# MySQL — 連線 / 唯讀 MCP / sql_mode / listener strict-mode 風險

> zdpos-environment skill 子檔。觸發：MySQL 連線、schema introspection、`SELECT @@sql_mode`、寫 `XxxRecordWriterListener` / `queryBuilder()->insert(...)` 前的 strict-mode 風險評估、follow-up「production-switch」change 設計。

## MySQL 連線

| Env | Connection |
|-----|------------|
| local | `docker exec -i pos_mysql mysql -u root` (empty password); DB `zdpos_dev_2` |
| DEV/UAT/PROD | Cloud SQL Proxy (`/home/deploy/scripts/cloud-sql-proxy.sh`, started `@reboot`) |

### Read-only MCP（schema introspection；2026-06-15 建）

三個唯讀 MCP（套件 `@benborla29/mcp-server-mysql`，`claude mcp add --scope local` → 只進個人 `~/.claude.json`，**不**進 repo——因 `.claude/` symlink 進 prompts repo，server-scope 會擴散到團隊/zdpos_dev）：
- `mysql-dev-ro` → local `pos_mysql` MySQL 5.7，帳號 `claude_ro`，`GRANT SELECT, SHOW VIEW` 給 6 個本地商家庫（含 `zdpos_dev_2`；**無** phpunit 的 `zdpos_dev`）。
- `mysql-dev-remote` → DEV `192.168.2.254` MariaDB 10.1.37（內網直連、不需 ssh tunnel），只 GRANT 11 個 dev/test/demo 庫。
- `mysql-uat-remote` → UAT `192.168.2.247:5058`（Cloud SQL Proxy，2026-07-17 建；**與 PROD CPOS217 共用同一 Cloud SQL 實例**，`SHOW DATABASES` 可見 280+ 個真實商家正式營運庫），帳號 `claude_ro`，**只 GRANT `zdpos_demo218` 這一個庫**（注意：`SKILL.md` 的部署表寫的 `zdpos_218` 是 UAT **codebase / deploy 目錄名**〔`/var/www/zdpos_218/`〕，跟這裡的 **DB schema 名**`zdpos_demo218` 不是同一個字串，查詢下 schema 前綴時勿混用）。⚠️ 此帳號**禁止**再補 `*.*` 或任何其他商家庫的 GRANT——擴權限前務必先問過本檔這段風險說明。
- ⚠️ DEV 主機**非乾淨 sandbox**（600+ 庫含真實商家 PII）→ **永遠不要 `*.*` grant、不要省略 `MYSQL_DB` 開全庫**；擴範圍只補對應 GRANT。UAT/PROD 共用實例風險更高，同一原則加倍適用。
- multi-DB 模式下 `DATABASE()` 為 null → 查詢**必帶 schema 前綴**（`zdpos_dev_2.<table>` / `zdpos_demo218.<table>`），否則報 no database selected。
- 工具須**重啟 session** 後才掛載（scope local 可跨重啟存活）。

## MySQL sql_mode（event-dispatcher listener prerequisites）

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

✅ 兩個 PROD 環境（含 UAT 共用 CPOS DB）皆無 `STRICT_TRANS_TABLES` / `STRICT_ALL_TABLES` / `NO_ZERO_DATE` / `NO_ZERO_IN_DATE`，event-dispatcher listener 切到 production-switch 不會被 strict mode 擋；下方 MEDIUM (varchar 截斷) 與 LOW (datetime 空字串) 風險今日仍為 silent，需待 DBA 主動啟用 STRICT 才會浮現。

### DEV

DEV 最近一次記錄同 local（見 memory `trap_db_silent_truncation_test_fixture.md`：`ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION`）。任何 follow-up 「production-switch」change（如把 `PosController` inline INSERT 切到 event dispatcher）MUST 先在 PROD-equivalent DB 重跑 `SELECT @@sql_mode` 再決定 listener 是否需要補欄寬 migration / NULL 護欄。

### Listener-write strict-mode risk 速查（surviving SSOT；原 `add-event-dispatcher-infrastructure` §10.5.2）

| 表 | Engine | NOT NULL 覆蓋 | varchar 截斷高風險欄 | datetime 空字串風險 |
|---|---|---|---|---|
| `log_voucher_operating` | MyISAM | ✅ 全覆蓋（含 DEFAULT 兜底） | `uby` (10) / `store_no` (10) / `sales_no` (10) | — (listener 自填 `date('Y-m-d H:i:s')`) |
| `record_dib` | MyISAM | ✅ 全覆蓋（含 DEFAULT 兜底） | `item_name` (40) | `cdate` 走 `(string)$event->cdate`，依賴 caller |
| `record_free` | MyISAM | ✅ 全覆蓋 | `customer_name` (20) / `item_name` (40) / `remark` (30) / `store_no` (10) | `cdate` nullable 但 `(string)null === ''` 在 STRICT+NO_ZERO_DATE 失敗 |

> 完整 per-column audit（LOW/MEDIUM 細節）原在 `add-event-dispatcher-infrastructure` change 的 `tasks.md` §10.5 closing note，該 change 已 squash-merge 進 develop、未獨立 archive（merged spec `openspec/specs/event-dispatcher/spec.md` 不含此審計）。現存 SSOT = 上方 strict-mode risk 速查表 + memory `trap_db_silent_truncation_test_fixture.md`。

### Forward-looking checklist（新增 listener 必跑）

1. `SELECT @@sql_mode` 重跑（local 至少；若是 production-switch 必含 PROD）。
2. `SHOW CREATE TABLE <target>` — 注意 `DESCRIBE` 對 `DEFAULT ''` 與 no-default 顯示一致，**MUST** 用 SHOW CREATE TABLE 才能區分。
3. 對照 listener INSERT key 列表：每個 NOT NULL 無 DEFAULT 的欄位 MUST 有 listener-supplied value。
4. datetime 欄不可塞 `(string)null` / `''`；caller 端確保傳有效 `Y-m-d H:i:s` 或 listener 用 `?: null`（前提：欄位 nullable）。
5. varchar 寬度偏緊欄（≤40）對中文輸入有截斷風險：寫 integration test 用接近上限的 fixture 探邊界（參考 memory `trap_db_silent_truncation_test_fixture.md`）。
6. MyISAM 表無 transaction → listener fire-and-forget 模式正確；但測試 cleanup MUST 手動 DELETE，不能依賴 `IntegrationTestCase` auto-rollback。
