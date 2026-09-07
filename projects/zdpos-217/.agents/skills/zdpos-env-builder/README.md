# ZDPOS 測試環境建置技能 (zdpos-env-builder) 實作範例

本文件記錄以 **拆帳結帳功能 (Split Bill) 於內部 DEV 伺服器** 建立隔離測試環境的真實完整過程，供 Agent 與開發者參照執行。

---

## 1. 範例情境與變數定義 (Scenario Parameters)

| 變數名稱 | 實作值 | 說明 |
|---|---|---|
| `TARGET_ENV` | `dev` | 內部 DEV 伺服器 (192.168.2.231，SSH 別名 `dev`) |
| `MERCHANT_NAME` | `splitbill` | 獨立商戶識別名稱 |
| `SOURCE_DB` | `zdpos_dev` | 來源資料庫 (192.168.2.254 MariaDB 10.1) |
| `TARGET_DB` | `zdpos_splitbill` | 新建隔離資料庫 |
| `BRANCH_NAME` | `feature/add-split-bill-checkout_0723` | 拆帳功能分支 (HEAD `8c76830d`) |
| `CODEBASE_DIR` | `zdpos_develop-splitbill` | 專屬程式碼目錄名 |
| `DB_HOST` | `192.168.2.254` | 資料庫主機 |
| `DB_USER` | `root` | 資料庫管理帳號 |
| `DB_PASS` | `${DB_PASS}` | 自 `protected/config/dev.php` 中 `$db_pass` 讀取 |

---

## 2. 實作完整流程記錄 (Execution Walkthrough)

### Step 1: 連線至 DEV 主機
```bash
ssh dev
# 以 web 使用者連線至 DEV 主機 (192.168.2.231)
```

### Step 2: 資料庫複製 (zdpos_dev -> zdpos_splitbill)
1. **建立新資料庫並授權 MCP 唯讀帳號**：
   ```bash
   mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" -e "
     CREATE DATABASE IF NOT EXISTS \`${TARGET_DB}\` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
     GRANT SELECT, SHOW VIEW ON \`${TARGET_DB}\`.* TO 'claude_ro'@'%';
     FLUSH PRIVILEGES;
   "
   ```

2. **安全管線 Dump & Restore（排除失效 View）**：
   > 說明：`zdpos_dev` 存在 9 個底層表不存在之失效 View（如 `inform_view`、`laundry_view`），使用 `--ignore-table` 排除以避免 MySQL Error 1356 中斷。
   ```bash
   mysqldump -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" \
     --single-transaction --skip-lock-tables --routines --triggers \
     --ignore-table="${SOURCE_DB}.inform_view" \
     --ignore-table="${SOURCE_DB}.laundry_view" \
     --ignore-table="${SOURCE_DB}.package_view" \
     --ignore-table="${SOURCE_DB}.reservation_table_view" \
     --ignore-table="${SOURCE_DB}.reservation_view" \
     --ignore-table="${SOURCE_DB}.view_facility_queue" \
     --ignore-table="${SOURCE_DB}.visitor_view" \
     --ignore-table="${SOURCE_DB}.visitor_view1" \
     --ignore-table="${SOURCE_DB}.visitor_view2" \
     "${SOURCE_DB}" | mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${TARGET_DB}"
   ```

3. **資料驗收比對**：
   - 匯入物件數：249 張 Base Tables + 63 個有效 View = 共 312 張表。
   - 核心業務表 row count（`sales_receipt: 6904`、`data_action: 139`、`data_station: 40`）與來源庫 100% 相符。

---

### Step 3: 配置獨立碼基與商戶設定
1. **工作區設定**：
   ```bash
   cd "/var/www/www.zdpos.tw/${CODEBASE_DIR}"
   git checkout "${BRANCH_NAME}"
   git config core.filemode false
   ```

2. **複製環境基礎設定檔**：
   ```bash
   cp -p /var/www/www.zdpos.tw/zdpos_develop/Glob.php ./Glob.php
   cp -p /var/www/www.zdpos.tw/zdpos_develop/.env ./.env
   ```

3. **建立商戶設定檔** `protected/config/splitbill.php`：
   - 設定 `$use_name = 'splitbill';`
   - 設定 `$version = "develop-splitbill";`
   - 設定 `$destination = "zdpos_develop-splitbill";`
   - 設定 `$db_name = "zdpos_splitbill";`
   - 設定獨立 Session 防止踢線：`sessionName => 'ZPOSSPLITBILL'`。

4. **建立 Console 設定檔** `protected/config/console.php`：
   - 設定 `components.db` 連線至 `${TARGET_DB}`，確保 `yiic` 命令行工具連線至新庫。

5. **配置 Runtime 權限**：
   ```bash
   mkdir -p protected/runtime/tracy
   chmod -R 777 protected/runtime
   ```

---

### Step 4: 建立 Web 薄入口與 Nginx 靜態資源 Symlinks
1. **建立薄入口目錄與 `index.php`**：
   ```bash
   mkdir -p "/var/www/www.zdpos.tw/${MERCHANT_NAME}"
   cat << 'PHP_EOF' > "/var/www/www.zdpos.tw/${MERCHANT_NAME}/index.php"
   <?php
   $version = "develop-splitbill";
   $destination = strlen($version) > 0 ? "zdpos_".$version : "zdpos";
   $yii = '../yii_framework/yii.php';
   $config = '../' . $destination . '/protected/config/splitbill.php';
   $uploadPath = dirname(__FILE__);

   date_default_timezone_set("Asia/Taipei");
   require_once($yii);
   $app = Yii::createWebApplication($config);
   $app->run();
   PHP_EOF

   mkdir -p "/var/www/www.zdpos.tw/${MERCHANT_NAME}"/{assets,log,upload,images,download}
   chmod -R 777 "/var/www/www.zdpos.tw/${MERCHANT_NAME}"
   ```

2. **建立 Nginx Document Root 軟連結（防止 404）**：
   ```bash
   ln -sf "/var/www/www.zdpos.tw/${MERCHANT_NAME}" "/var/www/public/www.zdpos.tw/${MERCHANT_NAME}"
   ```

3. **建立 Nginx 靜態資產對外軟連結（防止 CSS/JS 404）**：
   ```bash
   PUBLIC_TARGET="/var/www/public/www.zdpos.tw/${CODEBASE_DIR}"
   CODE_SOURCE="/var/www/www.zdpos.tw/${CODEBASE_DIR}"
   mkdir -p "${PUBLIC_TARGET}"
   for d in assets ckeditor css images js media; do
     ln -sf "${CODE_SOURCE}/${d}" "${PUBLIC_TARGET}/${d}"
   done
   ```

---

### Step 5: 選用後續示範：特定業務之 Migration 與 Schema 驗收（以拆帳為例）
> 說明：本步驟為拆帳結帳功能的專屬業務範例。通用的 `zdpos-env-builder` 建置流程在完成 Step 4 與 Step 6 連線驗證後即代表環境就緒。個別功能是否執行 Migration 與專屬 Schema 驗收，屬於應用層業務範疇，由該功能的需求與 Playbook 決定。

1. **套用 Migration**：
   ```bash
   cd "/var/www/www.zdpos.tw/${CODEBASE_DIR}"
   export ZDPOS_APPROVE_LARGE_MYISAM_TAXTYPE_MIGRATION=I_ACCEPT_MYISAM_TABLE_LOCK
   echo 'yes' | php protected/yiic.php migrate up
   ```
   - 成功套用 11 支 migration（核心 7 支 + 認損 3 支 + 稅別 1 支）。

2. **Schema 驗證重點指標**：
   - 3 張新表（`sales_relation`, `split_bill_session`, `split_bill_payment_reconciliation`）皆為 `InnoDB`。
   - 8 個專屬索引之第一前導欄位皆為 `store_no`。
   - `sales_receiptlist.saleslist_tax_type` 存在，既有 12,383 筆資料皆為 `NULL`。
   - 安全開關：`customer_module.SplitBill.available` 與 `SplitBillLossInv.available` 皆保持為 `0`。

---

### Step 6: 驗證 HTTP 狀態與隔離性
1. **檢查首頁 HTTP 回應**：
   ```bash
   curl -k -s -o /dev/null -w '%{http_code}\n' "https://127.0.0.1/${MERCHANT_NAME}/" -H 'Host: www.zdpos.tw'
   # 回傳 200
   ```
2. **檢查靜態資源回應**：
   ```bash
   curl -k -s -o /dev/null -w '%{http_code}\n' "https://127.0.0.1/${CODEBASE_DIR}/css/login.css" -H 'Host: www.zdpos.tw'
   # 回傳 200
   ```
3. **檢查資料庫座標顯示**：
   ```bash
   curl -k -s "https://127.0.0.1/${MERCHANT_NAME}/" -H 'Host: www.zdpos.tw' | grep -o '資料庫:[^ <]*'
   # 輸出確認包含：資料庫:zdpos_splitbill
   ```

---

## 3. 實戰踩坑與解決排查手記 (Troubleshooting Notes)

### 案例 1: mysqldump Error 1356 (View references invalid table)
- **現象**：Dump 中途異常退出，新資料庫僅建立 129 張表。
- **根因**：來源庫存在 9 個底層表已刪除的失效 View。
- **處置**：使用 `--ignore-table` 參數逐一排除該 9 個 View，即可順利匯入其餘 312 個物件。

### 案例 2: Web 薄入口 404 (Not Found)
- **現象**：瀏覽器連線 `https://www.zdpos.tw/splitbill/` 回傳 404。
- **根因**：DEV Nginx 的 Document Root 設定在 `/var/www/public/www.zdpos.tw/`，若僅建立 `/var/www/www.zdpos.tw/splitbill/`，Nginx 無法找到路徑。
- **處置**：在 `/var/www/public/www.zdpos.tw/splitbill` 建立軟連結指向實際入口。

### 案例 3: 靜態資產 404 與 `$(...).keyboard is not a function`
- **現象**：首頁 HTML 載入成功但無樣式，Console 噴出 `keyboard.js` 404 與相關 JS 錯誤。
- **根因**：Yii 的 `$reference_url` 指向程式碼目錄名（`${CODEBASE_DIR}`），Nginx public 下若無該目錄的靜態資源軟連結會找不到檔案。
- **處置**：於 `/var/www/public/www.zdpos.tw/${CODEBASE_DIR}/` 建立 `css`、`js`、`images` 等目錄之軟連結。

### 案例 4: `chmod` 導致 Git 出現大量 modified 檔案
- **現象**：調整目錄權限後，`git status` 顯示成千上萬筆 `M` 檔案。
- **根因**：Git 的 `core.filemode` 追蹤了檔案權限屬性變化（644 變成 777）。
- **處置**：執行 `git config core.filemode false` 即可忽略權限變化，恢復工作區乾淨度。

### 案例 5: 瀏覽器 Console 出現 `content_main.js` 錯誤
- **現象**：`content_main.js:14829 Uncaught TypeError: Cannot read properties of undefined (reading 'toLowerCase')`。
- **根因**：此為使用者瀏覽器擴充套件（Chrome Extension Content Script，如翻譯或快捷鍵外掛）的內部報錯，非 POS 系統程式碼問題。
- **處置**：改以 Chrome 無痕視窗（Ctrl+Shift+N）開啟即可排除外掛干擾。
