> This file extends `~/.claude/rules/common/testing.md` with PHP specific content.

# PHP Testing (PHPUnit 5.7)

## Test Coverage: 80% Minimum

Structure:
- `unit/` — No Yii::app(), no real DB (pure unit)
- `integration/` — Requires Yii app + database
- `functional/` — Critical business flows (E2E)

Reference: `protected/tests/docs/TESTING_STANDARDS.md`

## Running Tests (Docker PHPUnit)

**CRITICAL**: All Docker commands require `-i` flag (stdin). Missing it causes hang on WSL.

```bash
# Full suite
docker exec -i -w /var/www/www.posdev/zdpos_dev pos_php phpunit -c protected/tests/phpunit.xml

# Unit only (fast, ~4s)
docker exec -i -w /var/www/www.posdev/zdpos_dev pos_php phpunit -c protected/tests/phpunit.xml --testsuite unit

# Integration only
docker exec -i -w /var/www/www.posdev/zdpos_dev pos_php phpunit -c protected/tests/phpunit.xml --testsuite integration

# Fast local (Domain + infrastructure, ~330ms)
docker exec -i -w /var/www/www.posdev/zdpos_dev pos_php phpunit -c protected/tests/phpunit-fast.xml

# Specific file
docker exec -i -w /var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/unit/Domain/SomeTest.php
```

## PHPUnit 5.7 Syntax

| Feature | PHP 5.6 Syntax | Note |
|---------|----------------|------|
| Test method | `public function testXxx()` | Use testXxx naming, remove `@test` |
| Type-strict assert | `assertSame()` not `assertEquals()` | Use assertSame for identical type+value |
| Exceptions | `@expectedException` OR `setExpectedException()` | Both work |
| Mock all methods | `createMock()` | Full stub (all methods return null) |
| Mock partial | `getMockBuilder()->setMethods(null)` | Execute real methods |

**TRAP**: `createMock()` ≠ `getMockBuilder()->setMethods(null)` — not interchangeable.

## Test Isolation Rules

- [ ] Each test: `setUp()` creates fresh state
- [ ] Each test: `tearDown()` cleans up
- [ ] No test depends on another test's output
- [ ] `unit/` tests **never** call `Yii::app()` or real DB
- [ ] `integration/` tests use transactions: `$txn = Yii::app()->db->beginTransaction(); ... $txn->rollback();`

## Common Traps

| Trap | Symptom | Fix |
|------|---------|-----|
| `unit/` calls `Yii::app()` | Silent Yii init | Move test to `integration/` |
| `strcmp()` for DB ORDER BY | MySQL `utf8_unicode_ci` sorts differ from ASCII | Use `strcasecmp()` |
| SELECT field missing | Test expects field not queried | Add field to SELECT |
| No transaction cleanup | DB state pollutes next test | Add rollback in tearDown |

## E2E Testing

**Framework: playwright-cli snapshot**（無 Node.js build step，不引入 `@playwright/test`）

```bash
# Bug fix 前後比對 / 冒煙測試
playwright-cli snapshot https://www.posdev.test/dev3/<controller>/<action>
```

| 適用 | 不適用 |
|------|--------|
| Bug fix 完成後 UI 驗證 | 純 PHP 業務邏輯（PHPUnit 足夠） |
| UI 相關 patch 後 | |

快照目錄：`.playwright-cli/`

## Detailed Examples & Patterns

Full test templates, service mocking, fixture setup, and coverage generation in `php-pro` skill (loaded on-demand).
