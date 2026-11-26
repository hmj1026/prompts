# Linked Worktree Setup Traps 1–5 與 Prerequisites 一條龍

下列指令都在 **worktree root** 執行；每個 fenced multi-line block 都是獨立 shell，第一行皆設定 `set -eu`，不得依賴前一個 block 的 shell state。

Trap 1–4 的「解法」與最後的一條龍 block 都屬 **setup lease**（只供 orchestrator 或具名 setup worker 執行）；implementation worker 只執行各段完成條件的 read-only commands，遇到 prerequisite 缺失時回報 `BLOCKED`，不接手 setup。

## Trap 1：yii_framework 相對路徑找不到

`protected/tests/bootstrap.php` / `bootstrap-pure-unit.php` 期望 `dirname(__FILE__) . '/../../../yii_framework/yiit.php'`：

- 主 checkout：`<main>/protected/tests` → `<main>/yii_framework` ✓
- linked worktree：`<worktree-parent>/<name>/protected/tests` → `<worktree-parent>/yii_framework` ✗

**解法**：sibling worktree parent 是 writer root 外的 shared setup scope。orchestrator 在派發 writer 前以獨立 shared-setup lease 序列化建立或確認 symlink；implementation worker 只做下列 read-only 驗證。容器內使用 Docker mount 路徑，容器外指向主 checkout 旁的實體：

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

shared setup 不存在時回報 `BLOCKED`，由 orchestrator 取得 lease 後建立；worker 不寫 writer root 以外的 path。完成條件：`test -f "$(dirname "$WT")/yii_framework/yiit.php"`。

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

worktree 沒有 `protected/runtime/` 或 `protected/runtime/tracy/` 時，Yii／Tracy 啟動會 fatal；CLI 只需要目錄存在，但 HTTP／E2E 還必須由實際 PHP web user 寫入。`755` 不是跨 host UID 的通用答案，`777` 也不是預設修復；由 setup lease 依 `zdpos-environment` 的 linked-worktree runtime guard 選擇最小可寫的 owner／group／ACL，並記錄 before／after mode 與 cleanup owner。

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

probe 失敗即 `BLOCKED`；不要讓 implementation worker 接手 chmod／chown，也不要先跑瀏覽器再由 500 response 反推 prerequisite 缺失。

## Trap 4：node_modules 不在 worktree

`git worktree add` 只帶 tracked files。`node_modules/` gitignored，因此 repository precommit／JS unit 可能找不到 Jest、ESLint、TypeScript，Playwright 也可能報 `Cannot find module '@playwright/test'`。如果 main checkout 已有 lockfile 對應的 dependencies，建立暫時 symlink；不要在 task worktree 臨時安裝單一 package 或改寫 package manifests。

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

main checkout 的 dependencies 不存在或與 lockfile 不一致時，停止並依 repository dependency workflow 修復；不要用 partial install 掩蓋 prerequisite。gate 完成後只移除本次建立的 symlink：

```bash
set -eu

COMMON_GITDIR=$(realpath -e "$(git rev-parse --git-common-dir)")
MAIN=$(realpath -e "$(dirname "$COMMON_GITDIR")")
test -d "$MAIN/.git"

test -L node_modules
test "$(readlink node_modules)" = "$MAIN/node_modules"
unlink node_modules
```

完成條件：required binaries/modules 可載入；測試後 temporary symlink 已清理，package manifests 與 task worktree 內容未被 dependency setup 修改。

## Trap 5：E2E credentials 不在 worktree

worktree 不保存 credentials；未注入 `process.env.POS_ACCOUNT`／`POS_PASSWORD` 時，E2E spec 可能 `test.skip()`。

先呼叫 skill `zdpos-environment` 的 POS UI Login 取得當次環境座標與 credentials，再由本地 environment variables 傳入 Playwright。不得把帳密寫入 skill、artifact、command receipt 或聊天。

```bash
set -eu

test -n "${POS_ACCOUNT:-}"
test -n "${POS_PASSWORD:-}"
POS_ACCOUNT="$POS_ACCOUNT" POS_PASSWORD="$POS_PASSWORD" npx playwright test
```

完成條件：E2E 不再因缺 `POS_ACCOUNT` 而 `test.skip()`。

## PHP／JS prerequisites 一條龍

只由 setup lease owner 在 **worktree root** 執行；container runner 先完成 [writer-fence.md](./writer-fence.md) 的 Preflight 0；本 block 只準備 dependencies，不執行 PHPUnit、precommit 或 E2E；E2E credentials 另由 `zdpos-environment` 取得：

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
