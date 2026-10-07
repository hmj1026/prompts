# CODING_STANDARDS.md

| 欄位 | 值 |
| --- | --- |
| `owner` | `architecture-owner` |
| `status` | `current` |
| `last-verified` | `2026-09-24` |
| `canonical-source` | 本文件（專案全體程式碼風格唯一真理來源） |

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
*   *自動化檢驗*：由 `.php-cs-fixer.php` 與 `phpcs.xml` 自動檢查。

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

*   **`Str`**：`contains`, `startsWith`, `endsWith`, `length`, `lower`, `upper`, `limit`
*   **`Arr`**：`get`, `has`, `set`, `only`, `except`, `wrap`, `first`, `last`, `flatten`
*   **`Date`**：`startOfDay`, `endOfDay`, `normalizeYmd`

若輔助類缺少所需運算，應**擴充該輔助類**，嚴禁在業務邏輯內以字串手動拼裝日期或邊界值：
*   ✅ `Date::startOfDay($date)`（禁止 `$date . ' 00:00:00'`）
*   ✅ `Date::endOfDay($date)`（禁止 `$date . ' 23:59:59'`）

---

## 6. Magic Values & Constants（魔術值與常數化）

PHP 5.6 無原生 `enum` 關鍵字。所有枚舉皆由類別常數或抽象枚舉實現。**嚴禁在業務判斷或 View 渲染中出現裸數字 `0` / `'0'` / `1`**：

1. **`AbstractEnum` 子類**（`infrastructure/Foundation/Structures/AbstractEnum.php`）：
   * 適用於多處共用、具備名稱描述或下拉選單之狀態。
   * 子類位於 `domain/{Module}/Enums/` 或 `domain/Models/`。
   * 必須宣告 `const DESCRIPTIONS = [...]`，否則 `getDescription()` 將拋出異常。
2. **Repository 類別常數**：
   * 適用於單一 Repository 內部之標記。
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
