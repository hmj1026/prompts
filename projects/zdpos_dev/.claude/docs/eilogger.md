# EILogger 使用要點

## 架構

| 元件 | 檔案 | 角色 |
|------|------|------|
| `EILogger` | `protected/components/EILogger.php` | 靜態代理（Singleton Facade） |
| `EI` | `protected/models/EI.php` | 實際實作（含發票、log 等功能） |

`EILogger::method()` → `__callstatic()` → `EI` singleton instance → 實際方法

## 方法簽名

### `slog($msg, $file_title, $folder = "")` — 結構化 log（優先使用）

| 參數 | 型別 | 說明 |
|------|------|------|
| `$msg` | `string\|array` | log 內容，array 會經 `print_r()` 展開 |
| `$file_title` | `string` | 檔案標題，產生 `{title}_{Ymd}.xml` |
| `$folder` | `string` | 子資料夾名稱（選填，預設空 = 根目錄） |

**輸出路徑**：`/var/www/zdnStorage/logs/{YYYY-MM}/{HTTP_HOST}/{DB_NAME}/{folder}/{file_title}_{Ymd}.xml`

### `log($msg, $develop = false, $otherLog = false)` — 通用 debug log

| 參數 | 型別 | 說明 |
|------|------|------|
| `$msg` | `string\|array` | log 內容 |
| `$develop` | `bool` | true → `SaveReceiptLog_{Ymd}.xml` |
| `$otherLog` | `bool` | true → `PrintLog_{Ymd}.xml` |

**輸出路徑**：`.../{DB_NAME}/debug/log{Ymd}.xml`（預設）

### `startMarkTime()` / `stepTimeLog($step)` — 效能計時

計算步驟間毫秒耗時，用於效能分析。

## 呼叫方式選擇

| 場景 | 建議 | 範例 |
|------|------|------|
| Service / Domain 層 | `EILogger::slog()` 靜態呼叫 | `EILogger::slog($data, 'CouponMismatch')` |
| Controller 已有 `$EI` 變數 | `$EI->slog()` 實例呼叫 | `$EI->slog($data, 'SplitAcc', 'SplitAcc')` |
| 快速 debug（開發中） | `EILogger::log()` | `EILogger::log(['method' => __METHOD__, 'data' => $var])` |
| **禁止** | `Yii::log()` 在業務邏輯中 | — |

## 常見使用模式

### 1. API 整合 log（含 method + message 結構）
```php
EILogger::slog([
    'method'  => __FUNCTION__,
    'message' => '操作描述',
    'request' => $request->getAttributes(),
], $this->getFileTitle(), $this->getLogFolder());
```

### 2. 錯誤/例外 log
```php
EILogger::slog([
    'class'   => __CLASS__,
    'method'  => __FUNCTION__,
    'message' => '錯誤描述',
    'error'   => $exception->getMessage(),
    'code'    => $exception->getCode(),
], $fileTitle, $logFolder);
```

### 3. 簡單字串 log
```php
EILogger::slog(
    'Coupon mismatch - receipt_no: ' . $salno,
    'CouponMismatch'
);
```

### 4. 付款/退款流程 log（使用實例）
```php
$EI->slog('-----START-----', 'CreditOnlineRefund', 'CreditOnline');
$EI->slog($payData, 'CreditOnlineRefund', $logDir);
```

## 黑名單機制

`slog()` 內建黑名單過濾（`getBlackListTitle()` / `getBlackListFolder()`），匹配的 title 或 folder 會直接 return 不寫檔。

## file_title 命名慣例

| 用途 | file_title 範例 | folder 範例 |
|------|----------------|-------------|
| 結帳相關 | `'Credit'` | `'Credit'` |
| 拆帳 | `'splitAcc'` | `'splitAcc'` |
| 折價券異常 | `'CouponMismatch'` | （空） |
| 點數服務 | `'PointService'` | `'PointService'` |
| 線上退款 | `'CreditOnlineRefund'` | `'NcccCreditOnline'` |
| Insert 錯誤 | `'InsertError'` | （空） |
| 第三方核銷 | Service class name | Service folder |
