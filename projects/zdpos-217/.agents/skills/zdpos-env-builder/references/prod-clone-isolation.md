# 正式庫複本隔離 (Phase 2.5) 與 PHP Runtime 薄入口模板 (Phase 3)

本檔包含 `zdpos-env-builder` 的兩段完整作業細節：
1. **Phase 2.5 正式庫複本隔離**：當來源為正式商家庫（例如 vm1 上架設 `/sb84/` 隔離測試站）時必做，須於開放登入前全部完成。
2. **Phase 3 Web 薄入口與 Nginx 軟連結**：涵蓋 PHP 5.6 與 PHP 8.4（DEV vs vm1）分支模板與靜態資源 symlink 佈局。

---

## Phase 2.5: 正式庫複本隔離（來源是正式商家庫時必做，開放登入前完成）

正式庫複本帶著真實統編、真實字軌與正式 API 設定。`_develop` 旗標只切換部分 API 端點；開票、作廢、折讓的 XML 由 `EI::XMLCreate()` 直接寫到 `\GLOB\INVOICE_BASE_PATH`，**沒有環境閘門**，而 vm1 各碼基預設指向正式上傳佇列 `/var/glob-storage/invoices/`。

1. **發票輸出隔離**：碼基 `Glob.php` 的 `INVOICE_BASE_PATH` 改到隔離目錄（例 `/var/glob-storage/invoices-<站>/`），先建 `temp/{blank,invalid,invoice,allocate}` 與 `bak/{blank,invalid,invoice,allocate}`；備份後單行 sed，`php -l`。**共用碼基的租戶站做不到**：`INVOICE_BASE_PATH` 是該碼基 `Glob.php` 的常數，租戶 config 無法覆寫；與正式或其他站共用碼基（例 `/sb56/` 與 `/demo218/` 共用 `zdpos_218`）時，`check-site-isolation.php` 必為 `ISOLATION_FAIL`，該站**禁止開立、作廢、折讓發票**，並列入測試禁止清單；要開票只能另建碼基與獨立 `Glob.php`。
2. **字軌改 `OO`**：目標庫 `invoice_maintain` 當期 `used=1` 的每一列，以「帶原值條件的 UPDATE」改為 `OO` 測試字軌並設新號段（先確認號段在 `invoice_record` 無資料、原列備份）。
3. **`_develop` 旗標**：`eiic`／`linepay`／`jkospay`／`pipay`／`taiwanpay`／`liff`／`api` 的 `*_develop` 設 1。
4. **程式無法隔離者，列入測試禁止清單**：藝FUN 券（`EFunPayApi::IS_DEVELOP` 寫死 `false`）、`external_order` 模組（外送平台）、`zdn_api_url`、SMTP／簡訊／webhook。
5. **獨立受限 DB 帳號**：建立只授權該測試庫、帶 `MAX_USER_CONNECTIONS` 的專用 DB 帳號，測試站碼基的 `dbConnectParams.php` 改用它；測試站不得與正式站共用 superuser 帳號。`check-site-isolation.php` 會 FAIL 共用 superuser 帳號。帳號名稱與密碼不寫入文件或對話。共用碼基的租戶站不改 `dbConnectParams.php`（會影響同碼基其他站），而是在租戶 config 讀入 `dbConnectParams` 後覆寫 `$db_name` 與受限帳號；因此**該 config 同樣含受限帳密，不得貼進對話或文件**。
6. **靜態目錄 deny**：新增任何靜態目錄（例 `zdpos_218_sb84`）時，把它加入該站 nginx `.php` deny regex（`BEGIN <站>-uat` 區塊，443／80 兩份），reload 後以該目錄下 `.php` 回 403 驗證。
7. **連 DB 的探針腳本一律 try/catch**：PDO 連線失敗的未攔截例外堆疊會把連線帳密印到輸出（2026-11-24 曾外洩進 session transcript）；腳本捕捉例外後只印「連線失敗」與錯誤代碼，不印堆疊與 DSN。
8. **vm1 命名**：vm1 新測試站碼基一律 `zdpos_218_<站>`，發票隔離目錄一律 `invoices-<站>`（`zdpos_217_*` 保留給正式商家碼基；例：186 prod canary 專用 `zdpos_217_sb84`，UAT `/sb84/` 為 `zdpos_218_sb84`）。

完整步驟：`/home/paul/projects/zdpos-217-docs/docs/operations/playbooks/release-26.11.8-php84-canary.md` §4.2、§4.4、§4.5。vm1 網域、碼基、PHP pool、migration（走 pms-yii）與發票佇列見 `/home/paul/projects/zdpos-217-docs/docs/operations/vm1-architecture-overview.md`。

### Phase 2.5 完成條件（Completion Gate）

在 vm1 執行（先 `scp` 到 vm1）：

```bash
php8.4 /home/paul/projects/zdpos-217-docs/scripts/ops/check-site-isolation.php --codebase=<碼基> --config=<碼基內 config 相對路徑>
```

- 輸出 `ISOLATION_OK`、結束碼 0。
- 所有 WARN 項已轉成給測試者的禁止清單。
- 開第一張發票後，再確認 XML 只出現在隔離目錄。

---

## Phase 3: Web 薄入口與 Nginx 靜態資源配置 (Web Entry & Symlinks)

Yii 架構將網頁入口與程式碼主體分離（Thin-entry）。

### 先判斷站台跑哪個 PHP runtime

- **PHP 5.6**（現行預設）：照下方步驟 1 的模板建立。
- **DEV PHP 8.4**：碼基須為含 8.4 修正的分支。薄入口與 console 入口改用 `/home/paul/projects/zdpos-217-docs/docs/operations/playbooks/dev-php84-site-deployment.md` 附錄 A 的標準模板，該模板使用 `yii_framework-fork` 與 `config/runtime-bootstrap.php`，是 DEV 8.4 模板的出處。另在 nginx map 加一行，見該文件 §12。
- **vm1 PHP 8.4**：不用 DEV 8.4 模板；由來源商家的 5.6 `index.php` 只換 `$name`、`$yii`、`$config`，config 只換 `$use_name`、`$version`，`sessionName` 不改，見 `/home/paul/projects/zdpos-217-docs/docs/operations/playbooks/release-26.11.8-php84-canary.md` §4.2、§4.8（碼基須含 `bootPhp84LegacyEntry`）。

步驟 2、3 的 symlink 佈局兩種 runtime 相同。

### 1. 建立薄入口目錄與入口腳本（PHP 5.6 預設模板）

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

### 2. 建立 Nginx Document Root 軟連結

```bash
ln -sf "${WEB_ROOT}/${MERCHANT_NAME}" "${PUBLIC_ROOT}/${MERCHANT_NAME}"
```

### 3. 建立 Nginx 靜態資源對外軟連結

避免後端程式碼暴露，於 `${PUBLIC_ROOT}/${CODEBASE_DIR}/` 僅連結靜態資源目錄：

```bash
PUBLIC_DIR="${PUBLIC_ROOT}/${CODEBASE_DIR}"
CODE_DIR="${WEB_ROOT}/${CODEBASE_DIR}"
mkdir -p "${PUBLIC_DIR}"
for d in assets ckeditor css images js media; do
  ln -sf "${CODE_DIR}/${d}" "${PUBLIC_DIR}/${d}"
done
```

### 4. Phase 3 完成條件（Completion Criterion）

- `${PUBLIC_ROOT}/${MERCHANT_NAME}` 軟連結正確指向薄入口。
- `${PUBLIC_ROOT}/${CODEBASE_DIR}` 包含 `assets`、`ckeditor`、`css`、`images`、`js`、`media` 6 個靜態目錄軟連結。
