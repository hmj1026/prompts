---
name: zdpos-git-worktree
description: worktree 測試 setup：`.claude/worktrees/<name>/` 跑 phpunit 或 Playwright 前的五件套。Use when 進 worktree 跑測試，或出現 yii_framework not found、TracyBootstrap redeclare、@playwright/test missing。主 checkout 不需要。
allowed-tools: Read, Bash(ls *), Bash(cat *), Bash(ln *), Bash(cp *), Bash(mkdir *), Bash(chmod *), Bash(npm *), Bash(git *), Bash(bash *)
---

# Worktree PHPUnit + E2E 五件套 setup

worktree 路徑比主 checkout 深 3 層（`.claude/worktrees/<name>/`），測試 bootstrap 與部分 gitignored 資源會找不到。共五個 trap，照順序處理。

下列指令都在 **worktree root** 執行。主 checkout 與 yii_framework 用 git 推導，不寫死家目錄：

```bash
WT=$(git rev-parse --show-toplevel)
MAIN=$(git worktree list | awk 'NR==1{print $1}')
```

## Trap 1：yii_framework 相對路徑找不到

`protected/tests/bootstrap.php` / `bootstrap-pure-unit.php` 期望 `dirname(__FILE__) . '/../../../yii_framework/yiit.php'`：

- 主 checkout：`zdpos_dev/protected/tests` → `projects/yii_framework` ✓
- worktree：`.claude/worktrees/<name>/protected/tests` → `.claude/yii_framework` ✗

**解法**：在 `.claude/worktrees/` 層放 symlink。容器內用 Docker mount 路徑；容器外改指向主 checkout 旁的實體：

```bash
YII_SRC=/var/www/www.posdev/yii_framework
[ -d "$YII_SRC" ] || YII_SRC=$(realpath "$(dirname "$MAIN")/yii_framework")
ln -sf "$YII_SRC" "$(dirname "$WT")/yii_framework"
```

完成條件：`test -f "$(dirname "$WT")/yii_framework/yiit.php"`。

## Trap 2：protected/config 必須 COPY 不能 symlink

`protected/config/` 是 gitignored，worktree 沒有。直覺 `ln -s` 會炸：

```
Fatal error: Cannot redeclare class Infrastructure\Debug\TracyBootstrap
in worktree/infrastructure/Debug/TracyBootstrap.php
```

**根因**：`dev3.php` 內 `require(__DIR__ . '/../../setPathOfAlias.php')`，當 config 是 symlink 時 `__DIR__` 因 PHP realpath 解析會落到主 checkout，於是載入主 checkout 的 `setPathOfAlias.php`（require_once 主 `TracyBootstrap.php`）；同時 Yii alias `Infrastructure` 透過 worktree 的 `setPathOfAlias` 又載入 worktree 的 `TracyBootstrap.php`。兩個不同實體路徑的同名 class → fatal。

**解法**：用 cp 而非 ln：

```bash
cp -a "$MAIN/protected/config/." protected/config/
```

完成條件：`protected/config/` 是實體目錄（`test -d && ! test -L`），且 `phpunit` 不再報 TracyBootstrap redeclare。

## Trap 3：protected/runtime 也要建（chmod 755 即可）

worktree 沒有 `protected/runtime/`，Yii 啟動會 fatal「應用程式執行時的路徑是無效的」。`chmod 777` 會被 zdpos hook 擋 — 用 755。

```bash
mkdir -p protected/runtime && chmod 755 protected/runtime
```

完成條件：`stat -c '%a' protected/runtime` 為 `755`。

## Trap 4：node_modules 與 Playwright 不在 worktree

`git worktree add` 只帶 tracked files。`node_modules/` gitignored → `npx playwright test` 報 `Cannot find module '@playwright/test'`。

```bash
npm install --no-audit --no-fund --prefer-offline @playwright/test
git checkout package.json package-lock.json
```

完成條件：`node -e "require('@playwright/test')"` 成功，且 `git status --short package.json package-lock.json` 為空。

## Trap 5：.claude/artifacts/accounts.md 不在 worktree

`zdpos-environment` 規定 POS UI 登入帳密來自 gitignored `.claude/artifacts/accounts.md`。worktree 沒有 → `loginPos()` 拿不到 `process.env.POS_ACCOUNT` → 所有 E2E spec `test.skip()`。

用 env var 餵，不要 symlink `.claude/artifacts/`（裡面混了 reviews / sessions / sentinels，symlink 會讓 hook 狀態互相干擾）。

```bash
export POS_ACCOUNT=116 POS_PASSWORD=0000
POS_ACCOUNT=$POS_ACCOUNT POS_PASSWORD=$POS_PASSWORD npx playwright test
```

總店帳號（888/888）在 `/pos/index` 會卡「未選機號」，必須走分店帳號 + RepeatAction。其他環境帳號 → skill `zdpos-environment` POS UI Login。

完成條件：E2E 不再因缺 `POS_ACCOUNT` 而 `test.skip()`。

## Apply order

| Step | Action | 適用 |
|---|---|---|
| 1 | `ln -s` yii_framework | fast suite 起步 |
| 2 | `cp -a` protected/config | fast suite + full suite |
| 3 | `mkdir -p + chmod 755` protected/runtime | full suite |
| 4 | `npm install @playwright/test` + `git checkout package*.json` | E2E only |
| 5 | `export POS_ACCOUNT=116 POS_PASSWORD=0000` | E2E only |

Fast unit suite 只需 1+2。Full integration suite 需 1+2+3。E2E 需要全部五步。

一條龍（在 **worktree root** 執行；`116/0000` 為本地分店帳號）：

```bash
WT=$(git rev-parse --show-toplevel)
MAIN=$(git worktree list | awk 'NR==1{print $1}')
YII_SRC=/var/www/www.posdev/yii_framework
[ -d "$YII_SRC" ] || YII_SRC=$(realpath "$(dirname "$MAIN")/yii_framework")
ln -sf "$YII_SRC" "$(dirname "$WT")/yii_framework"
cp -a "$MAIN/protected/config/." protected/config/
mkdir -p protected/runtime && chmod 755 protected/runtime
npm install --no-audit --no-fund --prefer-offline @playwright/test \
  && git checkout package.json package-lock.json
export POS_ACCOUNT=116 POS_PASSWORD=0000
```

不另放共用 script：worktree 只含 tracked files，gitignored 的 `.claude/skills/` 在 worktree 內不存在。

## Related

- skill `zdpos-environment` POS UI Login — local POS `/pos/index` 必用分店帳號 + 選機號 + RepeatAction（與 Trap 5 的 `POS_ACCOUNT=116` 對應）
