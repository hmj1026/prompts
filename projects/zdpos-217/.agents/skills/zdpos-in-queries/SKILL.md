---
name: zdpos-in-queries
description: IN / NOT IN：query builder 用 whereIn / whereNotIn，CDbCriteria 用 addInCondition / addNotInCondition，傳入前 array_values，空陣列先 guard。Use when 寫多 ID 查詢或合併 LIKE+IN。一般 WHERE = / LIKE 不需要。
allowed-tools: Read, Grep, Glob
---

# IN / NOT IN Queries（安全寫法）

## Hard Rules

1. query builder 用 `whereIn()` / `whereNotIn()`；`CDbCriteria` 用 `addInCondition()` / `addNotInCondition()`。
2. 傳入前 `array_values($ids)` — 防止非連續 key 造成參數綁定錯位。
3. `addNotInCondition` 先 guard 空陣列：`addNotInCondition('col', [])` 會生成無效 SQL。

## 標準寫法

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

## 複合條件（LIKE + IN）

需要把 `$c->condition` 併入既有 `$where`、把 `$c->params` 用 `array_merge` 併入既有 `$params`：

```php
$c = new CDbCriteria();
$c->addInCondition('item_class', array_values($classes));

// 既有 $where / $params 來自 LIKE 段
$where  .= ' AND ' . $c->condition;
$params  = array_merge($params, $c->params);

$rows = Yii::app()->db->createCommand()
    ->where($where, $params)
    ->queryAll();
```

## 反模式（禁止）

```php
// 禁止 1：字串內插
$str = implode("','", $ids);
$sql = "SELECT * FROM t WHERE col IN ('$str')";

// 禁止 2：未 array_values 直接傳
$ids = [1 => 'a', 3 => 'b'];          // 非連續 key
$c->addInCondition('col', $ids);     // 綁定錯位

// 禁止 3：addNotInCondition 沒 guard 空陣列
$c->addNotInCondition('id', $excludeIds);  // 若 $excludeIds = [] → 無效 SQL
```

## Builder 替代

- **新寫的 Repository / 查詢層** → 用 `Infrastructure\Database\Query\Builder` 的 IN 方法。見 `infrastructure/AGENTS.md` Database Query Toolkit 段 / `docs/guides/query-toolkit-cookbook.md`。
- **改既有 legacy code、AR `findAll($criteria)`、或要併入既有 `CDbCriteria` 條件鏈** → 沿用本頁 `addInCondition` / `addNotInCondition`。

兩者底層同走 PDO bind，安全性等價；選擇看所在層是否已是 Builder 風格。

## 相關

- always-loaded floor：`.claude/rules/php/patterns.md`
- Repository 設計：`infrastructure/AGENTS.md` Database Query Toolkit 段
