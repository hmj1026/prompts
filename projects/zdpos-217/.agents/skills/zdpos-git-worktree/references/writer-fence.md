# Writer Fence、Setup Lease 與 Linked-Worktree Identity Preflight

本檔為 `zdpos-git-worktree` 的安全閘門完整規格與可執行指令。每個 fenced multi-line block 都是獨立 shell；若分開執行，該 block 第一行重新設定 `set -eu`（或 `set -euo pipefail`），不得依賴前一個 block 的 shell state。

## Writer fence：第一個 write 前

orchestrator 的 task packet 必須提供以下非秘密環境值：

- `ZDPOS_WRITER_ROOT`、`ZDPOS_WRITER_BRANCH`、`ZDPOS_WRITER_HEAD`
- `ZDPOS_WRITER_STATE_OID`：dispatch 前 writer 的 content-aware state object id
- `ZDPOS_PROTECTED_ROOT`、`ZDPOS_PROTECTED_STATE_OID`：不得被本 worker 修改的 checkout 及其 dispatch 前 state object id
- `ZDPOS_WRITER_IGNORED_MANIFEST`、`ZDPOS_PROTECTED_IGNORED_MANIFEST`：documentation governance inventory 產生的 NUL-delimited repository-relative ignored leaf paths；空集合使用 zero-byte regular file
- path allowlist、驗證命令、heartbeat deadline 與 stop condition（寫在 task packet，不放 env）

第一個 write 前執行：

```bash
set -euo pipefail

worktree_state_oid() {
  state_root="$1"
  ignored_manifest="$2"
  test -f "$ignored_manifest"
  test ! -L "$ignored_manifest"
  {
    printf 'status\0'
    git -C "$state_root" status --porcelain=v1 -z --untracked-files=all
    printf 'tracked-diff\0'
    git -C "$state_root" diff --binary --no-ext-diff HEAD --
    printf 'untracked-content\0'
    git -C "$state_root" ls-files --others --exclude-standard -z |
      while IFS= read -r -d '' state_path; do
        if [ -L "$state_root/$state_path" ]; then
          state_real=$(realpath -e "$state_root/$state_path")
          case "$state_real" in
            "$state_root/"*) ;;
            *) return 1 ;;
          esac
          test -f "$state_real"
          printf 'untracked-link\0%s\0%s\0%s\0%s\0%s\0' "$state_path" \
            "$(stat -c '%a' "$state_root/$state_path")" \
            "$(readlink "$state_root/$state_path")" \
            "$(stat -c '%a' "$state_real")" \
            "$(git hash-object --no-filters -- "$state_real")"
        elif [ -f "$state_root/$state_path" ]; then
          printf 'untracked-file\0%s\0%s\0%s\0' "$state_path" \
            "$(stat -c '%a' "$state_root/$state_path")" \
            "$(git hash-object --no-filters -- "$state_root/$state_path")"
        else
          printf 'unsupported-untracked\0%s\0' "$state_path" >&2
          return 1
        fi
      done
    printf 'ignored-manifest\0%s\0' "$(git hash-object --no-filters -- "$ignored_manifest")"
    while IFS= read -r -d '' state_path; do
      case "$state_path" in
        ''|/*|..|../*|*/..|*/../*) return 1 ;;
      esac
      state_parent=$(realpath -e "$(dirname "$state_root/$state_path")")
      case "$state_parent/" in
        "$state_root/"*) ;;
        *) return 1 ;;
      esac
      if [ -L "$state_root/$state_path" ]; then
        state_real=$(realpath -e "$state_root/$state_path")
        case "$state_real" in
          "$state_root/"*) ;;
          *) return 1 ;;
        esac
        test -f "$state_real"
        printf 'ignored-link\0%s\0%s\0%s\0%s\0%s\0' "$state_path" \
          "$(stat -c '%a' "$state_root/$state_path")" \
          "$(readlink "$state_root/$state_path")" \
          "$(stat -c '%a' "$state_real")" \
          "$(git hash-object --no-filters -- "$state_real")"
      elif [ -f "$state_root/$state_path" ]; then
        state_real=$(realpath -e "$state_root/$state_path")
        case "$state_real" in
          "$state_root/"*) ;;
          *) return 1 ;;
        esac
        printf 'ignored-file\0%s\0%s\0%s\0' "$state_path" \
          "$(stat -c '%a' "$state_root/$state_path")" \
          "$(git hash-object --no-filters -- "$state_root/$state_path")"
      else
        return 1
      fi
    done < "$ignored_manifest"
  } | git hash-object --stdin
}

WRITER_ROOT=$(realpath -e "${ZDPOS_WRITER_ROOT:?set ZDPOS_WRITER_ROOT}")
PROTECTED_ROOT=$(realpath -e "${ZDPOS_PROTECTED_ROOT:?set ZDPOS_PROTECTED_ROOT}")
WRITER_IGNORED_MANIFEST_INPUT="${ZDPOS_WRITER_IGNORED_MANIFEST:?set ZDPOS_WRITER_IGNORED_MANIFEST}"
PROTECTED_IGNORED_MANIFEST_INPUT="${ZDPOS_PROTECTED_IGNORED_MANIFEST:?set ZDPOS_PROTECTED_IGNORED_MANIFEST}"
case "$WRITER_IGNORED_MANIFEST_INPUT:$PROTECTED_IGNORED_MANIFEST_INPUT" in
  /*:/*) ;;
  *) exit 1 ;;
esac
test -f "$WRITER_IGNORED_MANIFEST_INPUT" && test ! -L "$WRITER_IGNORED_MANIFEST_INPUT"
test -f "$PROTECTED_IGNORED_MANIFEST_INPUT" && test ! -L "$PROTECTED_IGNORED_MANIFEST_INPUT"
WRITER_IGNORED_MANIFEST=$(realpath -e "$WRITER_IGNORED_MANIFEST_INPUT")
PROTECTED_IGNORED_MANIFEST=$(realpath -e "$PROTECTED_IGNORED_MANIFEST_INPUT")
ACTUAL_ROOT=$(realpath -e "$(git rev-parse --show-toplevel)")
test "$(pwd -P)" = "$ACTUAL_ROOT"
test "$ACTUAL_ROOT" = "$WRITER_ROOT"
test "$ACTUAL_ROOT" != "$PROTECTED_ROOT"
test "$(git branch --show-current)" = "${ZDPOS_WRITER_BRANCH:?set ZDPOS_WRITER_BRANCH}"
test "$(git rev-parse HEAD)" = "${ZDPOS_WRITER_HEAD:?set ZDPOS_WRITER_HEAD}"
test "$(worktree_state_oid "$WRITER_ROOT" "$WRITER_IGNORED_MANIFEST")" = \
  "${ZDPOS_WRITER_STATE_OID:?set ZDPOS_WRITER_STATE_OID}"
test "$(worktree_state_oid "$PROTECTED_ROOT" "$PROTECTED_IGNORED_MANIFEST")" = \
  "${ZDPOS_PROTECTED_STATE_OID:?set ZDPOS_PROTECTED_STATE_OID}"
```

任一檢查失敗就停止並回報 `INVALID_CHECKOUT`；不執行 write，也不自行修復受保護 checkout。
worker 完成後重跑 root／branch／HEAD 與 protected state 檢查，另回報 writer current state object id、allowlist delta 及實際 test output path。orchestrator 必須獨立重查；缺少 before／after receipt 時，GREEN 不成立。state OID 只掃描 manifest 內的 ignored unique WIP；orchestrator 必須先依 documentation governance 完成 ignored inventory 及下述 setup lease，再計算 writer baseline。implementation worker 的 allowlist 排除 setup paths 且只做 read-only 驗證。

## Setup lease：writer baseline 前

Trap 1–4 的 write blocks 只供 orchestrator 或具名 setup worker 執行。setup task packet 必須列出 exact output paths、before identity／absence、expected target 與 after completion criteria；同一 shared／ignored path 一次只允許一個 setup lease。全部 setup 完成後才計算 writer／protected state OID 並派發 implementation worker。implementation worker 遇到 prerequisite 缺失時回報 `BLOCKED`，不接手 setup。

[setup-traps.md](./setup-traps.md) 中每個 trap 的「解法」與最後的一條龍 block 都屬 setup lease；implementation worker 只執行各段完成條件的 read-only commands。

## Preflight 0：linked-worktree identity

以下是 read-only 的通用 host/container 檢查；`ZDPOS_DOCKER_WORKDIR` 必須指向本次 worktree 的 container root，`ZDPOS_PHP_CONTAINER` 預設為 `pos_php`。host metadata 必須是 repository common dir 下 `worktrees/<safe-basename>` 的 regular directory；container 只讀取同 basename 的 `/var/www/www.posdev/zdpos-217/.git/worktrees/<name>`，不改寫既有 worktree `.git`。

```bash
set -eu

fail_closed() {
  printf '%s\n' "$1" >&2
  exit 1
}

is_safe_metadata_name() {
  metadata_candidate="$1"
  case "$metadata_candidate" in
    ''|.|..|*..*|*[!A-Za-z0-9._-]*) return 1 ;;
    *) return 0 ;;
  esac
}

WT_ROOT=$(realpath -e "$(git rev-parse --show-toplevel)")
HOST_GITDIR=$(realpath -e "$(git rev-parse --git-dir)")
COMMON_GITDIR=$(realpath -e "$(git rev-parse --git-common-dir)")
META_NAME=$(basename "$HOST_GITDIR")
if ! is_safe_metadata_name "$META_NAME"; then
  fail_closed "unsafe linked-worktree metadata name: $META_NAME"
fi
if is_safe_metadata_name '../outside'; then
  fail_closed 'controlled outside metadata name was accepted'
fi
test "$HOST_GITDIR" = "$COMMON_GITDIR/worktrees/$META_NAME"
test -d "$HOST_GITDIR" && test ! -L "$HOST_GITDIR"
CONTAINER_ROOT="${ZDPOS_DOCKER_WORKDIR:?set ZDPOS_DOCKER_WORKDIR}"
CONTAINER="${ZDPOS_PHP_CONTAINER:-pos_php}"
CONTAINER_COMMON_GITDIR="/var/www/www.posdev/zdpos-217/.git"
CONTAINER_GITDIR="/var/www/www.posdev/zdpos-217/.git/worktrees/$META_NAME"
CONTAINER_COMMON_REAL=$(docker exec -i "$CONTAINER" realpath -e "$CONTAINER_COMMON_GITDIR")
CONTAINER_GITDIR_REAL=$(docker exec -i "$CONTAINER" realpath -e "$CONTAINER_GITDIR")
test "$CONTAINER_GITDIR_REAL" = "$CONTAINER_COMMON_REAL/worktrees/$META_NAME"
docker exec -i "$CONTAINER" test -d "$CONTAINER_COMMON_GITDIR"
docker exec -i "$CONTAINER" test ! -L "$CONTAINER_COMMON_GITDIR"
docker exec -i "$CONTAINER" test -d "$CONTAINER_GITDIR"
docker exec -i "$CONTAINER" test ! -L "$CONTAINER_GITDIR"
HOST_ROOT_ID=$(git --git-dir="$HOST_GITDIR" --work-tree="$WT_ROOT" rev-parse --show-toplevel)
CONTAINER_ROOT_ID=$(docker exec -i -w "$CONTAINER_ROOT" "$CONTAINER" \
  git --git-dir="$CONTAINER_GITDIR" --work-tree="$CONTAINER_ROOT" rev-parse --show-toplevel)
test "$HOST_ROOT_ID" = "$WT_ROOT"
test "$CONTAINER_ROOT_ID" = "$CONTAINER_ROOT"
HOST_ID=$(git --git-dir="$HOST_GITDIR" --work-tree="$WT_ROOT" rev-parse HEAD 'HEAD^{tree}')
CONTAINER_ID=$(docker exec -i -w "$CONTAINER_ROOT" "$CONTAINER" \
  git --git-dir="$CONTAINER_GITDIR" --work-tree="$CONTAINER_ROOT" rev-parse HEAD 'HEAD^{tree}')
test "$HOST_ID" = "$CONTAINER_ID"
test "$(docker exec -i -w "$CONTAINER_ROOT" "$CONTAINER" pwd -P)" = "$CONTAINER_ROOT"
```

native container `git` 因 host-absolute `.git` pointer exit 128 時，先保留為 metadata portability failure，改用上述 mapped `--git-dir` 檢查；只有 mapped metadata 缺失或 root／HEAD／tree mismatch 才是 `INVALID_CHECKOUT`，修正 mapping 後重跑。preflight 與 runner 都不寫入既有 `.git`。

每個下方 fenced multi-line block 都是獨立 shell；若分開執行，該 block 第一行重新設定 `set -eu`，不得依賴前一個 block 的 shell state。

### Worktree root identity 檢查

下列指令都在 **worktree root** 執行。主 checkout 由 resolved Git common dir 的 parent 推導，支援含空白的 path，並確認目前是 linked worktree：

```bash
set -eu

WT=$(realpath -e "$(git rev-parse --show-toplevel)")
COMMON_GITDIR=$(realpath -e "$(git rev-parse --git-common-dir)")
MAIN=$(realpath -e "$(dirname "$COMMON_GITDIR")")
test "$(pwd -P)" = "$WT"
test -f "$WT/.git"
test -d "$COMMON_GITDIR/worktrees"
test -d "$MAIN/.git"
```
