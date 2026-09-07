---
name: zdpos-env-builder
description: 建立與配置 zdpos 獨立測試環境。支援自訂環境座標（DEV 或 Local）、商戶標識、來源與目標資料庫、功能分支。涵蓋資料庫安全複製、獨立碼基與設定配置、Web 薄入口、Nginx 靜態資產連結與端到端隔離驗證。
---

# ZDPOS 隔離商戶測試環境建立指南

本技能提供標準化程序，用於在進行大功能驗證（如拆帳結帳、促銷重算、金流重構）時，建立完全獨立的商戶測試環境與資料庫，避免影響主開發環境。

> 完整實作命令與除錯案例請參見同目錄的 [README.md](./README.md)。

---

## 1. 變數合約 (Variable Contract)

執行前先依情境解析以下變數。**嚴禁在腳本或文件中硬編碼明文密碼**：

| 變數名稱 | 說明 | 範例值 (DEV) | 範例值 (Local) |
|---|---|---|---|
| `TARGET_ENV` | 目標部署環境 | `dev` | `local` |
| `MERCHANT_NAME` | 隔離商戶標識（小寫英數） | `splitbill` | `splitbill` |
| `SOURCE_DB` | 來源資料庫名稱 | `zdpos_dev` | `zdpos_dev` 或 `zdpos_dev_2` |
| `TARGET_DB` | 新建目標資料庫名稱 | `zdpos_splitbill` | `zdpos_splitbill` |
| `BRANCH_NAME` | 目標功能 Git 分支 | `feature/add-split-bill-checkout_0723` | 同左 |
| `CODEBASE_DIR` | 專屬程式碼目錄名 | `zdpos_develop-splitbill` | `zdpos-217` (worktree) |
| `WEB_ROOT` | 程式碼根目錄路徑 | `/var/www/www.zdpos.tw` | `/var/www/www.posdev` |
| `PUBLIC_ROOT` | Nginx 對外服務根目錄 | `/var/www/public/www.zdpos.tw` | `/var/www/public/www.posdev` |
| `WEB_DOMAIN` | Web 站點域名 / Host Header | `www.zdpos.tw` | `www.posdev` 或 `localhost` |
| `DB_HOST` | 資料庫伺服器位址 | `192.168.2.254` | `127.0.0.1` |
| `DB_USER` | 資料庫管理帳號 | `root` | `root` 或 `develop` |
| `DB_PASS` | 資料庫連線密碼 | 自現有商戶設定檔讀取 | 自現有商戶設定檔讀取 |

> 密碼獲取途徑：直接自現有商戶設定檔（如 `protected/config/dev.php`）讀取 `$db_pass` 變數值，禁止以明文記錄於任何文件或日誌中。

---

## 2. 支援環境與基礎設施座標 (5 Environments Alignment)

對齊專案既有之 5 環境架構：

1. **DEV 伺服器 (Env #4)**：
   - 遠端主機：SSH 主機別名 `dev`（`192.168.2.231`，使用者 `web`）。
   - 資料庫主機：`192.168.2.254:3306`（MariaDB 10.1）。
   - 唯讀 MCP：`mysql-dev-remote`（帳號 `claude_ro`，僅具 SELECT/SHOW VIEW 權限，不可用於 DDL）。
   - Web 伺服器：Nginx（Web 根目錄為 `/var/www/public/www.zdpos.tw/`）。
   - 程式碼根目錄：`/var/www/www.zdpos.tw/`。
2. **Local 環境 (Env #5)**：
   - 本機主機：`localhost`。
   - 資料庫主機：`127.0.0.1:3306`（MySQL 5.7）。
   - Web 薄入口根目錄：`~/projects/www.posdev/`。
3. **PROD / UAT (Env #1, #2, #3)**：
   - 本技能專注於測試環境隔離，嚴禁在正式環境（CPOS217、ZCPOS217）自動套用本流程。

---

## 3. 四階段標準作業程序 (4-Phase SOP)

### Phase 1: 資料庫安全複製 (Database Safe Replication)

`zdpos_dev` 歷史遺留若干底層表已不存在之失效 View（如 `inform_view`, `laundry_view`, `package_view`, `reservation_table_view`, `reservation_view`, `view_facility_queue`, `visitor_view*`）。使用 `mysqldump` 必須顯式排除，否則會因 MySQL Error 1356 中斷。

1. **建立目標資料庫並配置權限**：
   ```bash
   mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" -e "
     CREATE DATABASE IF NOT EXISTS \`${TARGET_DB}\` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
     GRANT SELECT, SHOW VIEW ON \`${TARGET_DB}\`.* TO 'claude_ro'@'%';
     FLUSH PRIVILEGES;
   "
   ```
   > 說明：`claude_ro` 授權供 DEV MCP 唯讀工具檢測使用；若在 Local 環境無此帳號可略過該授權語句。

2. **安全管線匯入（排除失效 View）**：
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

3. **完成條件（Completion Criterion）**：
   - 目標資料庫 `${TARGET_DB}` 存在，且 Base Tables 總數與來源庫相符（基礎表通常 > 240 張）。
   - 核心業務表（如 `data_action`、`sales_receipt`、`data_station`）筆數與來源庫完全相符。

---

### Phase 2: 獨立碼基與商戶設定配置 (Codebase & Config)

1. **設定碼基目錄與分支**：
   ```bash
   cd "${WEB_ROOT}/${CODEBASE_DIR}"
   git checkout "${BRANCH_NAME}"
   git config core.filemode false
   ```
   > 說明：`git config core.filemode false` 防止 Linux 目錄權限調整導致 Git 誤判檔案異動。

2. **複製基礎環境檔案**：
   ```bash
   cp -p "${WEB_ROOT}/zdpos_develop/Glob.php" ./Glob.php
   cp -p "${WEB_ROOT}/zdpos_develop/.env" ./.env
   ```

3. **建立商戶設定檔** `protected/config/${MERCHANT_NAME}.php`：
   以現有 `dev.php` 為基底衍生配置：
   ```bash
   CONFIG_FILE="protected/config/${MERCHANT_NAME}.php"
   cp protected/config/dev.php "${CONFIG_FILE}"
   sed -i "s/\\\$use_name = 'dev';/\\\$use_name = '${MERCHANT_NAME}';/g" "${CONFIG_FILE}"
   sed -i "s/\\\$version = \"develop\";/\\\$version = \"develop-${MERCHANT_NAME}\";/g" "${CONFIG_FILE}"
   sed -i "s/\\\$destination = \"zdpos_develop\";/\\\$destination = \"${CODEBASE_DIR}\";/g" "${CONFIG_FILE}"
   sed -i "s/\\\$db_name = \"${SOURCE_DB}\";/\\\$db_name = \"${TARGET_DB}\";/g" "${CONFIG_FILE}"
   sed -i "s/'sessionName' => 'ZPOSDEV'/'sessionName' => 'ZPOS' . strtoupper('${MERCHANT_NAME}')/g" "${CONFIG_FILE}"
   ```

4. **建立 Console 設定檔** `protected/config/console.php`：
   確保 `yiic` 命令行工具指向新建的目標資料庫：
   ```bash
   CONSOLE_FILE="protected/config/console.php"
   if [ -f "${CONSOLE_FILE}" ]; then
     sed -i "s/dbname=${SOURCE_DB}/dbname=${TARGET_DB}/g" "${CONSOLE_FILE}"
   fi
   ```

5. **確保 Runtime 目錄可寫**：
   ```bash
   mkdir -p protected/runtime/tracy
   chmod -R 777 protected/runtime
   ```

6. **完成條件（Completion Criterion）**：
   - `protected/config/${MERCHANT_NAME}.php` 與 `protected/config/console.php` 經 `php -l` 檢驗無語法錯誤。
   - `git status -s` 工作區保持乾淨，無未預期的未追蹤異動。

---

### Phase 3: Web 薄入口與 Nginx 靜態資源配置 (Web Entry & Symlinks)

Yii 架構將網頁入口與程式碼主體分離（Thin-entry）。

1. **建立薄入口目錄與入口腳本**：
   ```bash
   ENTRY_DIR="${WEB_ROOT}/${MERCHANT_NAME}"
   mkdir -p "${ENTRY_DIR}"
   cat << 'PHP_EOF' > "${ENTRY_DIR}/index.php"
   <?php
   $version = "develop-MERCHANT_NAME_PLACEHOLDER";
   $destination = strlen($version) > 0 ? "zdpos_".$version : "zdpos";
   $yii = '../yii_framework/yii.php';
   $config = '../' . $destination . '/protected/config/MERCHANT_NAME_PLACEHOLDER.php';
   $uploadPath = dirname(__FILE__);

   date_default_timezone_set("Asia/Taipei");
   require_once($yii);
   $app = Yii::createWebApplication($config);
   $app->run();
   PHP_EOF
   sed -i "s/MERCHANT_NAME_PLACEHOLDER/${MERCHANT_NAME}/g" "${ENTRY_DIR}/index.php"

   mkdir -p "${ENTRY_DIR}"/{assets,log,upload,images,download}
   chmod -R 777 "${ENTRY_DIR}"
   ```

2. **建立 Nginx Document Root 軟連結**：
   ```bash
   ln -sf "${WEB_ROOT}/${MERCHANT_NAME}" "${PUBLIC_ROOT}/${MERCHANT_NAME}"
   ```

3. **建立 Nginx 靜態資源對外軟連結**：
   避免後端程式碼暴露，於 `${PUBLIC_ROOT}/${CODEBASE_DIR}/` 僅連結靜態資源目錄：
   ```bash
   PUBLIC_DIR="${PUBLIC_ROOT}/${CODEBASE_DIR}"
   CODE_DIR="${WEB_ROOT}/${CODEBASE_DIR}"
   mkdir -p "${PUBLIC_DIR}"
   for d in assets ckeditor css images js media; do
     ln -sf "${CODE_DIR}/${d}" "${PUBLIC_DIR}/${d}"
   done
   ```

4. **完成條件（Completion Criterion）**：
   - `${PUBLIC_ROOT}/${MERCHANT_NAME}` 軟連結正確指向薄入口。
   - `${PUBLIC_ROOT}/${CODEBASE_DIR}` 包含 `assets`、`css`、`js` 等 6 個靜態目錄軟連結。

---

### Phase 4: 端到端連線與隔離性驗證 (E2E Verification Gate)

1. **HTTP 狀態碼檢測**：
   ```bash
   curl -k -s -o /dev/null -w '%{http_code}\n' "https://127.0.0.1/${MERCHANT_NAME}/" -H "Host: ${WEB_DOMAIN}"
   # 必須為 200
   ```

2. **靜態資產連線檢測**：
   ```bash
   curl -k -s -o /dev/null -w '%{http_code}\n' "https://127.0.0.1/${CODEBASE_DIR}/css/login.css" -H "Host: ${WEB_DOMAIN}"
   curl -k -s -o /dev/null -w '%{http_code}\n' "https://127.0.0.1/${CODEBASE_DIR}/js/jquery-1.9.1.min.js" -H "Host: ${WEB_DOMAIN}"
   # 必須皆為 200
   ```

3. **資料庫連線座標檢測**：
   ```bash
   curl -k -s "https://127.0.0.1/${MERCHANT_NAME}/" -H "Host: ${WEB_DOMAIN}" | grep -o '資料庫:[^ <]*'
   # 輸出確認包含：資料庫:${TARGET_DB}
   ```

4. **完成條件（Completion Criterion）**：
   - 入口頁面 HTTP 回應碼為 200。
   - 核心 CSS 與 JS 靜態資源回應碼為 200（無 404）。
   - 頁首顯示之連線資料庫名稱明確為 `${TARGET_DB}`，確認已完成資料庫隔離。

---

## 4. 職責邊界與業務解耦宣告 (Scope & Decoupling Boundaries)

- **環境建置邊界 (In-Scope)**：
  本技能的核心職責為基礎設施與隔離環境建置（獨立資料庫複製、碼基配置、Web 薄入口、Nginx 靜態資產軟連結、端到端連線與資料庫隔離性驗收）。Phase 4 驗證通過即代表環境建置就緒。
- **功能專屬步驟 (Out-of-Scope)**：
  任何特定功能的新增資料表（例如 `sales_relation`、`split_bill_*`）、專屬索引定義、功能開關（如 Gate A 的 `available = 0`），以及 `yiic migrate new` / `up`，均屬於應用層個別業務部署範疇，**嚴禁**列為通用環境建置之必備條件。環境就緒後，若需套用業務異動，請參照該功能的專屬 Playbook 進行。

---

## 5. 實戰避坑原則 (Traps)

1. **Nginx 404**：DEV 的 Document Root 在 `${PUBLIC_ROOT}`，若漏建商戶軟連結會導致 HTTP 404。
2. **靜態資源 404 與 JS 崩潰**：漏建 `${PUBLIC_ROOT}/${CODEBASE_DIR}/` 靜態目錄軟連結會導致 `login.css` 與 `keyboard.js` 404，進而引發 `$(...).keyboard is not a function` 錯誤。
3. **Git 工作區大量 modified 檔案**：目錄 `chmod` 會變更 filemode，必須執行 `git config core.filemode false`。
4. **Session 互相覆蓋**：商戶設定檔必須指定獨立的 `sessionName`（如 `ZPOS${MERCHANT_NAME}`），防止與主開發站共用 Session。
5. **瀏覽器外掛干擾報錯**：主控台出現 `content_main.js` 報錯通常為 Chrome 擴充套件（如翻譯工具）引起，使用無痕視窗開啟即可排除干擾。
6. **唯讀 MCP 無法執行 DDL**：`claude_ro` 僅具唯讀權限，建立資料庫或執行 Dump/Restore 必須以具備權限之帳號於伺服器內網執行，完成後再授權 `claude_ro`。
