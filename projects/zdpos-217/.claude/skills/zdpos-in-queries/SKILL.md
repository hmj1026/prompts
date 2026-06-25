---
name: zdpos-in-queries
description: zdpos IN / NOT IN 查詢安全寫法：用 CDbCriteria::addInCondition() / addNotInCondition()，禁止字串內插（`IN ({$str})`），且必須 array_values($ids) 避免非連續 key bug，addNotInCondition 需 guard 空陣列。使用時機：寫 SQL IN / NOT IN 條件、處理多 ID 查詢、addInCondition / addNotInCondition / array_values 陷阱、LIKE + IN 複合條件合併。一般 WHERE = / LIKE 不需要本 skill。
allowed-tools: Read, Grep, Glob
---

# IN / NOT IN Queries（安全寫法）

> 從 `.claude/rules/php/patterns.md` 抽出，改為按需載入。
> 觸發詞：IN clause / NOT IN / addInCondition / addNotInCondition / array_values / WHERE IN 多 ID / 複合 LIKE+IN。

## Hard Rules

1. **永遠**用 `CDbCriteria::addInCondition()` / `addNotInCondition()`，**禁止**字串內插（`"col IN ({$str})"`）。
2. 傳入前**永遠** `array_values($ids)` — 防止非連續 key 造成參數綁定錯位。
3. `addNotInCondition` **必須 guard 空陣列**：`addNotInCondition('col', [])` 會生成無效 SQL。

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

判準：

- **新寫的 Repository / 查詢層** → 用 `Infrastructure\Database\Query\Builder`（DB Query Layering）提供的 IN 方法（型別安全、自動綁參）。見 `infrastructure/CLAUDE.md` Database Query Toolkit 段 / `docs/guides/query-toolkit-cookbook.md`。
- **改既有 legacy code、AR `findAll($criteria)`、或要併入既有 `CDbCriteria` 條件鏈** → 沿用本頁 `addInCondition` / `addNotInCondition` 寫法（強行換 Builder 反而擴大 diff、破壞 surgical change）。

兩者底層同走 PDO bind，安全性等價；選擇看「所在層是否已是 Builder 風格」，不為換而換。

## 全域規則參考

- 主規則檔：`.claude/rules/php/patterns.md`（已縮短，本主題已搬到本 skill）
- Repository 設計：`infrastructure/CLAUDE.md` Database Query Toolkit 段
