# zdpos-217 Project Mandates

## 🚨 CRITICAL: PHP 5.6 Legacy Constraints
**ZERO TOLERANCE** for modern syntax. Any violation will cause a 500 error in the production environment (PHP 5.6.40).

- ❌ **FORBIDDEN**: 
    - Null Coalescing Operator (`??`) -> Use `isset($var) ? $var : $default`
    - Scalar Type Hints (`function(int $id)`) -> Use PHPDoc `@param int $id`
    - Return Type Declarations (`: void`, `: array`) -> Use PHPDoc `@return void`
    - Spaceship Operator (`<=>`)
    - Anonymous Classes / Arrow Functions
- ✅ **REQUIRED**:
    - **Short Array Syntax**: `[]` is allowed and preferred.
    - **Strict PHPDoc**: Mandatory for ALL methods and properties to facilitate IDE/AI understanding.
    - **Explicit Casting**: Always cast DB results to expected types (e.g., `(int)$row['id']`).

## 🏛 Architecture & Framework (Yii 1.1 + DDD)
This project is a hybrid of legacy Yii 1.1 MVC and modern DDD patterns.

- **ActiveRecord Requirement**: 
  Every model MUST include: `public static function model($className=__CLASS__) { return parent::model($className); }`
- **DB Query Returns**:
  `CDbCommand::queryRow()` returns `false` (NOT `null`) when no results. Always check with `if ($result === false)` or `if (!$result)`.
- **DDD Layers**:
    - `Controller` -> `Service` -> `Repository`
    - **Domain Layer** (`domain/`): Business logic, DTOs, Interfaces.
    - **Infrastructure Layer** (`infrastructure/`): Data access, Repositories, External APIs.
- **Namespaces**: Use `Domain\Services`, `Infrastructure\Repositories`, etc. (Configured via `setPathOfAlias.php`).

## 🎨 Frontend (Legacy POS)
- ❌ **FORBIDDEN**: `$.ajax`, `fetch`, `axios`.
- ✅ **REQUIRED**: **`POS.list.ajaxPromise()`** for all asynchronous requests.
- **State Management**: The global `POS` object is the Single Source of Truth.

## 🧪 Testing Standards (PHPUnit 5.7)
- **Method Naming**: MUST start with `test` (e.g., `testCalculateTotal`). **NO** `shouldXxx` or `it_xxx`.
- **Annotations**: Remove `@test` annotations if using `testXxx` naming.
- **String Comparison**: When verifying MySQL results (case-insensitive), ALWAYS use **`strcasecmp()`**, NEVER `strcmp()`.
- **Mocking**: Prefer `createMock()` over `getMockBuilder()` when possible.

## 🛠 Common Operations (via Docker)
Always execute commands through the project's Docker container (using -i for interactive mode):

```bash
# Running Tests (Fast Suite ~330ms Domain+Infrastructure)
docker exec -i -w /var/www/www.posdev/zdpos-217 pos_php phpunit -c protected/tests/phpunit-fast.xml

# Running Tests (Full Suite / Specific Test)
docker exec -i -w /var/www/www.posdev/zdpos-217 pos_php phpunit -c protected/tests/phpunit.xml [Path_to_Test]

# Database Migrations
docker exec -i -w /var/www/www.posdev/zdpos-217 pos_php php protected/yiic.php migrate up

# Reset Opcache (dev4 pos_php revalidate_freq=60; 修改 view / PHP 後跑測試前必執行避免偽綠)
docker exec -i pos_php sh -c 'kill -USR2 1'
```

## 🛡️ Safety & Git Discipline
- **SSOT**: Extend existing single source of truth, never duplicate.
- **Read-before-Write**: Run `GitNexus` impact analysis before editing symbols to evaluate blast radius.
- **No auto-commit**: Never automatically commit; use `/dhpk:smart-commit` or `/dhpk:precommit`.

## 📝 Communication
- **Language**: Traditional Chinese (正體中文) for responses and comments.
- **Terminology**: Keep technical terms in English (Controller, Action, Repository).
- **Proactiveness**: Suggest refactoring monolithic logic into Services/Repositories where appropriate.
