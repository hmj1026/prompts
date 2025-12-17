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

## Communication Guidelines
- **Primary Language**: Always respond in **Traditional Chinese (正體中文)** unless specifically requested otherwise.
- **Code Comments**: Use Traditional Chinese.

## 🚨 CRITICAL MUST-READ RULES
1.  **Strict PHP 5.6 Environment**:
    -   ❌ NO Null Coalescing (`??`). Use `isset()` or `!empty()`.
    -   ❌ NO Scalar Type Hints (`function(int $id)`). Use PHPDoc instead.
    -   ❌ NO Return Types (`: void`).
    -   ✅ Short Array Syntax `[]` is ALLOWED (supported since 5.4).
    -   ✅ Models MUST have: `public static function model($className=__CLASS__) { return parent::model($className); }`
2.  **File System Constraints**:
    -   🔴 **ROOT (`E:\projects\zdpos_dev\`) is READ-ONLY**.
    -   🟢 **WEB ROOT (`"E:\projects\www.posdev\dev3"`) is WRITEABLE**.
    -   Ensure relative paths consider the Web Root structure.
3.  **Frontend Constraints**:
    -   ❌ DO NOT use `$.ajax`, `fetch`, or `axios` directly.
    -   ✅ **MUST USE**: `POS.list.ajaxPromise()` for all async requests.
    -   Global Object: `POS` is the source of truth for frontend state.

## 📂 Architecture & File Placement
**Root is Read-Only.** Create/Modify files only in allowed subdirectories.
**Outputs:** All dynamic artifacts (reports/images) go to `output/`.
**Docker** Using docker to develop, should execute command in php container. container name is pos_php, workdir is under `/var/www/www.posdev/zdpos_dev`
**TDD** tdd command should use `cd /var/www/www.posdev/zdpos_dev` then `phpunit ./protected/tests/unit/*.php`

## 📂 Architecture & File Map
| Directory | Purpose | Namespace / Rules |
| :--- | :--- | :--- |
| `protected/models/` | Yii ActiveRecords | `class Post extends CActiveRecord` |
| `protected/controllers/`| MVC Controllers | `class SiteController extends Controller` |
| `protected/helpers/` | Helpers | `class CommonHelper` |
| `domain/Services/` | Business Logic | Namespace `Domain\Services` (DDD preferred) |
| `infrastructure/Repositories/` | Data Access | Namespace `Infrastructure\Repositories` |
| `js/` | Frontend Scripts | Use `zpos.js` as entry point |

## 🛠 Development Workflow (The "Clear" Strategy)
We use a stateless workflow to save tokens.
1.  **Planning**: Read/Update `openspec/proposals/*.md`. This is our "Memory".
2.  **Coding**: Implement small chunks based on the proposal.
3.  **Checking**: Expect the user to run `git commit` after verification is OK.
4.  **Clearing**: Expect the user to run `/clear` often. Rely on `CLAUDE.md` and Proposal files for context, NOT chat history.

## 🧪 Testing & Verification
-   **Unit Tests**: `npm test` (if configured) or specific PHPUnit command.
-   **Manual**: Since this is a legacy web app, suggest URLs to check (e.g., `https://www.posdev.test/dev3/controller/action`).
-   **Logs**: Check `protected/runtime/application.log` for Yii errors.
