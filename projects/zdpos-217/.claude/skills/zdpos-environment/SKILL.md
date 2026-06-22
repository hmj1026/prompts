---
name: zdpos-environment
description: zdpos 5 部署環境 (CPOS217 / ZCPOS217 / UAT / DEV / local Docker) 的路徑、SSH 主機 (vm1/vm2/dev)、cron owner、MySQL 連線 / sql_mode / strict-mode listener prerequisites、application.log、POS 登入測試帳號 (local/dev/cpos218/總店/分店) 與 WSL 陷阱。Use when 提到 cron / SSH / 部署 / merchant config / docker pos_php / playwright-cli 登入測試 / SELECT @@sql_mode / event-dispatcher listener / XxxRecordWriterListener / queryBuilder()->insert。一般功能編輯不需載入。
allowed-tools: Read, Bash(ls *), Bash(cat *), Bash(docker exec *), Bash(grep *)
---

# zdpos 部署環境與基礎設施

> 觸發詞：cron / SSH / 部署 / Cloud SQL / DEV server / merchant config / 5 環境 / docker pos_php / application.log。
> 一般功能編輯不需要這份內容；無相關觸發詞時不要載入。

## 5 Environments (shared Yii codebase + per-merchant config)

| # | Env | Type | SSH | Codebase | Cron owner |
|---|-----|------|-----|----------|------------|
| 1 | CPOS217 | PROD | `vm1` (104.199.245.231) | `/var/www/zdpos_217/` | `deploy` |
| 2 | ZCPOS217 | PROD | `vm2` (104.199.182.52) | `/var/www/pos.zdn.tw/zcpos_217/` | `deploy` |
| 3 | UAT (zdpos_218) | UAT | `vm1` (shares CPOS217 host) | `/var/www/zdpos_218/` | `deploy` |
| 4 | DEV server | Dev | `dev` (192.168.2.231 internal) | `/var/www/www.zdpos.tw/zdpos_dev/` | `web` |
| 5 | local Docker | Local | localhost | `/var/www/www.posdev/zdpos-217/` (container `pos_php`) | host crontab |

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

## MySQL

| Env | Connection |
|-----|------------|
| local | `docker exec -i pos_mysql mysql -u root` (empty password); DB `zdpos_dev_2` |
| DEV/UAT/PROD | Cloud SQL Proxy (`/home/deploy/scripts/cloud-sql-proxy.sh`, started `@reboot`) |

### Read-only MCP（schema introspection；2026-06-15 建）

兩個唯讀 MCP（套件 `@benborla29/mcp-server-mysql`，`claude mcp add --scope local` → 只進個人 `~/.claude.json`，**不**進 repo——因 `.claude/` symlink 進 prompts repo，server-scope 會擴散到團隊/zdpos_dev）：
- `mysql-dev-ro` → local `pos_mysql` MySQL 5.7，帳號 `claude_ro`，`GRANT SELECT, SHOW VIEW` 給 6 個本地商家庫（含 `zdpos_dev_2`；**無** phpunit 的 `zdpos_dev`）。
- `mysql-dev-remote` → DEV `192.168.2.254` MariaDB 10.1.37（內網直連、不需 ssh tunnel），只 GRANT 11 個 dev/test/demo 庫。
- ⚠️ DEV 主機**非乾淨 sandbox**（600+ 庫含真實商家 PII）→ **永遠不要 `*.*` grant、不要省略 `MYSQL_DB` 開全庫**；擴範圍只補對應 GRANT。
- multi-DB 模式下 `DATABASE()` 為 null → 查詢**必帶 schema 前綴**（`zdpos_dev_2.<table>`），否則報 no database selected。
- 工具須**重啟 session** 後才掛載（scope local 可跨重啟存活）。**cpos218 (UAT) 暫緩**：與 PROD CPOS217 共用 Cloud SQL，連它＝直接讀 production。

## MySQL sql_mode（event-dispatcher listener prerequisites）

> 觸發：寫 `XxxRecordWriterListener` / `queryBuilder()->insert(...)` 前的 strict-mode 風險評估、`SELECT @@sql_mode` 查詢、follow-up 「production-switch」change 設計。

### Local Docker (2026-05-28 verified)

```
session_mode: ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
 global_mode: ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
```

✅ 四個 strict flag 皆不存在：`STRICT_TRANS_TABLES` / `STRICT_ALL_TABLES` / `NO_ZERO_DATE` / `NO_ZERO_IN_DATE`。

驗證指令：

```bash
docker exec -i pos_mysql mysql -u root -D zdpos_dev_2 -e \
  "SELECT @@SESSION.sql_mode AS session_mode, @@GLOBAL.sql_mode AS global_mode\G"
```

### PROD / UAT（2026-05-28 verified by user via SSH）

| Env | sql_mode | 與 local 差異 |
|---|---|---|
| PROD CPOS (CPOS217) + UAT (zdpos_218) | `ALLOW_INVALID_DATES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION` | 多 `ALLOW_INVALID_DATES`（明確允許 `0000-00-00` / `2026-02-30` 之類無效日期；比 local 更寬鬆，永不可能命中 NO_ZERO_DATE 行為）。**UAT 與 PROD CPOS 共用同一 Cloud SQL 實例 / DB，sql_mode 必然相同；不需另跑 UAT 驗證。** |
| PROD POS (ZCPOS217) | `NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION` | 少 `ERROR_FOR_DIVISION_BY_ZERO`（除零回 NULL 不發 warning）；多 `NO_AUTO_CREATE_USER`（GRANT-only，與 listener 寫入無關） |

✅ 兩個 PROD 環境（含 UAT 共用 CPOS DB）皆無 `STRICT_TRANS_TABLES` / `STRICT_ALL_TABLES` / `NO_ZERO_DATE` / `NO_ZERO_IN_DATE`，event-dispatcher listener 切到 production-switch 不會被 strict mode 擋；§10.5.2 的 MEDIUM (varchar 截斷) 與 LOW (datetime 空字串) 風險今日仍為 silent，需待 DBA 主動啟用 STRICT 才會浮現。

### DEV

DEV 最近一次記錄同 local（見 memory `trap_db_silent_truncation_test_fixture.md`：`ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION`）。任何 follow-up 「production-switch」change（如把 `PosController` inline INSERT 切到 event dispatcher）MUST 先在 PROD-equivalent DB 重跑 `SELECT @@sql_mode` 再決定 listener 是否需要補欄寬 migration / NULL 護欄。

### Listener-write strict-mode risk 速查（`add-event-dispatcher-infrastructure` §10.5.2 SSOT）

| 表 | Engine | NOT NULL 覆蓋 | varchar 截斷高風險欄 | datetime 空字串風險 |
|---|---|---|---|---|
| `log_voucher_operating` | MyISAM | ✅ 全覆蓋（含 DEFAULT 兜底） | `uby` (10) / `store_no` (10) / `sales_no` (10) | — (listener 自填 `date('Y-m-d H:i:s')`) |
| `record_dib` | MyISAM | ✅ 全覆蓋（含 DEFAULT 兜底） | `item_name` (40) | `cdate` 走 `(string)$event->cdate`，依賴 caller |
| `record_free` | MyISAM | ✅ 全覆蓋 | `customer_name` (20) / `item_name` (40) / `remark` (30) / `store_no` (10) | `cdate` nullable 但 `(string)null === ''` 在 STRICT+NO_ZERO_DATE 失敗 |

完整 per-column audit 與 LOW/MEDIUM 細節：`openspec/changes/add-event-dispatcher-infrastructure/tasks.md` §10.5 closing note（archive 後改看 `openspec/changes/archive/<date>-add-event-dispatcher-infrastructure/tasks.md`）。

### Forward-looking checklist（新增 listener 必跑）

1. `SELECT @@sql_mode` 重跑（local 至少；若是 production-switch 必含 PROD）。
2. `SHOW CREATE TABLE <target>` — 注意 `DESCRIBE` 對 `DEFAULT ''` 與 no-default 顯示一致，**MUST** 用 SHOW CREATE TABLE 才能區分。
3. 對照 listener INSERT key 列表：每個 NOT NULL 無 DEFAULT 的欄位 MUST 有 listener-supplied value。
4. datetime 欄不可塞 `(string)null` / `''`；caller 端確保傳有效 `Y-m-d H:i:s` 或 listener 用 `?: null`（前提：欄位 nullable）。
5. varchar 寬度偏緊欄（≤40）對中文輸入有截斷風險：寫 integration test 用接近上限的 fixture 探邊界（參考 memory `trap_db_silent_truncation_test_fixture.md`）。
6. MyISAM 表無 transaction → listener fire-and-forget 模式正確；但測試 cleanup MUST 手動 DELETE，不能依賴 `IntegrationTestCase` auto-rollback。

## Local Error Logs

| log | path (relative) |
|-----|-----------------|
| Yii application | `protected/runtime/application.log` (project-root relative) |
| PHP fatal/warning | `~/projects/docker_run/logs/php/error.log` (host-side docker bind mount; tilde-anchored) |

When user reports local migration / runtime error or asks to verify dev3 behavior, grep both log paths first; do not ask which config / which DB. On macOS replace `~/projects/docker_run/` with the local docker compose log mount.

## SSH

`vm1` / `vm2` / `dev` defined in `~/.ssh/config`. Claude Code has no ssh-agent → **cannot SSH directly**: ask user to run remote commands and paste results; obtain authorization each time.

## POS UI Login (playwright-cli)

> 觸發：「用 playwright-cli 跑 dev3 / dev / cpos218 登入測試」「總店/分店帳號」。
> 只支援 local / DEV / UAT(cpos218)。PROD (CPOS217 / ZCPOS217) **嚴禁** 由 AI 自動登入。

### Step 0 — Playwright-cli bootstrap（**第一次使用** machine setup）

dev3 / dev / cpos218 皆為自簽憑證（或 dev-only CA），playwright-cli 預設拒絕並印 `Error: net::ERR_CERT_AUTHORITY_INVALID`。MUST 兩步 setup（皆 idempotent-safe，可重跑）：

```bash
# 1. 安裝 chromium（Homebrew playwright-cli 不會預先帶 browser binary）
#    先用 --list 跳過已裝；無 chromium 才跑安裝（每次重跑成本 ~115 MB download）
playwright-cli install-browser --list | grep -q chromium || playwright-cli install-browser chromium

# 2. 建立 .playwright/cli.config.json（已 gitignored；若已存在則 -n 跳過避免覆寫使用者自訂）
mkdir -p .playwright
[ -f .playwright/cli.config.json ] || cat > .playwright/cli.config.json << 'EOF'
{
  "browser": {
    "browserName": "chromium",
    "contextOptions": { "ignoreHTTPSErrors": true }
  }
}
EOF
```

> `npx playwright test`（committed E2E）走 `playwright.config.js` 內 `use.ignoreHTTPSErrors: true`，**不**需要 `.playwright/cli.config.json` — 兩條路徑各自管自己。`.playwright/` 已在 `.gitignore`。

### Step 1 — 取得帳號

帳號明文 **不** 寫在本 skill；改放未追蹤檔：

```bash
cat .claude/artifacts/accounts.md
```

| 檔案存在 | 動作 |
|----------|------|
| 存在 | 從表格抓對應 env / 角色（總店 = HQ / 分店 = Branch）的 account / password |
| 不存在或內容缺該 env | 用 `AskUserQuestion` 向使用者索取，並提示「請補進 `.claude/artifacts/accounts.md`（已 .gitignore）以利下次自動使用」 |

**`accounts.md` 範本格式**（user 第一次填寫時參考）：

```markdown
| env | account | password | role | note |
|---|---|---|---|---|
| local | 116 | 0000 | Branch | 機號數量有限；--workers=1 |
| local | 888 | 888 | HQ | adminMode；不選機號 |
| dev | <ask user> | <ask user> | Branch | DEV server |
| cpos218 | <ask user> | <ask user> | Branch | UAT |
```

`role=Branch` 走前台 `/pos/index`（含機號選取）；`role=HQ` 走 adminMode，**不能**進前台（見 Step 2.5）。

### Step 2 — 登入流程 snippet

```bash
# 依需求換成 dev3 (local) / dev (DEV server) / demo218 (UAT) 的 base URL
BASE="https://www.posdev.test/dev3"
# 下方 ACCOUNT/PASSWORD 必須先執行 Step 1 取得；切勿直接寫死樣板值
ACCOUNT="<from-step-1>"
PASSWORD="<from-step-1>"

playwright-cli open "$BASE/site/login"
playwright-cli snapshot                       # 取得 account / password / 登入 button 的 ref
# 依 snapshot 結果替換 e1 / e2 / e3（POS 登入頁固定欄位：textbox "帳號 *" / textbox "密碼 *" / button "Submit"）
playwright-cli fill e1 "$ACCOUNT"
playwright-cli fill e2 "$PASSWORD"

# 必要：POS 登入頁有 keyboardDiv 軟鍵盤覆蓋 Submit 按鈕，不 hide 會 click timeout（pointer events intercepted）
playwright-cli eval "() => { var k=document.getElementById('keyboardDiv'); if(k){k.style.display='none';return 'hidden';} return 'no-keyboard'; }"

playwright-cli click e3                       # Submit；URL 應由 /site/login → /dev3/
playwright-cli snapshot                       # 驗證登入：title 變「位置:mysql 資料庫:zdpos_dev_2」、出現「總管理處 admin (權限：1)」或「<分店名> <user> (權限：N)」
```

### Step 2.5 — pos/index 必須是分店帳號 + 機號（local Docker）

`pos/index` 要進前台需要「綁機號的分店身分」。實測陷阱：

| 帳號類型 | 登入後行為 | 是否能進 `/pos/index` |
|---------|-----------|----------------------|
| 總店 (HQ) `888/888` | 進得了 `/dev3/` 後台，但會被攔在「您尚未選擇機號，無法使用前台功能」 banner | ❌ 不行 |
| 分店 (Branch) `116/0000` + 選機號 | 進 `/pos/index`，`window.POS` / `window.ItemRemarkDialog` 可用 | ✅ 必須走這條 |

**站點 (LoginForm[station]) 選機號流程**：

1. 填 `#LoginForm_username` 與 `#LoginForm_password`（fill 後 `base.js:reLoadstation()` 動態補機號選項）
2. `#LoginForm_station` 預設被 `$('#LoginForm_station').hide()` 隱藏 → `selectOption()` 會卡 `element is not visible` → **改用 DOM API 設值並 dispatch `change` event**：
   ```js
   var sel = document.getElementById('LoginForm_station');
   for (var i = 0; i < sel.options.length; i++) {
     var v = sel.options[i].value;
     if (v !== '0' && v !== '') { sel.value = v; sel.dispatchEvent(new Event('change', { bubbles: true })); break; }
   }
   ```
3. 機號被前次 session 佔用 → 表單顯示「機號重複！」並停留在 `/site/login`。隱藏的 `<input name="RepeatAction">` 是覆寫 flag：JS 設 `RepeatAction.value = '1'` 後再次 click submit 即可強制接管。
4. playwright (committed E2E) 必須在 `try { waitForURL(... !/\/site\/login/) } catch { 偵測「機號重複」→ RepeatAction=1 → 再 submit }`，否則跨 test 串接時必爆。

> Committed E2E 參考：`js/tests/e2e/item-remark-dialog-tablet-scroll.spec.js` 的 `loginPos()` helper（4 viewport 共用一個 page，避免多 session 同站點互踩）。

> 登出 (`/site/logout`) 會觸發 `beforeunload` confirmation dialog → 後續任何 playwright-cli 指令會回 `Tool ... does not handle the modal state`。必須立刻 `dialog-accept`：
>
> ```bash
> playwright-cli goto "$BASE/site/logout"
> playwright-cli dialog-accept                # 必接，否則下一個指令會卡 modal state
> ```

### Step 3 — Base URL 對照

| Env | Base URL |
|-----|----------|
| local Docker | `https://www.posdev.test/dev3/` |
| DEV server | `https://www.zdpos.tw/dev/` |
| UAT (cpos218) | `https://cpos.zdn.tw/demo218/` |

### 注意事項

- `dhpk:ui-ux-verifier` agent 的 policy 是「user 先登入、agent 不碰憑證」（`.claude/agents/dhpk:ui-ux-verifier.md`）— 與本段不衝突，那是稽核獨立性。本段僅供 ad-hoc playwright-cli / e2e 驗證。
- artifacts 路徑已在 `.gitignore`（`artifacts/`）；切勿把它移出該資料夾。
- 失敗 3 次（snapshot 找不到欄位 / 登入後仍在 /site/login）→ 停止並回報，照 `execution-policy.md` Anti-Loop。

## Misc

- File-write permission verified at runtime; if working dir is unwritable, fall back to `output/` or user-specified path.
- Paths / SSH hosts / cron owners listed here — do not re-ask user.
- On WSL local, do not add `--ignore-submodules` to `git status --short` (DrvFs NTFS inotify hang).
