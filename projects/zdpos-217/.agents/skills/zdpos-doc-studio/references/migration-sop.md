# 既有客戶導入新制度之設定 SOP 與注意事項 (Migration SOP Reference)

當模組涉及「既有舊資料／無限期舊客戶轉型啟用新制度（如點數效期制、拆帳規範化）」時，必須在第 6 大章依照本標準指引撰寫。

---

## 1. 核心安全設計：零中斷向後相容 (Fail-Safe Fallback)
在實體資料表剛由 Migration 建立、但尚未針對該商戶執行資料遷移前：
1. **空表檢測 (No Batch Data)**：核心 Service 在讀取批次資料前，必須調用 `hasPointBatches()` 或檢查狀態欄位。若無歷史批次資料，一律**判定為未啟用新制**。
2. **自動降級 (Graceful Degradation)**：系統自動回退至舊版純量邏輯（走舊版欄位加減），並於日誌記錄 `isExpirySystemEnabled=false reason=NO_BATCH_DATA 走預設點數舊制方法`。
3. **商業保證**：部署新程式碼至生產環境時，未遷移的既存商戶前台收銀與結帳完全不受任何影響。

---

## 2. 標準 6 步驟導入 SOP (Step-by-Step SOP)

1. **Step 1：確認商戶政策與舊資料處置方針**
   - 明確新規則（例如：年度固定 1 年 7 個月、或按月浮動）。
   - **歷史舊資料處理決策**：確認歷史累積資料（如數年前的舊點數）是要設定寬限期統一延展，還是嚴格按歷史單據時間計算（防範次日排程啟動時瞬間清零客訴）。
2. **Step 2：安排維護窗口與資料庫備份**
   - 於夜間閉店離峰執行，防止前台併發寫入。
   - 使用 `mysqldump` 備份關鍵資料表（`data_customer`, `record_point`, `system_config`）。
3. **Step 3：規則設定與 system_config 綁定**
   - 確認規則表中的規則 ID，並更新系統參數指向該規則。
4. **Step 4：執行歷史資料批次遷移 CLI (Migration Command)**
   - 執行指令：`php ./protected/yiic.php <CommandName> run --config={tenant_config}`。
   - **內部機制**：
     - 分頁批次處理（例如以 Generator 每批 500 筆，避免 OOM）。
     - 時間軸重播歷史（Event Sourcing Replay）。
     - 差異自動補正平帳（例如 `PointEvent::MIGRATION_ADJUSTMENT = 99`），確保重播總額與客戶現有點數 100% 絕對吻合。
5. **Step 5：執行數據完整性校驗 (Validate)**
   - 執行校驗指令：`php ./protected/yiic.php <CommandName> validate --config={tenant_config}`。
   - 確認差異筆數為 0。若發現未預期偏差，使用 `cleanup` 指令清空後重新除錯。
6. **Step 6：配置每日定時排程 (Cron Job)**
   - 於 Crontab 配置定時排程（如每日凌晨 00:05 執行）：
     `5 0 * * * php /var/www/zdpos/protected/yiic.php <CommandName> process --config={tenant_config} >> /var/log/zdpos/task.log 2>&1`。
7. **Step 7：前後台功能驗收與上線**
   - 前台收銀：測試正向累加、FIFO 扣減、作廢還原。
   - 後台管理：查看統計總表與用戶歷程。

---

## 3. 關鍵避坑指引 (Critical Gotchas)

- **🚨 歷史舊點數/資料瞬間清零客訴雷區**：若未設寬限期，歷史 2 年前的消費在算入新效期後已是過去時間，排程啟動當天會被直接清零。務必在遷移前協商寬限期策略。
- **⚠️ 作廢防死而復生**：若原扣除批次在作廢當下已過期，系統必須阻斷作廢，防止已過期點數藉由作廢流程重新復活。
- **💡 大規模資料遷移與記憶體管理**：百萬級歷史資料請配置 CLI `memory_limit` 至少 512M 或 1024M，並善用 `gc_collect_cycles()`。
- **🛑 第三方外部系統互斥**：若會員或訂單屬於外部第三方雲端（如 Yo-SVIP / Ocard），系統應自動旁路跳過本地到期運算，交由外部 API 處理。
