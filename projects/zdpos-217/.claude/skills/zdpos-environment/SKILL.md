---
name: zdpos-environment
description: zdpos 5 部署環境 (CPOS217 / ZCPOS217 / UAT / DEV / local Docker) 的路徑、SSH 主機 (vm1/vm2/dev)、cron owner、MySQL 連線 / sql_mode / strict-mode listener prerequisites、application.log、POS 登入測試帳號 (local/dev/cpos218/總店/分店) 與 WSL 陷阱。Use when 提到 cron / SSH / 部署 / merchant config / docker pos_php / playwright-cli 登入測試 / SELECT @@sql_mode / event-dispatcher listener / XxxRecordWriterListener / queryBuilder()->insert / cpos.zdpos.tw·www.zdpos.tw·www.posdev.test 某 URL 跑哪份碼基 / oklao(2/3) thin-entry / X:Y:Z 或 vm2 UNC (\pos \logs) 直讀 / network share 掛載——重點是答案需要環境座標（主機/帳密/測試帳號/schema 前綴/路徑），程式碼查不到也別反問。不載入：純程式邏輯 / UI / CSS / 欄位邏輯，即使句中出現 dev4·event-dispatcher·登入頁 等字。
allowed-tools: Read, Bash(ls *), Bash(cat *), Bash(docker exec *), Bash(grep *)
---

# zdpos 部署環境與基礎設施

> Router 檔：5 環境總表在下方；各領域細節在 `references/`，**需要時才讀對應子檔**（一般功能編輯不需載入任何內容）。

## 5 Environments (shared Yii codebase + per-merchant config)

| # | Env | Type | SSH | Codebase | Cron owner |
|---|-----|------|-----|----------|------------|
| 1 | CPOS217 | PROD | `vm1` (104.199.245.231) | `/var/www/zdpos_217/` | `deploy` |
| 2 | ZCPOS217 | PROD | `vm2` (104.199.182.52) | `/var/www/pos.zdn.tw/zcpos_217/` | `deploy` |
| 3 | UAT (zdpos_218) | UAT | `vm1` (shares CPOS217 host) | `/var/www/zdpos_218/` | `deploy` |
| 4 | DEV server | Dev | `dev` (192.168.2.231 internal) | `/var/www/www.zdpos.tw/zdpos_develop/`（URL `www.zdpos.tw/dev`, DB `zdpos_dev`；詳 `references/multi-site.md`） | `web` |
| 5 | local Docker | Local | localhost | `/var/www/www.posdev/zdpos-217/` (container `pos_php`) | host crontab |

## 細節路由（讀對應子檔）

| 需求 / 觸發詞 | 讀這個子檔（含的區塊 anchor） |
|---|---|
| merchant config SSOT / 新增商家 / **本地 dev4 入口** / `## Command templates` (yiic·docker exec workdir) / **`## SSH`** 主機定義 / **`## Local Error Logs`** (application.log) | `references/environments.md`（`### Local dev4 entry` / `## Command templates` / `## SSH` / `## Local Error Logs`） |
| 某 URL 跑哪份碼基 / thin-entry / cpos.zdpos.tw·www.zdpos.tw·www.posdev.test / oklao(2/3/dev4) / `X:Y:Z` 或 vm2 UNC `\pos`·`\logs` 直讀 / network share 掛載 / 遠端 opcache 假象 | `references/multi-site.md`（`## 多站部署架構`） |
| MySQL 連線 / 唯讀 schema MCP (`### Read-only MCP`) / `SELECT @@sql_mode` / strict-mode listener 風險 / `XxxRecordWriterListener` / `queryBuilder()->insert` / production-switch change | `references/mysql.md`（`## MySQL` / `### Read-only MCP` / `## MySQL sql_mode`） |
| playwright-cli 登入 dev4 / dev / cpos218 / 總店(HQ)·分店(Branch) 帳號 / 機號選取 / keyboardDiv overlay / 機號重複 RepeatAction / 遠端 dev4 前台登入 | `references/pos-login.md`（`## POS UI Login (playwright-cli)`：`### Step 0` / `### Step 2.5` / `### 遠端 dev4 前台登入`） |

> PROD (CPOS217 / ZCPOS217) **嚴禁** 由 AI 自動登入；playwright-cli 登入只支援 local / DEV / UAT(cpos218)。

## Misc

- File-write permission verified at runtime; if working dir is unwritable, fall back to `output/` or user-specified path.
- Paths / SSH hosts / cron owners listed here — do not re-ask user.
- On WSL local, do not add `--ignore-submodules` to `git status --short` (DrvFs NTFS inotify hang).
