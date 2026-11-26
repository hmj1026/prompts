---
name: zdpos-environment
description: environment 座標與 POS 操作路由。Use when 答案涉及環境座標或 POS 前台操作（非純程式／欄位邏輯）：站台網址對應碼基/DB/PHP pool、SSH/Docker/MySQL/MCP 座標、PROD slow log 與 DB 主機、POS 登入（playwright-cli／agent-browser／pos-guard）或功能鍵操作步驟。
allowed-tools: Read, Bash(ls *), Bash(cat *), Bash(docker exec *), Bash(grep *), Bash(awk *), Bash(realpath *), Bash(dirname *), Bash(test *)
---

# zdpos 部署環境與基礎設施

5 環境總表與 vm1 測試站座標在下方；細節配置披露於 `references/`，依需求讀取對應子檔後再作答或操作。

## 5 Environments（shared Yii codebase + per-merchant config）

| # | Env | Type | SSH | Codebase | Cron owner |
|---|---|---|---|---|---|
| 1 | CPOS217 | PROD | `vm1` (104.199.245.231) | `/var/www/zdpos_217/` | `deploy` |
| 2 | ZCPOS217 | PROD | `vm2` (104.199.182.52) | `/var/www/pos.zdn.tw/zcpos_217/` | `deploy` |
| 3 | UAT (`zdpos_218`) | UAT | `vm1`（共用 CPOS217 主機） | `/var/www/zdpos_218/`（`/demo218/`；對照站見下方 vm1 測試站座標） | `deploy` |
| 4 | DEV server | Dev | `dev` (192.168.2.231 internal) | `/var/www/www.zdpos.tw/zdpos_develop/`（URL `www.zdpos.tw/dev`、DB `zdpos_dev`；詳 `references/multi-site.md`） | `web` |
| 5 | local Docker | Local | localhost | `/var/www/www.posdev/zdpos-217/`（container `pos_php`） | host crontab |

### vm1 測試站座標

完整結構見 `/home/paul/projects/zdpos-217-docs/docs/operations/vm1-architecture-overview.md`（§4.3 runtime map、§5.1 碼基、§8.2 發票與 DB）：

| 入口 / 站台 | 碼基 | PHP Pool | DB / 備註 |
|---|---|---|---|
| `/sb84/` | `zdpos_218_sb84` | PHP 8.4 `zdpos-uat` | DB `zdpos_sb84` |
| `/sb56/` | `zdpos_218_sb` | map `default` PHP 5.6 | 同 DB `zdpos_sb84`（禁開票；碼基發票目錄 `invoices-sb218`） |
| `/php84/` | `zdpos_218_php84` | PHP 8.4 `zdpos-uat` | DB `zdpos_php84` |
| 186 canary | `zdpos_217_sb84` | — | 專供 186 canary |

## 細節路由（按需讀取子檔）

| 需求 / 觸發情境 | 對應文件與區塊 anchor |
|---|---|
| merchant config SSOT、新增商家、**本地 dev4 入口、linked-worktree URL 碼基 identity、runtime/tracy 可寫性**、yiic／docker exec workdir、SSH 主機定義、local `application.log` | `references/environments.md`（`### Local dev4 entry` / `## Command templates` / `## SSH` / `## Local Error Logs`） |
| URL 對應碼基、thin-entry、`cpos.zdpos.tw`／`www.zdpos.tw`／`www.posdev.test`、`oklao(2/3/dev4)`、`X:Y:Z` 或 vm2 UNC `\pos`／`\logs` 直讀、network share 掛載、遠端 opcache 假象 | `references/multi-site.md`（`## 多站部署架構`） |
| DEV web 主機設定：FPM pool、nginx vhost／upstream／`fastcgi_pass`、public 薄入口與靜態目錄佈局、站台切 PHP 版本 | `references/dev-web-topology.md`（先跑實測探針確認現況，以實測取代 playbook 推論） |
| MySQL 連線、唯讀 schema MCP、改 DEV `system_config` 測試前提、`SELECT @@sql_mode`、strict-mode listener 風險、`XxxRecordWriterListener`、`queryBuilder()->insert`、production-switch change | `references/mysql.md`（`## MySQL 連線` / `### Read-only MCP` / `### DEV 設定寫入` / `## MySQL sql_mode`） |
| playwright-cli 登入 `dev4`／`dev`／`cpos218`、總店(HQ)／分店(Branch) 帳號、機號選取、`keyboardDiv` overlay、機號重複 `RepeatAction`、遠端 dev4 前台登入 | `references/pos-login.md`（`## POS UI Login (playwright-cli)`：`### Step 0` / `### Step 2.5` / `### 遠端 dev4 前台登入`） |
| PROD 慢請求／慢查詢調查、vm1／vm2 slow log 路徑與門檻、站台 DB 主機（Cloud SQL `10.8.202.2` 或 vm2 XAMPP）、SQL 文字可查性 | `references/prod-observability.md` |
| agent-browser 測 POS 前台／後台、派 QA subagent、**UAT／vm1 前台發票攔截 `pos-guard`**（登入後一律走 `scripts/pos-guard.sh`；`login`／`logout` 走 `scripts/pos-ab.sh`；放行與擋下範圍、作廢核准、已知限制）、點擊沒反應、`/record/*` 403 | `references/agent-browser-pos.md`（`## UAT／vm1 前台：一律經 pos-guard` / `## 操作沒反應時先查這張表`） |
| POS 操作步驟、功能鍵頁次與行為（`data_button`＋`data_action`）、桌位模式開桌／收單／續單／作廢、清測試暫存單 | `references/pos-operations.md` |
| **vm1 全貌**：網域→docroot→PHP pool／nginx runtime map、`cpos.zdn.tw` 入口對應碼基、**migration 走 pms／pms-yii**（取代碼基 console）、**正式發票佇列** `glob-storage/invoices`、cron／systemd、Samba | `/home/paul/projects/zdpos-217-docs/docs/operations/vm1-architecture-overview.md`（§9 背景作業與 migration、§10 共用儲存、§11 必讀陷阱） |

## 操作邊界與完成條件

- **PROD 隔離**：AI 自動登入（含 playwright-cli）僅限 local、DEV 與 UAT（`cpos218`）；PROD（CPOS217 / ZCPOS217）嚴禁自動登入，改由人工操作。
- **WSL local git status**：執行 `git status --short` 時直接執行、省略 `--ignore-submodules`（避免 DrvFs NTFS inotify hang）。
- **輸出路徑**：工作目錄不可寫時，將輸出寫入 `output/` 或使用者指定路徑。
- **完成條件**：所有命中的路由子檔已讀取並核對實況（不憑記憶或 playbook 推論）；自動登入目標已確認非 PROD；UAT／vm1 前台操作經 `scripts/pos-guard.sh`（`login`／`logout` 經 `scripts/pos-ab.sh`）；WSL `git status --short` 不含 `--ignore-submodules`。
