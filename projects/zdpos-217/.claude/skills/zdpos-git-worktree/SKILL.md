---
name: zdpos-git-worktree
description: zdpos 專案 `.claude/worktrees/<name>/` 跑 phpunit.xml 完整套件或 Playwright E2E 必跑的五件套 setup（yii_framework symlink / protected/config cp / protected/runtime mkdir+755 / `npm i @playwright/test` 後還原 lock / `POS_ACCOUNT` env）。使用時機：`git worktree add` 後進 `.claude/worktrees/`、worktree 內跑 phpunit.xml / npx playwright test、出現以下症狀任一：`yii_framework not found`、`Cannot redeclare class Infrastructure\\Debug\\TracyBootstrap`、`Cannot find module '@playwright/test'`、所有 E2E spec 都 skip。主 checkout 跑測試不需要載入。
allowed-tools: Read, Bash(ls *), Bash(cat *), Bash(ln *), Bash(cp *), Bash(mkdir *), Bash(chmod *), Bash(npm *), Bash(git *), Bash(bash *)
---

# Worktree PHPUnit + E2E 五件套 setup

> 觸發：`.claude/worktrees/<name>/` 內跑 phpunit.xml / playwright test。主 checkout 不需要。

worktree 路徑比主 checkout 深 3 層（`.claude/worktrees/<name>/`），測試 bootstrap 與部分 gitignored 資源會找不到。共五個 trap，必須照順序處理。

## Trap 1：yii_framework 相對路徑找不到

`protected/tests/bootstrap.php` / `bootstrap-pure-unit.php` 期望 `dirname(__FILE__) . '/../../../yii_framework/yiit.php'`：

- 主 checkout：`zdpos_dev/protected/tests` → `projects/yii_framework` ✓
- worktree：`.claude/worktrees/<name>/protected/tests` → `.claude/yii_framework` ✗

**解法**：worktree 建立後，在 `.claude/worktrees/` 層放 symlink 指向容器內路徑：

```bash
ln -s /var/www/www.posdev/yii_framework /home/paul/projects/zdpos-217/.claude/worktrees/yii_framework
```

容器內 Docker mount 看得到；主機端只要 worktree 看得見就行。

## Trap 2：protected/config 必須 COPY 不能 symlink

`protected/config/` 是 gitignored，worktree 沒有。直覺 `ln -s` 會炸：

```
Fatal error: Cannot redeclare class Infrastructure\Debug\TracyBootstrap
in worktree/infrastructure/Debug/TracyBootstrap.php
```

**根因**：`dev3.php` 內 `require(__DIR__ . '/../../setPathOfAlias.php')`，當 config 是 symlink 時 `__DIR__` 因 PHP realpath 解析會落到主 checkout，於是載入主 checkout 的 `setPathOfAlias.php`（require_once 主 `TracyBootstrap.php`）；同時 Yii alias `Infrastructure` 透過 worktree 的 `setPathOfAlias` 又載入 worktree 的 `TracyBootstrap.php`。兩個不同實體路徑的同名 class → fatal。

**解法**：用 cp 而非 ln：

```bash
cp -a /home/paul/projects/zdpos-217/protected/config/. protected/config/
```

## Trap 3：protected/runtime 也要建（chmod 755 即可）

worktree 沒有 `protected/runtime/`，Yii 啟動會 fatal 「應用程式執行時的路徑 "..." 是無效的」。`chmod 777` 會被 zdpos hook 擋（強制 750/640） — 用 755。

```bash
mkdir -p protected/runtime && chmod 755 protected/runtime
```

## Trap 4：node_modules 與 Playwright 不在 worktree

`git worktree add` 只帶 tracked files。`node_modules/` gitignored → `npx playwright test` 報 `Cannot find module '@playwright/test'`。

```bash
# npm 自動裝會 bump 版本，事後 git checkout 還原 lock
npm install --no-audit --no-fund --prefer-offline @playwright/test
git checkout package.json package-lock.json
```

## Trap 5：.claude/artifacts/accounts.md 不在 worktree

`zdpos-environment` skill 規定 POS UI 登入帳密來自 gitignored `.claude/artifacts/accounts.md`。worktree 沒有 → `loginPos()` 拿不到 `process.env.POS_ACCOUNT` → 所有 14+ E2E spec `test.skip()`。

**解法**：env var 直接餵（推薦），不要 symlink `.claude/artifacts/`（裡面混了 reviews / sessions / sentinels 等 hook 寫入物，symlink 會讓 hook 狀態互相干擾）。

```bash
# local Docker 分店帳號（參見 zdpos-environment skill "Step 2.5"）
export POS_ACCOUNT=116 POS_PASSWORD=0000
POS_ACCOUNT=$POS_ACCOUNT POS_PASSWORD=$POS_PASSWORD npx playwright test
```

總店帳號（888/888）在 `/pos/index` 會卡「未選機號」，必須走分店帳號 + RepeatAction。dev / cpos218 / demo218 等其他環境的帳號編號 → skill `zdpos-environment` "Step 2.5"。

## Apply order

| Step | Action | 適用 |
|---|---|---|
| 1 | `ln -s` yii_framework | fast suite 起步 |
| 2 | `cp -a` protected/config | fast suite + full suite |
| 3 | `mkdir -p + chmod 755` protected/runtime | full suite |
| 4 | `npm install @playwright/test` + `git checkout package*.json` | E2E only |
| 5 | `export POS_ACCOUNT=116 POS_PASSWORD=0000` | E2E only |

Fast unit suite 只需 1+2。Full integration suite 需 1+2+3。E2E 需要全部五步。

> 五步可串成一條龍（在 **worktree root** 執行；`116/0000` 為本地分店帳號）：
>
> ```bash
> WT=$(git rev-parse --show-toplevel); MAIN=/home/paul/projects/zdpos-217
> ln -sf /var/www/www.posdev/yii_framework "$(dirname "$WT")/yii_framework"   # Trap 1
> cp -a "$MAIN/protected/config/." protected/config/                          # Trap 2
> mkdir -p protected/runtime && chmod 755 protected/runtime                   # Trap 3
> npm install --no-audit --no-fund --prefer-offline @playwright/test \
>   && git checkout package.json package-lock.json                           # Trap 4
> export POS_ACCOUNT=116 POS_PASSWORD=0000                                    # Trap 5
> ```
>
> 不另放共用 script：worktree 只含 tracked files，gitignored 的 `.claude/skills/` symlink 在 worktree 內不存在，相對路徑叫不到；需要時把上面存成自己的 helper 即可。

## Related

- memory `testing-traps.md` — zdpos 測試 setup 路徑計算 / Bootstrap split (pure-unit vs full) / SELECT column 對齊等 trap，跑 fast suite 前可一併參考
- memory `trap_zpos_list_public_api.md` — `js/zpos/list.js` 公開 API 命名反直覺（`setDiscount` / `setAllowance` / `removeItem` 等），呼叫前必 grep 確認（worktree 內寫 E2E spec 必讀）
- skill `zdpos-environment` § POS UI Login — local POS `/pos/index` 必用分店帳號 + 選機號 + RepeatAction（與 Trap 5 的 `POS_ACCOUNT=116` 密切相關；總店帳號 888 會卡「未選機號」）
