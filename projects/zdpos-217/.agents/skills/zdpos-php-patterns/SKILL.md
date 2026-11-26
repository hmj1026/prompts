---
name: zdpos-php-patterns
description: PHP 實作模式（catch 例外記錄、IN／NOT IN 安全查詢）。Use when 撰寫 try/catch 或決定 side-effect／主流程失敗策略，或撰寫多 ID IN／NOT IN 查詢與 LIKE+IN 複合條件。Not for 一般 WHERE =／LIKE 查詢。
allowed-tools: Read, Grep, Glob
---

# zdpos PHP 實作模式

依觸發情境套用對應段落的全部規則；每段皆附可檢核完成條件。

## 1. Exception Logging（catch 例外記錄）

### 強制規則（雙寫）

每個 `catch (\Exception $e)` 必須同時呼叫以下兩者：

1. **`\application\helpers\ExceptionLogHelper::logCaughtExceptionToApplication($e, $context)`**：寫入 `application.log`（含 stack trace）、category 自動為 `exception.<class>.<httpStatus?>.caught`、對 `CDbException` 自動去重 SQL、自動補 `REQUEST_URI`／`HTTP_REFERER`。
2. **Domain logger**（如 `SalesWeatherLogger::error('<channel>', $method, $msg, $ctx)`）：供 ops grep。

> `catch (\Throwable $e)` 在 PHP 5.6 語法合法但永不命中；PHP 8.4 下同樣交給 `ExceptionLogHelper::logCaughtExceptionToApplication($e)`（已接受 `\Throwable`）。

### 失敗位置策略

| 失敗類型 | 處置策略 |
| :--- | :--- |
| **Side-effect 失敗**（context insert／metrics 等次要寫入） | 雙寫 log ＋ safe degrade（設 `status='error'`，吞掉不再 re-throw） |
| **Main-flow error**（主流程失敗） | 雙寫 log ＋ re-throw，或設 `status='error'` 由上游 escalate |

### 標準寫法與必避反模式

```php
try {
    // ...
} catch (\Exception $e) {
    \application\helpers\ExceptionLogHelper::logCaughtExceptionToApplication($e, $context);
    SalesWeatherLogger::error('<channel>', __METHOD__, $e->getMessage(), $context);
    // Side-effect 失敗：safe degrade（如回傳 status='error'）；Main-flow error：re-throw 或由上游 escalate
}
```

全數改採上述雙寫，杜絕下列四種反模式：
- empty catch（`catch (\Exception $e) { }`）或註解忽略（`catch (\Exception $e) { /* ignore */ }`）
- 只寫 `EILogger::error(...)` 而漏掉 `ExceptionLogHelper::logCaughtExceptionToApplication`
- 直接呼叫 `\Yii::log($e->getMessage(), \CLogger::LEVEL_ERROR, 'application')` 記錄例外（含 PHP 7+／8.4 的 `Error`）

### 參考實作

- 最完整範例：`protected/controllers/PosController.php`
- Domain logger 樣板：`SalesWeatherLogger`（`domain/SalesWeather/Support/SalesWeatherLogger.php`）
- Helper：`application\helpers\ExceptionLogHelper`

- **完成條件**：每個新增或修改的 `catch` 區塊皆雙寫 `ExceptionLogHelper::logCaughtExceptionToApplication` 與 Domain logger、依失敗位置落實 safe degrade 或 re-throw，且零反模式殘留。

## 2. IN / NOT IN 安全查詢

### 層級選用與三條硬規則

- **新寫 Repository／查詢層**：優先用 `Infrastructure\Database\Query\Builder` 的 `whereIn()`／`whereNotIn()`（詳見下方相關參考）。
- **既有 legacy code、AR `findAll($criteria)` 或併入既有 `CDbCriteria` 條件鏈**：用 `CDbCriteria` 的 `addInCondition()`／`addNotInCondition()`。
- 兩者底層皆走 PDO bind，安全性等價；依所在層風格選用。

所有多值查詢遵守三條硬規則：
1. 統一走 `whereIn()`／`whereNotIn()`（Query Builder）或 `addInCondition()`／`addNotInCondition()`（`CDbCriteria`）。
2. 傳入前包 `array_values($ids)`，防止非連續 key 造成參數綁定錯位。
3. `addNotInCondition` 前先 guard 空陣列（`!empty($excludeIds)`）；空陣列不加條件（等於不過濾），避免 `addNotInCondition('col', [])` 生成無效 SQL。

### 標準寫法

```php
// IN
$c = new CDbCriteria();
$c->addInCondition('item_no', array_values($itemNos));

// NOT IN（含空陣列 guard）
$c = new CDbCriteria();
if (!empty($excludeIds)) {
    $c->addNotInCondition('id', array_values($excludeIds));
}
// $excludeIds 為空時不加條件 → 等於不過濾
```

### 複合條件（LIKE + IN）

將 `$c->condition` 併入既有 `$where`，`$c->params` 以 `array_merge` 併入既有 `$params`：

```php
$c = new CDbCriteria();
$c->addInCondition('item_class', array_values($classes));

// 既有 $where / $params 來自 LIKE 段
$where .= ' AND ' . $c->condition;
$params = array_merge($params, $c->params);

$rows = Yii::app()->db->createCommand()
    ->where($where, $params)
    ->queryAll();
```

### 必避反模式

全數改用上述標準寫法，杜絕下列三種寫法：
- 字串內插（`$str = implode("','", $ids); "SELECT * FROM t WHERE col IN ('$str')"`）
- 未經 `array_values()` 直接傳非連續 key 陣列（如 `[1 => 'a', 3 => 'b']` 造成參數綁定錯位）
- 未 guard 空陣列直接呼叫 `$c->addNotInCondition('id', $excludeIds)`（`$excludeIds = []` 生成無效 SQL）

- **完成條件**：每個新增或修改的 IN／NOT IN 查詢皆走 PDO bind（Builder 或 `CDbCriteria`）、傳入值經 `array_values()` 正規化、`NOT IN` 具備空陣列 guard，且 LIKE+IN 複合條件正確合併 `$where` 與 `$params`。

## 相關參考

- Always-loaded floor：`.claude/rules/php/patterns.md`
- EILogger 用法：`.claude/docs/eilogger.md`
- Repository／Query Builder：`infrastructure/AGENTS.md`（Database Query Toolkit 段）、`docs/guides/query-toolkit-cookbook.md`
