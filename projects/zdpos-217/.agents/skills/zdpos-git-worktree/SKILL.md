---
name: zdpos-git-worktree
description: linked-worktree writer fence 與測試 setup。Use when subAgent 要在 linked worktree edit/port/copy，或要跑 PHPUnit、precommit/Jest、Playwright；也用於 host-absolute `.git` pointer、yii_framework、TracyBootstrap、Jest/Playwright dependency failure。Output: writer/setup lease receipt 或 fail-closed INVALID_CHECKOUT。
allowed-tools: Read, Bash(ls *), Bash(cat *), Bash(ln *), Bash(cp *), Bash(mkdir *), Bash(chmod *), Bash(npm *), Bash(git *), Bash(bash *), Bash(test *), Bash(node *), Bash(readlink *), Bash(realpath *), Bash(diff *), Bash(pwd *), Bash(stat *), Bash(unlink *), Bash(docker exec *)
---

# Linked worktree writer fence + test setup

subAgent 在 linked worktree 執行第一個 edit／port／copy 前先取得 `writer lease`；測試 worker 再完成
linked-worktree identity preflight與適用的 setup traps。worktree 的 `.git` 可能指向 host absolute
metadata；container 使用對應的 main `.git/worktrees/<name>` mapping。完成條件是 writer、受保護
checkout、host／container與實際輸出 path 都能由 receipt 獨立核對。

## Writer fence：第一個 write 前

orchestrator 的 task packet 必須提供以下非秘密環境值：

- `ZDPOS_WRITER_ROOT`、`ZDPOS_WRITER_BRANCH`、`ZDPOS_WRITER_HEAD`
- `ZDPOS_WRITER_STATE_OID`：dispatch 前 writer 的 content-aware state object id
- `ZDPOS_PROTECTED_ROOT`、`ZDPOS_PROTECTED_STATE_OID`：不得被本 worker 修改的 checkout及其
  dispatch 前 state object id
- `ZDPOS_WRITER_IGNORED_MANIFEST`、`ZDPOS_PROTECTED_IGNORED_MANIFEST`：documentation governance
  inventory 產生的 NUL-delimited repository-relative ignored leaf paths；空集合使用 zero-byte regular file
- path allowlist、驗證命令、heartbeat deadline與 stop condition（寫在 task packet，不放 env）

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
worker 完成後重跑 root／branch／HEAD與 protected state 檢查，另回報 writer current state object id、
allowlist delta及實際 test output path。orchestrator 必須獨立重查；缺少 before／after receipt 時，
GREEN 不成立。state OID 只掃描 manifest 內的 ignored unique WIP；orchestrator 必須先依
documentation governance 完成 ignored inventory及下述 setup lease，再計算 writer baseline。
implementation worker 的 allowlist 排除 setup paths且只做 read-only 驗證。

## Setup lease：writer baseline 前

Trap 1–4 的 write blocks 只供 orchestrator 或具名 setup worker 執行。setup task packet 必須列出
exact output paths、before identity／absence、expected target與 after completion criteria；同一 shared／
ignored path一次只允許一個 setup lease。全部 setup 完成後才計算 writer／protected state OID並派發
implementation worker。implementation worker 遇到 prerequisite 缺失時回報 `BLOCKED`，不接手 setup。

下列每個 trap 的「解法」與最後的一條龍 block 都屬 setup lease；implementation worker只執行各段
完成條件的 read-only commands。

## Preflight 0：linked-worktree identity

以下是 read-only 的通用 host/container 檢查；`ZDPOS_DOCKER_WORKDIR` 必須指向本次 worktree 的
container root，`ZDPOS_PHP_CONTAINER` 預設為 `pos_php`。host metadata 必須是 repository common
dir 下 `worktrees/<safe-basename>` 的 regular directory；container 只讀取同 basename 的
`/var/www/www.posdev/zdpos-217/.git/worktrees/<name>`，不改寫既有 worktree `.git`。

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

native container `git` 因 host-absolute `.git` pointer exit 128 時，先保留為 metadata portability
failure，改用上述 mapped `--git-dir` 檢查；只有 mapped metadata 缺失或 root／HEAD／tree mismatch
才是 `INVALID_CHECKOUT`，修正 mapping 後重跑。preflight 與 runner 都不寫入既有 `.git`。

每個下方 fenced multi-line block 都是獨立 shell；若分開執行，該 block 第一行重新設定
`set -eu`，不得依賴前一個 block 的 shell state。

下列指令都在 **worktree root** 執行。主 checkout 由 resolved Git common dir 的 parent 推導，
支援含空白的 path，並確認目前是 linked worktree：

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

## Trap 1：yii_framework 相對路徑找不到

`protected/tests/bootstrap.php` / `bootstrap-pure-unit.php` 期望 `dirname(__FILE__) . '/../../../yii_framework/yiit.php'`：

- 主 checkout：`<main>/protected/tests` → `<main>/yii_framework` ✓
- linked worktree：`<worktree-parent>/<name>/protected/tests` → `<worktree-parent>/yii_framework` ✗

**解法**：sibling worktree parent 是 writer root 外的 shared setup scope。orchestrator 在派發 writer 前
以獨立 shared-setup lease 序列化建立或確認 symlink；implementation worker 只做下列 read-only 驗證。
容器內使用 Docker mount 路徑，容器外指向主 checkout 旁的實體：

```bash
set -eu

WT=$(realpath -e "$(git rev-parse --show-toplevel)")
COMMON_GITDIR=$(realpath -e "$(git rev-parse --git-common-dir)")
MAIN=$(realpath -e "$(dirname "$COMMON_GITDIR")")
test "$(pwd -P)" = "$WT"

YII_SRC=/var/www/www.posdev/yii_framework
[ -d "$YII_SRC" ] || YII_SRC=$(realpath -e "$(dirname "$MAIN")/yii_framework")
YII_LINK="$(dirname "$WT")/yii_framework"
test -L "$YII_LINK"
test "$(readlink -f "$YII_LINK")" = "$YII_SRC"
```

shared setup 不存在時回報 `BLOCKED`，由 orchestrator 取得 lease 後建立；worker 不寫 writer root
以外的 path。完成條件：`test -f "$(dirname "$WT")/yii_framework/yiit.php"`。

## Trap 2：protected/config 必須 COPY 不能 symlink

`protected/config/` 是 gitignored，worktree 沒有。直覺 `ln -s` 會炸：

```
Fatal error: Cannot redeclare class Infrastructure\Debug\TracyBootstrap
in worktree/infrastructure/Debug/TracyBootstrap.php
```

**根因**：`dev3.php` 內 `require(__DIR__ . '/../../setPathOfAlias.php')`，當 config 是 symlink 時 `__DIR__` 因 PHP realpath 解析會落到主 checkout，於是載入主 checkout 的 `setPathOfAlias.php`（require_once 主 `TracyBootstrap.php`）；同時 Yii alias `Infrastructure` 透過 worktree 的 `setPathOfAlias` 又載入 worktree 的 `TracyBootstrap.php`。兩個不同實體路徑的同名 class → fatal。

**解法**：用 cp 而非 ln：

```bash
set -eu

WT=$(realpath -e "$(git rev-parse --show-toplevel)")
COMMON_GITDIR=$(realpath -e "$(git rev-parse --git-common-dir)")
MAIN=$(realpath -e "$(dirname "$COMMON_GITDIR")")
test "$(pwd -P)" = "$WT"

CONFIG_SRC=$(realpath -e "$MAIN/protected/config")
CONFIG_TARGET="$WT/protected/config"
if [ -e "$CONFIG_TARGET" ]; then
  test -d "$CONFIG_TARGET"
  test ! -L "$CONFIG_TARGET"
  diff -qr "$CONFIG_SRC" "$CONFIG_TARGET"
else
  mkdir -p "$CONFIG_TARGET"
  cp -a "$CONFIG_SRC/." "$CONFIG_TARGET/"
fi
```

完成條件：`protected/config/` 是實體目錄（`test -d && ! test -L`），且 `phpunit` 不再報 TracyBootstrap redeclare。

## Trap 3：protected/runtime 與 Tracy runtime

worktree 沒有 `protected/runtime/` 或 `protected/runtime/tracy/` 時，Yii／Tracy 啟動會 fatal；CLI
只需要目錄存在，但 HTTP／E2E 還必須由實際 PHP web user 寫入。`755` 不是跨 host UID 的通用答案，
`777` 也不是預設修復；由 setup lease 依 `zdpos-environment` 的 linked-worktree runtime guard
選擇最小可寫的 owner／group／ACL，並記錄 before／after mode 與 cleanup owner。

```bash
set -eu

mkdir -p protected/runtime/tracy
test -d protected/runtime
test -d protected/runtime/tracy
```

HTTP／E2E 的完成條件是以實際 web user 在目標 container root 進行 read-only permission probe：

```bash
set -eu

WEB_USER="${ZDPOS_WEB_USER:?set ZDPOS_WEB_USER to the effective PHP web user}"
docker exec -i -u "$WEB_USER" -w "${ZDPOS_DOCKER_WORKDIR:?set ZDPOS_DOCKER_WORKDIR}" \
  "${ZDPOS_PHP_CONTAINER:-pos_php}" sh -c \
  'test -w protected/runtime && test -w protected/runtime/tracy'
```

probe 失敗即 `BLOCKED`；不要讓 implementation worker 接手 chmod／chown，也不要先跑瀏覽器再由
500 response 反推 prerequisite 缺失。

## Trap 4：node_modules 不在 worktree

`git worktree add` 只帶 tracked files。`node_modules/` gitignored，因此 repository precommit／JS unit
可能找不到 Jest、ESLint、TypeScript，Playwright 也可能報 `Cannot find module '@playwright/test'`。
如果 main checkout 已有 lockfile 對應的 dependencies，建立暫時 symlink；不要在 task worktree
臨時安裝單一 package 或改寫 package manifests。

```bash
set -eu

COMMON_GITDIR=$(realpath -e "$(git rev-parse --git-common-dir)")
MAIN=$(realpath -e "$(dirname "$COMMON_GITDIR")")
test -d "$MAIN/.git"

test -d "$MAIN/node_modules"
test ! -e node_modules
test ! -L node_modules
ln -s "$MAIN/node_modules" node_modules
```

依 gate 驗證 required dependency：

```bash
set -eu

test -x node_modules/.bin/jest
test -x node_modules/.bin/eslint
test -x node_modules/.bin/tsc
node -e "require('@playwright/test')" # 只有 E2E 需要
```

main checkout 的 dependencies 不存在或與 lockfile 不一致時，停止並依 repository dependency
workflow 修復；不要用 partial install 掩蓋 prerequisite。gate 完成後只移除本次建立的 symlink：

```bash
set -eu

COMMON_GITDIR=$(realpath -e "$(git rev-parse --git-common-dir)")
MAIN=$(realpath -e "$(dirname "$COMMON_GITDIR")")
test -d "$MAIN/.git"

test -L node_modules
test "$(readlink node_modules)" = "$MAIN/node_modules"
unlink node_modules
```

完成條件：required binaries/modules 可載入；測試後 temporary symlink 已清理，package manifests
與 task worktree 內容未被 dependency setup 修改。

## Trap 5：E2E credentials 不在 worktree

worktree 不保存 credentials；未注入 `process.env.POS_ACCOUNT`／`POS_PASSWORD` 時，E2E spec
可能 `test.skip()`。

先呼叫 skill `zdpos-environment` 的 POS UI Login 取得當次環境座標與 credentials，再由本地
environment variables 傳入 Playwright。不得把帳密寫入 skill、artifact、command receipt 或聊天。

```bash
set -eu

test -n "${POS_ACCOUNT:-}"
test -n "${POS_PASSWORD:-}"
POS_ACCOUNT="$POS_ACCOUNT" POS_PASSWORD="$POS_PASSWORD" npx playwright test
```

完成條件：E2E 不再因缺 `POS_ACCOUNT` 而 `test.skip()`。

## Apply order

| Step | Action | 適用 |
|---|---|---|
| 0 | linked-worktree identity preflight：驗證 host common gitdir、safe basename、container mapped gitdir、雙側 HEAD/tree；browser／E2E 再核對 thin-entry target config；native pointer failure 先歸 metadata portability failure | 所有 container runner；browser／E2E 需 route guard |
| 1 | read-only 驗證 orchestrator 以 shared-setup lease 建立的 yii_framework symlink | fast suite 起步 |
| 2 | `cp -a` protected/config | fast suite + full suite |
| 3 | setup lease 建立 `protected/runtime/tracy`，並由實際 web user probe 可寫 | full PHP integration + E2E |
| 4 | 暫時連結 main checkout 的完整 `node_modules`，gate 後清理 | JS precommit/unit + E2E |
| 5 | 透過 `zdpos-environment` 載入 `POS_ACCOUNT`／`POS_PASSWORD` | E2E only |

PHP fast unit suite 只需 1+2；full PHP integration suite 需 1+2+3；repository precommit／JS
unit 需要 4；E2E 需要依測試 bootstrap 套用 1–4，再以 5 提供 credentials。

PHP／JS prerequisites 一條龍（只由 setup lease owner 在 **worktree root** 執行；container runner先完成
Preflight 0；本 block 只準備 dependencies，不執行 PHPUnit、precommit 或 E2E；E2E credentials
另由 `zdpos-environment` 取得）：

```bash
set -eu

WT=$(realpath -e "$(git rev-parse --show-toplevel)")
COMMON_GITDIR=$(realpath -e "$(git rev-parse --git-common-dir)")
MAIN=$(realpath -e "$(dirname "$COMMON_GITDIR")")
test "$(pwd -P)" = "$WT"
test -f "$WT/.git"
test -d "$COMMON_GITDIR/worktrees"
test -d "$MAIN/.git"
YII_SRC=/var/www/www.posdev/yii_framework
[ -d "$YII_SRC" ] || YII_SRC=$(realpath -e "$(dirname "$MAIN")/yii_framework")
YII_LINK="$(dirname "$WT")/yii_framework"
test -L "$YII_LINK"
test "$(readlink -f "$YII_LINK")" = "$YII_SRC"
CONFIG_SRC=$(realpath -e "$MAIN/protected/config")
CONFIG_TARGET="$WT/protected/config"
if [ -e "$CONFIG_TARGET" ]; then
  test -d "$CONFIG_TARGET"
  test ! -L "$CONFIG_TARGET"
  diff -qr "$CONFIG_SRC" "$CONFIG_TARGET"
else
  mkdir -p "$CONFIG_TARGET"
  cp -a "$CONFIG_SRC/." "$CONFIG_TARGET/"
fi
mkdir -p protected/runtime/tracy
test -d protected/runtime/tracy
test -d "$MAIN/node_modules"
test ! -e node_modules
test ! -L node_modules
ln -s "$MAIN/node_modules" node_modules
```

JS／E2E gate 完成後依 Trap 4 驗證 target，再 `unlink node_modules`。

不另放共用 script：worktree 只含 tracked files。local agent skill 是 prompts repo 的 tracked
canonical，透過 project symlink 投影到 consuming project。branch delivery SSOT 是
`<consuming-project-root>/docs/workflow/execution-policy.md`；deploy／review 必須分別驗證 projected
skill symlink解析回本 canonical path，且該 consuming-project pointer 可由 fresh checkout 取得。
local projection 不代表 target branch 已 commit，不得以它宣稱 branch delivery complete。

## Related

- skill `zdpos-environment` POS UI Login — 取得當次環境座標、登入流程與 credentials；本 skill 不保存帳密
