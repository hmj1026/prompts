---
paths:
  - "**/*.php"
---

# PHP Coding Style (zdpos-specific)

> Extends `~/.claude/rules/common/coding-style.md`. PHP 5.6 baseline — assume **all** PHP 7.0+ syntax is forbidden (typed params/returns/properties, `??`, `?->`, `match`, arrow fn, named args, group use, multi-catch, short list `[$a,$b]=`, `new class`, union types). Use PHPDoc for types, `isset() ?:` for null coalescing.

## Scope Rule（新增 / 觸碰碼，避免無意義 sweep）

下列**風格 / 重構類**規則（Array Syntax、Method Name Length、Magic Values 常數化、字串常數化，以及 `php/view-architecture.md` 的 view 架構）一律套用此範圍定義；**語言硬限制（PHP 5.6 syntax / polyfills）不在此列，恆久適用**。

- **IN scope（MUST）**：本次新增的方法 / 檔案、diff 內出現或新命名的程式碼。
- **OUT scope（不主動改）**：本次未觸碰的既有碼——勿為「順手」擴張 blast radius。
- **「實質改寫」例外**：整方法 / 整檔重寫時，連帶清理該範圍內所有同類違規。**「實質改寫」= 重寫整個方法主體或整檔，非僅改幾行**。
- 各節若有自動化工具或專屬豁免（array `.php-cs-fixer.php` 自動修、PHPUnit `testXxx` 命名豁免），於該節補述。

## PHP 5.6 polyfills (no PHP 7+ stdlib)

| Forbidden | Use |
|-----------|-----|
| `random_bytes()` / `random_int()` | `openssl_random_pseudo_bytes()` |
| `intdiv()` | `(int)($a / $b)` |
| `dirname(__FILE__, N)` | nested `dirname()` |
| `str_contains` / `str_starts_with` | `strpos` / `substr` |
| `array_column($a, null, $key)` reindex | pass explicit value key |
| `preg_replace_callback_array` | sequential `preg_replace_callback` |

## Array Syntax (PHP 5.4+ short array only)

Hard rule（依 §Scope Rule）：always `[]`, never `array()`。涵蓋 literal、預設參數、function 引數、PHPDoc 範例。

| Forbidden | Correct |
|-----------|---------|
| `array('a', 'b')` | `['a', 'b']` |
| `function f($opts = array())` | `function f($opts = [])` |
| `array_merge(array(), $x)` | `array_merge([], $x)` |

Auto-enforced by `.php-cs-fixer.php`（`'array_syntax' => ['syntax' => 'short']`）與 `phpcs.xml`（`Generic.Arrays.DisallowLongArraySyntax`）；commit 時 `php-cs-fixer fix` 會自動修正，但寫 code 時直接 `[]` 可省去 churn。

## Framework Access

- Single key: `Yii::app()->request->getPost($key)` / `$this->Request->getPost($key)` (forbidden: `$_POST[$key]` / `$_GET[$key]`)
- Whole POST array in Controller: `$_POST` is the **only allowed exception** (Yii 1.1 has no `getAll()`); Controller layer only, and only after detecting presence via `$this->Request->getPost($key)` first.
- **Domain / Infrastructure layers (Request, Service, Repository)**: strictly forbid `$_POST` / `$_GET`. Request classes must receive an already-normalised array via constructor; do not read superglobals.
- Models need `public static function model($className=__CLASS__) { return parent::model($className); }`
- `queryRow()` returns `false` on miss (not null) — check with `!$result`

## Helper Priority (Str / Arr / Date)

Before any string / array / date operation, **first check** `infrastructure/Support/`:
- `Str`: contains / startsWith / endsWith / length / lower / upper / limit
- `Arr`: get / has / set / only / except / wrap / first / last / flatten
- `Date`: startOfDay / endOfDay / normalizeYmd

If the helper lacks the needed operation: **extend the helper**; manual concatenation in business code is forbidden.

| Forbidden | Correct |
|-----------|---------|
| `$date . ' 00:00:00'` | `Date::startOfDay($date)` |
| `$date . ' 23:59:59'` | `Date::endOfDay($date)` |

## Magic Values (DB column enums)

> **PHP 5.6 — 無原生 `enum`。** 不要寫 `enum Type: int {...}`（PHP 8.1+）；本專案的 enum = `AbstractEnum` 子類或 class const。

Bare literals `0` / `'0'` / `1` forbidden — **不只 query / WHERE**，也涵蓋 **controller 業務分支**（`$this->getStore()->type == 0`）與 **view 渲染分支**（`<?php if ($row['type'] == 0) ?>`）。Priority:

1. **`AbstractEnum` subclass** (`infrastructure/Foundation/Structures/AbstractEnum.php`) — when reused in multiple places or needs description / Select options
   - Subclasses live in `domain/{Module}/Enums/` or `domain/Models/`
   - `const DESCRIPTIONS` is required, otherwise `getDescription()` throws
   - Canonical 範例：`domain/Reports/Enums/StoreTypeEnum.php`（`HEADQUARTERS = 0` / `BRANCH = 1` + `DESCRIPTIONS`）、`domain/Stock/Enums/AllocateStatusEnum.php`
2. **Repository class constants** (fallback) — single-Repo usage, simple flags
   - Naming: `FIELD_SEMANTIC` (e.g. `PACKAGE_STATE_PENDING`)
   - Declared at top of class body + PHPDoc noting the field semantic source

Code smell: `(string)$x === '0'` → use `$x == self::CONST_UNSELECTED` (loose comparison).

**字串常數同理**（依 §Scope Rule；既有 50+ 處 `checkPermission("x")` 不主動掃）：
- Permission key 字面值（`$this->checkPermission("permission")`）、ACL marker（`'*individual'`）、sentinel 字串（`'PERMISSION_NOT_DEFINED'`）→ 收斂進對應模組的 class const（如 `MenuAccessPolicy::INDIVIDUAL_MARKER`、`zdn_menu::TYPE_CATEGORY`），不在多處重複裸字串。
- JS↔PHP 共用常數須雙邊宣告 + parity test 鎖定（見 `js/tests/permission-save-format.test.js` 範式）。

## Method Name Length

Hard rule（依 §Scope Rule）：方法名稱不得超過 **32 字元**。

背景：IDE（PHPStorm / IntelliJ）在方法名稱過長時會產生警告提示，影響開發體驗。

**豁免**：PHPUnit 測試方法（`testXxx`）依 `test[Subject]_[Condition]_[ExpectedOutcome]` 命名慣例，允許超過 32 字元以保留可讀性。

| 超標示例 | 修正方向 |
|---------|---------|
| `assertListenerClassNoArgConstructor` (35) | `assertListenerNoCtor` (20) |
| `searchItemsForVoucherClassBuilder` (33) | `searchVoucherClassItems` (23) |
| `rollbackVoucherHeadTrackForInsert` (33) | `rollbackVoucherHeadTrack` (24) |

策略：刪去 `ForXxx` 後置、縮寫 `Constructor→Ctor`、省略已由類別名稱表達的模組詞。

## Variable Naming

| Kind | Rule | Example |
|------|------|---------|
| array / collection | snake_case plural | `$order_items`, `$pay_actions` |
| object | PascalCase | `$PayAction`, `$OrderRepo` |
| scalar | camelCase | `$storeId`, `$totalAmount` |
