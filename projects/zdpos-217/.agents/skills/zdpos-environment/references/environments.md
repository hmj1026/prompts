# Environments — merchant config / dev4 entry / commands / SSH / logs

> zdpos-environment skill 的「環境細節」子檔。5 環境總表在 router `../SKILL.md`；本檔放各環境的設定來源、本地入口、指令樣板與存取方式。

## Merchant config & 環境特性

- **Merchant SSOT**: `protected/config/*.php` (exclude `main/console/db/params.php`, `_`/`.` prefixes, `00_recycle/`). `apps/db_list.php` is empty — **not** the source.
- **UAT and CPOS217 co-host**: two codebases / runtimes / crons coexist independently，**但共用同一個 Cloud SQL 實例 / DB**（→ UAT 的 `SELECT @@sql_mode` / schema / row 永遠等於 PROD CPOS）。
- **API keys** hardcoded in class constants, shared across 5 envs — UAT/DEV throttled to avoid burning PROD quota.
- **Adding a merchant**: drop `protected/config/{newshop}.php`; cron auto-discovers via `listMerchants` — no cron change needed.

### Local dev4 entry（`/dev4` 碼基 identity guard）

- 穩定的薄入口 `/home/paul/projects/www.posdev/dev4/index.php` 目前載入 `../zdpos-217/protected/config/dev4.php`；在 `pos_php` 內即 `/var/www/www.posdev/zdpos-217`（host `/home/paul/projects/zdpos-217`）的 **main checkout**。因此 `www.posdev.test/dev4` **不會自動跟隨 linked worktree**；URL、目前 shell 的 cwd 與目標 branch 不能互相推論。
- 測 linked worktree 前，先在實際 container 解析 entry 的 `$config`，確認 `realpath -e` 等於目標 worktree 的 `protected/config/dev4.php`。entry 指向 main 或其他樹時，停止並標 `INVALID_CHECKOUT`／`NOT_RUN`；不要用頁面顯示的 `位置:mysql` 取代碼基 identity。
- 若 owner 授權以薄入口暫時 overlay 目標 worktree，setup lease 必須保存 entry 原文／hash、目標 config、切換時間與 cleanup owner；切換後 reset opcache，測試後恢復**完全相同**的 entry 並再 reset／重驗。此流程只適用 local disposable run，不適用 PROD。
- `protected/config/dev4.php`（gitignored）已內含 docker `dir_path` override；`protected/tests/bootstrap.php` 自 `155e64d` 起 env-aware（有 dev4.php 優先、否則 fallback dev3.php），`git checkout/pull` 不會再把測試入口還原回 dev3。
- E2E：`js/tests/e2e/_helpers/login.js` 預設 `BASE_URL` 已是 dev4；linked worktree 仍須先通過上列 URL／碼基 guard，只有要改打其他環境才設 `POS_BASE_URL`。
- ⚠️ **opcache false-green**：`pos_php` opcache `revalidate_freq=60` → 改完 view/PHP 後 60 秒內仍服務舊 bytecode，E2E 可能以舊碼假綠。**每次改完、跑 E2E 前必 reset**：
  ```bash
  docker exec -i pos_php sh -c 'kill -USR2 1'   # 須 sh -c；直接 docker exec ... kill 找不到 kill binary
  ```

#### Linked-worktree `/dev4` read-only preflight

在 `pos_php` 內執行；把 `<worktree-basename>` 換成目標 linked worktree basename。這個檢查只確認
route identity，不會改 entry 或 runtime：

```bash
set -eu

ENTRY=/var/www/www.posdev/dev4/index.php
TARGET=/var/www/www.posdev/<worktree-basename>
CONFIG_REL=$(awk -F"'" '/^\$config[ \t]*=/{print $2; exit}' "$ENTRY")
test -n "$CONFIG_REL"
test "$(realpath -e "$(dirname "$ENTRY")/$CONFIG_REL")" = "$TARGET/protected/config/dev4.php"
```

若檢查不能在 container root 與 target root 都通過，瀏覽器 journey 的結果不得記為 PASS。
linked-worktree 測試另需 setup lease 建立 `protected/runtime/tracy`，並用實際 PHP web user
（常見為 `www-data`）確認 `protected/runtime` 與 `tracy` 皆可寫；權限採最小可寫範圍，不能以
固定 `755` 或 `777` 假設所有 host/container UID 都相同。缺少目錄或 web-user write probe 失敗時，
先標 `BLOCKED`，不要讓瀏覽器先跑出一張 500 receipt。

## Command templates

```bash
ZDPOS_ROOT=/var/www/zdpos_217      # CPOS217; replace codebase path for other envs
YIIC="/usr/bin/php $ZDPOS_ROOT/protected/yiic.php"
# Local Docker:
docker exec -i -w /var/www/www.posdev/zdpos-217 pos_php php protected/yiic.php
```

> ⚠️ **workdir 必用 `/var/www/www.posdev/zdpos-217`**。`pos_php` 同時掛載 `zdpos-217`（本專案）與舊 `zdpos_dev` 兩個 checkout；用 `-w .../zdpos_dev` 跑 phpunit **不報錯**，會 silently 測到另一份 codebase（新檔在 zdpos-217 → `Cannot open file`）。

## SSH

`vm1` / `vm2` / `dev` defined in `~/.ssh/config`. Claude Code has no ssh-agent → **cannot SSH directly**: ask user to run remote commands and paste results; obtain authorization each time.

> 遠端某 URL 跑哪份碼基 / `X:/Y:/Z:` network share 對應 / opcache 假象 → 見 `multi-site.md`（多站部署架構：LOCAL / DEV / PROD 共通）。

## Local Error Logs

| log | path (relative) |
|-----|-----------------|
| Yii application | `protected/runtime/application.log` (project-root relative) |
| PHP fatal/warning | `~/projects/docker_run/logs/php/error.log` (host-side docker bind mount; tilde-anchored) |

When user reports local migration / runtime error or asks to verify dev4 behavior, grep both log paths first; do not ask which config / which DB. On macOS replace `~/projects/docker_run/` with the local docker compose log mount.
