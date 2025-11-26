<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# Project Context: zdpos_dev

> **Note**: These project-specific rules override general guidelines where conflicts occur.

## 🛠 Tech Stack & Environment
-   **Core**: PHP 5.6.40 (Yii 1.1), MySQL 5.7, Apache 2.4.
-   **Frontend**: ES6 JavaScript, `zpos.js` (Global `POS` object).
-   **Paths**:
    -   Root (ReadOnly): `D:\projects\zdpos_dev\`
    -   Web Root: `D:\laragon\www\www.zdpos\dev3\`
    -   Local URL: `https://www.zdpos.test/dev3`
-   **Config**: `protected/config/dev3.php`, Timezone `Asia/Taipei`.

## 📂 Architecture & File Placement
**Root is Read-Only.** Create/Modify files only in allowed subdirectories.
**Outputs:** All dynamic artifacts (reports/images) go to `output/`.

| Directory | Purpose | Namespace / Rules |
| :--- | :--- | :--- |
| `protected/models/` | Yii ActiveRecords | `class Post extends CActiveRecord` |
| `protected/controllers/`| MVC Controllers | `class SiteController extends Controller` |
| `protected/helpers/` | Helpers | `class CommonHelper` |
| `domain/Services/` | Business Logic | Namespace `Domain\Services` (DDD preferred) |
| `infrastructure/Repositories/` | Data Access | Namespace `Infrastructure\Repositories` |
| `js/` | Frontend Scripts | Use `zpos.js` as entry point |

## 📐 Coding Conventions

### PHP 5.6 & Yii 1.1 Constraints
-   **Syntax**: No scalar/return types. No `??` operator. Use Short Array `[]`.
-   **Typing**: MUST use PHPDoc for all methods/props (`@param string $var`).
-   **Yii AR**: Models must define `public static function model($className=__CLASS__)`.
-   **Controllers**: Actions must look like `public function actionIndex()`.
-   **No New Libs**: Use existing `phpqrcode`, `CommonHelper`, etc.

### Frontend (ES6)
-   **Async**: Use `async/await` and `Promise`.
-   **AJAX**: STRICTLY use `POS.list.ajaxPromise()` wrapper. Do NOT use raw `$.ajax` if avoidable.
-   **Global**: `POS` object is the SSOT for frontend state.

### Naming & Style
-   **PHP Class**: `PascalCase`
-   **Method/Prop**: `camelCase`
-   **Const**: `UPPER_SNAKE_CASE`
-   **Database**: `snake_case` (`receipt_credit`, `tax_number`)
-   **Format**: 4 spaces indent. Single quotes `''` preferred for strings.
