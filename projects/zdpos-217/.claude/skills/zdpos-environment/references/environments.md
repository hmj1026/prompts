# Environments — merchant config / dev4 entry / commands / SSH / logs

> zdpos-environment skill 的「環境細節」子檔。5 環境總表在 router `../SKILL.md`；本檔放各環境的設定來源、本地入口、指令樣板與存取方式。

## Merchant config & 環境特性

- **Merchant SSOT**: `protected/config/*.php` (exclude `main/console/db/params.php`, `_`/`.` prefixes, `00_recycle/`). `apps/db_list.php` is empty — **not** the source.
- **UAT and CPOS217 co-host**: two codebases / runtimes / crons coexist independently，**但共用同一個 Cloud SQL 實例 / DB**（→ UAT 的 `SELECT @@sql_mode` / schema / row 永遠等於 PROD CPOS）。
- **API keys** hardcoded in class constants, shared across 5 envs — UAT/DEV throttled to avoid burning PROD quota.
- **Adding a merchant**: drop `protected/config/{newshop}.php`; cron auto-discovers via `listMerchants` — no cron change needed.

### Local dev4 entry（zdpos-217 working tree 的入口）

- 測 zdpos-217 改動**一律走 `www.posdev.test/dev4`**：薄 entry `dev4/index.php` 載入 `../zdpos-217/protected/config/dev4.php` → dev4 直接 render 本 working tree 的 views/JS/PHP，**編輯即生效**（無需 rsync）。`dev3` 載入舊 `zdpos_dev` checkout，測 zdpos-217 改動不會生效。
- `protected/config/dev4.php`（gitignored）已內含 docker `dir_path` override；`protected/tests/bootstrap.php` 自 `155e64d` 起 env-aware（有 dev4.php 優先、否則 fallback dev3.php），`git checkout/pull` 不會再把測試入口還原回 dev3。
- E2E：`js/tests/e2e/_helpers/login.js` 預設 `BASE_URL` 已是 dev4 → bare `npx playwright test` 即打 dev4，只有要改打其他環境才設 `POS_BASE_URL`。
- ⚠️ **opcache false-green**：`pos_php` opcache `revalidate_freq=60` → 改完 view/PHP 後 60 秒內仍服務舊 bytecode，E2E 可能以舊碼假綠。**每次改完、跑 E2E 前必 reset**：
  ```bash
  docker exec -i pos_php sh -c 'kill -USR2 1'   # 須 sh -c；直接 docker exec ... kill 找不到 kill binary
  ```

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
