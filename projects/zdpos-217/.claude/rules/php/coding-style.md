---
paths:
  - "**/*.php"
---

# PHP Coding Style (zdpos-specific)

> Extends `~/.claude/rules/common/coding-style.md`. PHP 5.6 baseline — assume **all** PHP 7.0+ syntax is forbidden (typed params/returns/properties, `??`, `?->`, `match`, arrow fn, named args, group use, multi-catch, short list `[$a,$b]=`, `new class`, union types). Use PHPDoc for types, `isset() ?:` for null coalescing.

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

Hard rule（**僅針對新增 / 修改的程式碼**）：always `[]`, never `array()`。涵蓋 literal、預設參數、function 引數、PHPDoc 範例。

| Forbidden | Correct |
|-----------|---------|
| `array('a', 'b')` | `['a', 'b']` |
| `function f($opts = array())` | `function f($opts = [])` |
| `array_merge(array(), $x)` | `array_merge([], $x)` |

**範圍規則（避免無意義 sweep）**：
- 新增的方法、新增的檔案、本次修改 diff 內出現的 array literal → MUST 用 `[]`
- 該檔案內**其他既有 method** 的 `array()` → **不主動清理**（讓 `.php-cs-fixer.php` 在它自然被 commit 時統一處理；不要為了「順手」擴張 blast radius）
- 例外：整檔重寫 / 整方法重寫時，連帶清理該方法 / 該檔內所有 `array()`

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

Bare literals `0` / `'0'` / `1` forbidden in queries / conditions. Priority:

1. **`AbstractEnum` subclass** (`infrastructure/Foundation/Structures/AbstractEnum.php`) — when reused in multiple places or needs description / Select options
   - Subclasses live in `domain/{Module}/Enums/` or `domain/Models/`
   - `const DESCRIPTIONS` is required, otherwise `getDescription()` throws
2. **Repository class constants** (fallback) — single-Repo usage, simple flags
   - Naming: `FIELD_SEMANTIC` (e.g. `PACKAGE_STATE_PENDING`)
   - Declared at top of class body + PHPDoc noting the field semantic source

Code smell: `(string)$x === '0'` → use `$x == self::CONST_UNSELECTED` (loose comparison).

## Method Name Length

Hard rule（**僅針對新增 / 修改的方法**）：方法名稱不得超過 **32 字元**。

背景：IDE（PHPStorm / IntelliJ）在方法名稱過長時會產生警告提示，影響開發體驗。

**範圍規則（避免無意義 sweep）**：
- 新增的方法、本次 diff 內新命名的方法 → MUST ≤ 32 字元
- 既有方法（未在此次 diff 新增）→ **不主動重命名**（等其被修改時一併調整）
- 例外：整方法重寫 / 整類重寫時，連帶清正該方法 / 該類內所有超標命名

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
