> This file extends `~/.claude/rules/common/coding-style.md` with PHP specific content.

# PHP Coding Style

## PHP 5.6 Compatibility (Hard Limits)

| Forbidden | Use Instead |
|-----------|-------------|
| Type hints: `function foo(int $id)` | PHPDoc: `@param int $id` |
| Return types: `: string` | PHPDoc: `@return string` |
| Null coalescing: `$x ?? 'default'` | Ternary: `isset($x) ? $x : 'default'` |
| Array syntax: `array('key' => 'val')` | Modern syntax: `['key' => 'val']` |

## Framework Access Patterns

- **POST/GET**: Use `Yii::app()->request->getPost()` not `$_POST`
- **PDO Queries**: MANDATORY prepared statements with `:param` binding
- **Models**: All ActiveRecord classes must have:
  ```php
  public static function model($className=__CLASS__) { return parent::model($className); }
  ```
- **Error Handling**: Check `!$result` explicitly; `queryRow()` returns `false` (not `null`)

## Code Quality Checklist

- ✓ PHP 5.6 compatibility verified (no type hints, no `??`)
- ✓ Framework used for request access (no direct `$_GET/POST`)
- ✓ All SQL queries use PDO prepared statements
- ✓ Functions < 50 lines, files < 800 lines
- ✓ PHPDoc on all public methods (see php-pro skill for examples)
- ✓ Error handling explicit (no silent failures)
