# CODING_STANDARDS.md

| 欄位 | 值 |
| --- | --- |
| `owner` | `architecture-owner` |
| `status` | `current` |
| `last-verified` | `2026-10-07` |
| `canonical-source` | 本文件（專案全體程式碼風格唯一真理來源） |

> 本文件為版控正本，相對連結以專案根目錄為基準；只引用版控內實際存在的檔案。

本文件定義專案全體開發者與 AI Agent 在 PHP 5.6 + Yii 1.1 + DDD 架構下的程式碼編寫標準與風格規範。

---

## 1. Scope Rule（修改範圍與震盪界定）

下列**風格與重構類規則**一律套用此範圍定義；**PHP 5.6 語言硬限制無豁免，恆久適用**：

*   **IN scope（MUST）**：本次新增的方法、類別、檔案，以及 Git diff 內修改或新命名的程式碼。
*   **OUT scope（不主動修改）**：本次未觸碰的既有代碼——嚴禁以「順手改進」為由擴張 blast radius。
*   **「實質改寫」例外**：當重構整個方法主體或整檔重寫時，連帶清理該範圍內的所有風格違規（僅改動數行不算實質改寫）。

---

## 2. PHP 5.6 Baseline & Polyfills（語言硬限制）

生產環境為 **PHP 5.6.40**。嚴禁使用任何 PHP 7.0+ 現代語法（禁止類型提示、標量返回類型、`??` 空值合併運算子、`?->` 安全調用、`match`、箭頭函數 `fn()`、命名參數、多重 catch、短 list 解構、匿名類別）。

### 常用函數 Polyfills 替代清單

| 禁止使用（PHP 7+） | 正確替代方案（PHP 5.6） |
| :--- | :--- |
| `random_bytes()` / `random_int()` | `openssl_random_pseudo_bytes()` |
| `intdiv($a, $b)` | `(int)($a / $b)` |
| `dirname(__FILE__, N)` | 多層巢狀 `dirname(dirname(...))` |
| `str_contains()` / `str_starts_with()` | `strpos() !== false` / `substr()` 或使用 `Str` 輔助類 |
| `array_column($a, null, $key)` | 傳入明確的 value key，或以 `foreach` 重建索引 |
| `preg_replace_callback_array()` | 依序使用 `preg_replace_callback()` |

---

## 3. Array Syntax（陣列語法）

全面採用 PHP 5.4+ 短陣列語法，**禁止 `array()`**：

*   常規宣告：`['a', 'b']`（禁止 `array('a', 'b')`）
*   方法參數預設值：`function doSomething($opts = [])`
*   合併運算：`array_merge([], $data)`
*   *自動化檢驗*：由 [`.php-cs-fixer.php`](.php-cs-fixer.php) 與 [`phpcs.xml`](phpcs.xml) 自動檢查。

---

## 4. Framework & Persistence Access（框架與持久層存取）

### 4.1 請求參數取值（Request Access）
*   **單一參數**：使用 `Yii::app()->request->getPost($key)` 或 `$this->Request->getPost($key)`（嚴禁裸讀 `$_POST[$key]` / `$_GET[$key]`）。
*   **整批 POST 陣列（Controller 層唯一例外）**：Controller 在確認 `$this->Request->getPost($key)` 存在後，才允許存取 `$_POST`。
*   **Domain 與 Infrastructure 層**：**絕對禁止讀取超全域變數 `$_POST` / `$_GET`**。Request 物件必須在構造時接收已正規化的資料陣列。

### 4.2 ActiveRecord 與查詢規則
*   **ActiveRecord 宣告**：每個繼承 `CActiveRecord` 的模型必須包含：
    ```php
    public static function model($className = __CLASS__)
    {
        return parent::model($className);
    }
    ```
*   **查詢未命中處理**：`CDbCommand::queryRow()` 在查無資料時回傳 `false`（非 `null`），必須以 `if ($result === false)` 或 `if (!$result)` 判斷。

---

## 5. Infrastructure Helper Priority（基礎設施輔助類優先）

在進行任何字串、陣列或日期操作前，**必須優先查閱並使用** `infrastructure/Support/` 的輔助方法：

*   **[`Str`](infrastructure/Support/Str.php)**：`contains`, `startsWith`, `endsWith`, `length`, `lower`, `upper`, `limit`
*   **[`Arr`](infrastructure/Support/Arr.php)**：`get`, `has`, `set`, `only`, `except`, `wrap`, `first`, `last`, `flatten`
*   **[`Date`](infrastructure/Support/Date.php)**：`startOfDay`, `endOfDay`, `normalizeYmd`

若輔助類缺少所需運算，應**擴充該輔助類**，嚴禁在業務邏輯內以字串手動拼裝日期或邊界值：
*   ✅ `Date::startOfDay($date)`（禁止 `$date . ' 00:00:00'`）
*   ✅ `Date::endOfDay($date)`（禁止 `$date . ' 23:59:59'`）

---

## 6. Magic Values & Constants（魔術值與常數化）

PHP 5.6 無原生 `enum` 關鍵字。所有枚舉皆由類別常數或抽象枚舉實現。**嚴禁在業務判斷或 View 渲染中出現裸數字 `0` / `'0'` / `1`**：

1. **[`AbstractEnum`](infrastructure/Foundation/Structures/AbstractEnum.php) 子類**：
   * 適用於多處共用、具備名稱描述或下拉選單之狀態。
   * 子類位於 `domain/{Module}/Enums/` 或 `domain/Models/`。
   * 必須宣告 `const DESCRIPTIONS = [...]`，否則 `getDescription()` 將拋出異常。
2. **類別常數**：
   * 適用於單一類別（Repository、Controller、Policy 等）內部之標記。
   * 命名格式：`FIELD_SEMANTIC`（如 `PACKAGE_STATE_PENDING`）。
3. **字串常數與權限標記**：
   * 權限字串（如 `MenuAccessPolicy::INDIVIDUAL_MARKER`）與 sentinel 標記收斂至類別常數，避免分散各處裸寫字串。

---

## 7. Method Name Length（方法名稱長度限制）

*   **長度上限**：一般生產程式碼之方法名稱不得超過 **32 字元**（避免 IDE 提示警告）。
*   **縮寫與命名策略**：刪除冗餘的 `ForXxx` 後綴、縮寫 `Constructor` $\to$ `Ctor`、省略類別已載明的模組名詞。
*   **測試方法豁免**：PHPUnit 測試方法（`testXxx`）遵循 `test[Subject]_[Condition]_[ExpectedOutcome]` 慣例，允許超過 32 字元。

---

## 8. Variable Naming Conventions（變數命名規範）

| 類型 | 命名規則 | 實例 |
| :--- | :--- | :--- |
| **Array / Collection** | `snake_case`（複數） | `$order_items`, `$pay_actions` |
| **Object** | `PascalCase` | `$PayAction`, `$OrderRepo` |
| **Scalar** | `camelCase` | `$storeId`, `$totalAmount` |

---

## 9. Control Flow & Method Placement（流程結構與方法放置）

*   **Early return**：前置條件與錯誤情況放在方法開頭，檢查後立即 `return` 或 `throw`，主流程維持在最外層縮排。一個條件一個 guard，不合併成複合判斷。
*   **方法放置**：新增方法預設加在檔案最下端；同領域的方法群可放在相關既有方法旁，以維持內聚。
*   **類別成員順序**：常數與屬性放在類別頂端，不夾在方法之間。

---

## 10. AJAX／API 回應契約（依呼叫端選格式）

回應格式由**消費端**決定，同一類呼叫端只用一種格式；不得自創新格式，也不得把既有端點改成另一種格式。

| 呼叫端 | 格式 | 建構方式 |
| :--- | :--- | :--- |
| **POS 前台**（`POS.list.ajaxPromise` / `ajaxQuery`、`POS.post` / `postData` 呼叫的端點） | `{err, date, result, msg, data}`，`err` 為 `0` 表示成功 | `PosController::response()`；非 PosController 的端點（如基底 Controller 的閘門）須輸出相同鍵 |
| **後台頁面 AJAX**（`js/admin/**` 等，非 ZTable 內建 callback） | `{success, data, message}` | 新程式以 `Infrastructure\Http\Respond\ApiResponse::success()` / `fail()` 組裝，經 `Respondable::respond()` 輸出；既有 `markResult()` 可沿用 |
| **ZTable 內建 callback**（insert / update / delete） | ZTable 元件合約：成功回純文字 `success` | 錯誤以 `ZTableErrorResponse::end()` 或純文字訊息結束 |
| **api module**（`protected/modules/api/**`） | module 自身合約 | module trait 的 `json()` / `error($text, $status)` |
| **整頁請求**（非 AJAX） | HTTP 錯誤頁 | `throw new CHttpException(403 / 404, $message)` |

*   POS 前台以 `data.err !== 0` 判斷失敗，`err` 格式**不是**棄用格式。
*   `success` 格式的錯誤碼放 `ApiResponse::fail($message, $data, $code)` 的 `code` 鍵。

---

## 11. Domain Boundary（Domain 層邊界）

*   Domain 層不得直接依賴 Yii／`CDb*`、Infrastructure repository 或 exception、application helper、logger、全域執行環境或 shutdown hook；需要時經 Domain 內的 Port，由 Infrastructure 的 Adapter 實作。
*   duplicate-key、lock-timeout 等框架例外由 Repository／Adapter 轉成 Domain 可理解的 typed outcome 或 exception；Domain 不得以 `CDbException::errorInfo` 判斷資料庫語意。
*   抽出 Port／Adapter 時，舊 implementation 的引用須清零、Port 位於 Domain、Adapter 位於 Infrastructure、Factory wiring 正確，且原 Domain consumer 不再自帶同類框架副作用，抽出才算完成。
*   稽核與錯誤 log 在 application／Infrastructure 邊界寫入；Domain 需要表達稽核事件時，回傳 outcome 或經 typed Port。
*   Domain 決策類（Policy）一律放 `domain/Policies/`（namespace `Domain\Policies`，不依模組切子目錄）：
    *   instance-based，不寫 static。
    *   對齊 Laravel Rule 物件：決策 `passes($subject, array $context = [])` 回傳 bool，true = 放行；不放行的訊息由 `message()` 提供（於 `passes()` 之後呼叫，訊息所需的標的值由 `passes()` 記住）。
    *   同一次請求內固定不變的設定與環境值（使用者層級、店號、資料庫名稱等）放 constructor，決策方法只吃被判定的標的。

---

## 12. Comments & Provenance Anchor（註解與變更錨點）

*   新增或修改的程式註解使用正體中文；技術識別字、型別與既有 API 名稱維持英文。
*   變更錨點格式：`YYYY/MM/DD 作者 [版本] 功能描述`。
    *   新物件：物件 docblock 只放一個錨點，方法內不重複。
    *   既有物件的新方法：方法 docblock 放一個錨點（功能描述之後、`@param` 之前）。
    *   既有方法的修改：第一個修改段落開頭放一個錨點，同方法不重複。

---

## 13. Test Independence（測試獨立性）

*   斷言必須比較彼此獨立的來源；只把 fixture 欄位與自身比較的測試即使通過也應拒收。
*   宣稱防止某回歸的測試，必須實測在該回歸下會變紅。
*   測試語法以目前安裝的 PHPUnit 版本（`vendor/phpunit`，5.7.27）支援的 API 為準：例外斷言新寫優先 `expectException()`（搭配 `expectExceptionMessage()`）；`setExpectedException()` 自 5.2 起標為 `@deprecated` 但仍可用；`@expectedException` annotation 亦可用。

---

## 14. Naming Alignment（命名對齊 Laravel）

新命名先找 Laravel 的對應概念並沿用其名稱，日後抽介面或遷移時可直接銜接；Laravel 沒有對應時，才依本專案既有慣例命名。

| 概念 | Laravel 對應 | 本專案命名 |
| :--- | :--- | :--- |
| 決策類（Policy） | Rule 物件 `passes()` / `message()` | `passes($subject, array $context = [])`、`message()` |
| 請求前的閘門 | middleware `EnsureXxx::handle()` | 基底 Controller 方法 `ensureXxx($action)`，如 `ensureStoreIsResolved()` |
| 是否已登入 | `Auth::check()` | `authCheck()` |
| 是否應回 JSON | `$request->expectsJson()` | `expectsJson()` |
| 取值方法 | 不加 `get` 前綴（如 `$request->user()`） | 名詞式，如 `currentStoreNo()`、`orphanNotice()` |
| 驗證並回傳違規訊息 | Validator（`validate()`） | `validateXxx()`，通過回 `null`、違規回訊息字串 |
| 解析外部格式（非建構實例） | 無 | `parseXxx()`；`fromXxx()` 保留給回傳本類別實例的工廠方法 |

*   同性質的兩個以上類別（如 `EmployeeRepository` 與 `StationRepository`），相同業務動作用相同方法名與參數順序，以便抽出共同介面。
*   參數與命名順序一致：成對方法（如 `xxxViolationFromPost`）命名結構對稱。

