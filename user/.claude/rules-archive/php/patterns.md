> This file extends [common/patterns.md](../common/patterns.md) with PHP specific content.

# PHP Design Patterns

## Repository Pattern (Yii 1.1)

Interface：`findById`, `findAll`, `findByCriteria`, `save`, `delete`。
注入 `IOrderRepository` 到 services，不直接用 `Order` model。

## Service Layer

業務邏輯分離：transaction、validation、外部 API、rollback。

## Validator

`class XxxValidator extends CValidator`，model rules：`['field', 'ext.validators.XxxValidator']`

## API Response Envelope

`['success' => bool, 'data' => mixed, 'message' => string, 'metadata' => array]`

## Dependency Injection

Controller：`$this->orderService = Yii::app()->getComponent('orderService')`
Config：`'components' => ['orderService' => ['class' => 'app.services.OrderService']]`

## Pagination

`CDbCriteria` + offset/limit，回傳 total count + paginated results。

## PHP 5.6 Adaptations

| Common Pattern | PHP 5.6 替代 |
|---------------|-------------|
| Named Arguments | `$options` 陣列 + `array_merge($defaults, $options)` |
| Fluent Interface | `CDbCommand` 原生支援鏈式；`CDbCriteria` 需包裝 |
| Lazy Evaluation | `CDbCommand::queryAll()`/`queryRow()` 即 terminal method |

> 完整 code examples 見 `php-pro` skill → `references/yii1-1.md`
