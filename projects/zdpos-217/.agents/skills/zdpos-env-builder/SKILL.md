---
name: zdpos-env-builder
description: zdpos 隔離測試環境建置 SOP。Use when 在 DEV 或 Local 建立獨立商戶測試站（複製 DB、配置碼基／thin-entry／Nginx），或在 vm1 複製正式商家庫架設隔離測試站（含發票與外部整合隔離）。
---

# ZDPOS 隔離商戶測試環境建置指南

建立完全獨立的商戶測試資料庫、碼基、Web 薄入口與 Nginx 靜態資源連結，直到端到端 HTTP 與資料庫隔離驗證全數通過。

## 參考文件路由

| 情境 | 先讀檔案／技能 |
|---|---|
| 來源為正式商家庫（Phase 2.5 完整 8 項隔離規格與驗證指令），或套用 Phase 3 PHP 5.6／DEV 8.4／vm1 8.4 薄入口模板與 symlink 指令 | [references/prod-clone-isolation.md](./references/prod-clone-isolation.md) |
| 查閱 DEV 完整實作範例與排查手記 | [references/dev-walkthrough.md](./references/dev-walkthrough.md) |
| 查詢 DEV／Local 基礎設施座標（SSH、DB 主機、Nginx Document Root、唯讀 MCP `mysql-dev-remote`／`claude_ro`） | skill `zdpos-environment` |
| 查詢 vm1 網域、碼基、PHP pool、migration（走 pms-yii）與發票佇列 | `/home/paul/projects/zdpos-217-docs/docs/operations/vm1-architecture-overview.md` |

## 1. 變數合約 (Variable Contract)

執行 Phase 1 前先依目標環境解析全部 12 項變數。`DB_PASS` 一律於執行時自現有商戶設定檔（如 `protected/config/dev.php` 的 `$db_pass`）動態讀取，嚴禁以明文寫入腳本、文件或日誌。

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

**完成條件**：全部 12 項變數皆已解析且 `DB_PASS` 來自設定檔動態讀取（無明文落盤）。

## 2. 適用範圍與職責邊界 (Scope Boundaries)

- **適用環境與硬性閘門**：本流程僅用於隔離測試環境建置，嚴禁在正式環境（CPOS217、ZCPOS217）執行。於 vm1 複製正式商家庫架設隔離測試站（例 `/sb84/`）時可沿用本流程，且**必做 Phase 2.5**。
- **In-Scope（環境建置）**：獨立資料庫複製、碼基與商戶設定配置、正式庫複本外部整合隔離、Web 薄入口、Nginx 靜態資產軟連結、端到端連線與資料庫隔離性驗收。Phase 4 通過即代表環境就緒。
- **Out-of-Scope（業務部署解耦）**：特定功能的新增資料表（例如 `sales_relation`、`split_bill_*`）、專屬索引定義、功能開關（如 Gate A 的 `available = 0`）與 `yiic migrate new` / `up` 屬應用層業務部署；環境就緒後改依該功能專屬 Playbook 執行，不列為通用建置條件。

## 3. 標準作業程序 (4-Phase + Phase 2.5 SOP)

### Phase 1: 資料庫安全複製 (Database Safe Replication)

`zdpos_dev` 遺留 9 個底層表已不存在的失效 View（`inform_view`、`laundry_view`、`package_view`、`reservation_table_view`、`reservation_view`、`view_facility_queue`、`visitor_view`、`visitor_view1`、`visitor_view2`），`mysqldump` 必須顯式排除以避免 MySQL Error 1356 中斷。

1. **建立目標資料庫並授權 MCP 唯讀帳號**（Local 若無 `claude_ro` 帳號可略過 `GRANT`）：
   ```bash
   mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" -e "
     CREATE DATABASE IF NOT EXISTS \`${TARGET_DB}\` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
     GRANT SELECT, SHOW VIEW ON \`${TARGET_DB}\`.* TO 'claude_ro'@'%';
     FLUSH PRIVILEGES;
   "
   ```

2. **安全管線匯入（排除 9 個失效 View）**：
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

**完成條件**：`${TARGET_DB}` 已建立（DEV 已完成 `claude_ro` 授權）、匯入全程無 Error 1356、Base Tables 總數與 `${SOURCE_DB}` 一致（通常 > 240 張），且核心業務表（`data_action`、`sales_receipt`、`data_station`）筆數與來源庫完全相符。

### Phase 2: 獨立碼基與商戶設定配置 (Codebase & Config)

1. **切換目標分支並關閉 filemode 追蹤**（避免後續權限調整造成 Git 誤判 modified）：
   ```bash
   cd "${WEB_ROOT}/${CODEBASE_DIR}"
   git checkout "${BRANCH_NAME}"
   git config core.filemode false
   ```

2. **複製基礎環境檔案**：
   ```bash
   cp -p "${WEB_ROOT}/zdpos_develop/Glob.php" ./Glob.php
   cp -p "${WEB_ROOT}/zdpos_develop/.env" ./.env
   ```

3. **由 `dev.php` 衍生商戶設定檔** `protected/config/${MERCHANT_NAME}.php`：
   ```bash
   CONFIG_FILE="protected/config/${MERCHANT_NAME}.php"
   cp protected/config/dev.php "${CONFIG_FILE}"
   sed -i "s/\\\$use_name = 'dev';/\\\$use_name = '${MERCHANT_NAME}';/g" "${CONFIG_FILE}"
   sed -i "s/\\\$version = \"develop\";/\\\$version = \"develop-${MERCHANT_NAME}\";/g" "${CONFIG_FILE}"
   sed -i "s/\\\$destination = \"zdpos_develop\";/\\\$destination = \"${CODEBASE_DIR}\";/g" "${CONFIG_FILE}"
   sed -i "s/\\\$db_name = \"${SOURCE_DB}\";/\\\$db_name = \"${TARGET_DB}\";/g" "${CONFIG_FILE}"
   sed -i "s/'sessionName' => 'ZPOSDEV'/'sessionName' => 'ZPOS' . strtoupper('${MERCHANT_NAME}')/g" "${CONFIG_FILE}"
   ```

4. **更新 Console 設定檔** `protected/config/console.php`（確保 `yiic` 指向目標庫；vm1 保持原狀不改，見避坑原則 #6）：
   ```bash
   CONSOLE_FILE="protected/config/console.php"
   if [ -f "${CONSOLE_FILE}" ]; then
     sed -i "s/dbname=${SOURCE_DB}/dbname=${TARGET_DB}/g" "${CONSOLE_FILE}"
   fi
   ```

5. **建立並開放 Runtime 目錄**：
   ```bash
   mkdir -p protected/runtime/tracy
   chmod -R 777 protected/runtime
   ```

**完成條件**：分支位於 `${BRANCH_NAME}` 且 `core.filemode=false`；`Glob.php`、`.env`、`protected/config/${MERCHANT_NAME}.php`（含獨立 `sessionName`）皆就位；`protected/config/${MERCHANT_NAME}.php` 與 `protected/config/console.php`（非 vm1）經 `php -l` 零語法錯誤；`protected/runtime/tracy` 可寫；`git status -s` 無非預期異動。

### Phase 2.5: 正式庫複本隔離（來源為正式商家庫時必做，開放登入前完成）

正式庫複本含真實統編、字軌與正式 API 設定，且 `EI::XMLCreate()` 直接寫入 `\GLOB\INVOICE_BASE_PATH`、**沒有環境閘門**。開放登入前先讀並逐項完成 [references/prod-clone-isolation.md](./references/prod-clone-isolation.md) 的全部 8 項隔離規格：
- 獨立碼基改寫 `Glob.php` 的 `INVOICE_BASE_PATH` 到隔離目錄（共用碼基無法隔離，嚴禁開立／作廢／折讓發票並列入禁止清單）；
- 目標庫 `invoice_maintain` 當期 `used=1` 改為 `OO` 測試字軌與新號段、`*_develop` 旗標設 `1`、程式無法隔離項目（藝FUN 券、`external_order`、`zdn_api_url`、SMTP／簡訊／webhook）列入測試禁止清單；
- 建立獨立受限 DB 帳號（含 `MAX_USER_CONNECTIONS`，禁止共用 superuser）、新靜態目錄加入 nginx `.php` 403 deny（443／80）、DB 探針腳本一律 `try/catch` 不洩露帳密／DSN，並遵循 vm1 命名 `zdpos_218_<站>` 與 `invoices-<站>`（保留 `zdpos_217_*` 給正式商家）。

**完成條件（Completion Gate）**：於 vm1 執行 `check-site-isolation.php` 輸出 `ISOLATION_OK`（exit 0），所有 WARN 項已轉為測試禁止清單；開立第一張測試發票後確認 XML 僅出現在隔離目錄。

### Phase 3: Web 薄入口與 Nginx 靜態資源配置 (Web Entry & Symlinks)

依目標 PHP runtime 至 [references/prod-clone-isolation.md](./references/prod-clone-isolation.md) 取得完整模板與指令並執行：
1. **建立薄入口**：PHP 5.6 用標準 `index.php` 模板並建 `{assets,log,upload,images,download}`；DEV 8.4 改用 `dev-php84-site-deployment.md` 附錄 A（`yii_framework-fork` + `config/runtime-bootstrap.php`）並加 nginx map（§12）；vm1 8.4 由來源商家 5.6 `index.php` 僅換 `$name`/`$yii`/`$config`、config 僅換 `$use_name`/`$version` 且維持 `sessionName`（碼基須含 `bootPhp84LegacyEntry`）。
2. **建立 Nginx 軟連結**（5.6／8.4 相同）：連結 `${PUBLIC_ROOT}/${MERCHANT_NAME}` 指向薄入口；於 `${PUBLIC_ROOT}/${CODEBASE_DIR}/` 僅連結 `assets`、`ckeditor`、`css`、`images`、`js`、`media` 6 個靜態資源目錄以隔離後端程式碼。

**完成條件**：薄入口目錄與入口腳本就位、`${PUBLIC_ROOT}/${MERCHANT_NAME}` 正確指向薄入口，且 `${PUBLIC_ROOT}/${CODEBASE_DIR}/` 下 6 個靜態目錄軟連結皆有效解析。

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

**完成條件**：入口頁面與核心 CSS／JS 靜態資源 HTTP 回應碼皆為 `200`（零 404），且頁首連線資料庫明確顯示 `資料庫:${TARGET_DB}`。

## 4. 實戰避坑原則 (Traps)

1. **Nginx 404**：DEV 的 Document Root 在 `${PUBLIC_ROOT}`，務必建立 `${PUBLIC_ROOT}/${MERCHANT_NAME}` 指向薄入口的軟連結。
2. **靜態資源 404 與 JS 崩潰**：務必建立 `${PUBLIC_ROOT}/${CODEBASE_DIR}/` 的 6 個靜態目錄軟連結，避免 `login.css` 與 `keyboard.js` 404 引發 `$(...).keyboard is not a function`。
3. **Git 工作區大量 modified 檔案**：`chmod` 會異動 filemode，先設定 `git config core.filemode false` 維持工作區乾淨。
4. **Session 互相覆蓋**：商戶設定檔指定獨立 `sessionName`（如 `ZPOS${MERCHANT_NAME}`），防止與主開發站共用 Session（vm1 PHP 8.4 例外見 Phase 3）。
5. **瀏覽器外掛干擾報錯**：Console 出現 `content_main.js` 報錯通常為 Chrome 擴充套件（如翻譯工具）所致，改以無痕視窗驗證。
6. **vm1 的 migration 走 pms-yii**：vm1 各碼基的 `protected/config/console.php` 為失效舊檔（連線資訊過期、`demo_retail`），保持原狀不修改；migration 由 pms 呼叫 pms-yii，檔案放於 pms-yii 的 `protected/migrations/<資料夾>`（特定商家放專用資料夾，見 vm1 架構總覽 §8）。
7. **唯讀 MCP 無法執行 DDL**：`claude_ro` 僅具唯讀權限，建庫與 Dump／Restore 一律以具管理權限帳號於伺服器內網執行，完成後再授權 `claude_ro`。
