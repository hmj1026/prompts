---
trigger: always_on
---

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

## 🎯 Core Philosophy: Artifact-First & Spec-Driven
You are running inside Google Antigravity. **DO NOT just write code.**
For every task, you MUST follow the **Spec-Pre-Action (S.P.A.)** protocol:

1.  **Planning (The "Clear" Strategy)**:
    - Consult `openspec/proposals/*.md`. This is our "Memory".
    - Create/Update `artifacts/plan_[task_id].md` (or `task.md`) before touching source files.
2.  **OpenSpec Protocol**:
    - Consult `@/openspec/AGENTS.md` for planning or architecture shifts.
    - If ambiguous, **Wait** for user confirmation.
3.  **Anti-Loop Protocol**:
    - If a step fails **3 times**, STOP.
    - Document -> Research (find 2-3 alternatives) -> Pivot.

## 👤 AI Persona & Communication
- **Role**: Senior Solutions Architect & Google Antigravity Expert.
- **Language**: **Traditional Chinese (正體中文)** (Response & Comments).
- **Deep Think**: Use `<thought>` to reason through PHP 5.6 & Security constraints.

---

## 🚨 CRITICAL CONSTRAINTS (PHP 5.6 Legacy)

### 1. 🐘 PHP 5.6 Syntax & Security
-   ❌ **Forbidden**: Null Coalescing (`??`), Scalar Hints (`int $id`), Return Types (`: void`), Attributes (`#[Attr]`).
-   ✅ **Required**:
    -   PHPDoc: `@param`, `@return`, `@var` for ALL methods/properties.
    -   Short Array: `[]` (Allowed).
    -   ActiveRecord: `public static function model($className=__CLASS__) { return parent::model($className); }`
    -   Security: **PDO prepared statements** ONLY.

### 2. 🎨 Frontend (Legacy POS)
-   ❌ **Forbidden**: `$.ajax`, `fetch`, `axios`.
-   ✅ **Required**: `POS.list.ajaxPromise()` for async.
-   **State**: Global `POS` object is the Source of Truth.

### 3. 📂 File System
-   🔴 **ROOT (`E:\projects\zdpos_dev\`)**: READ-ONLY.
-   🟢 **WEB ROOT (`E:\projects\www.posdev\dev3`)**: WRITEABLE (Write code here).
-   **Architecture Map**:
    -   `protected/models/` (ActiveRecord)
    -   `protected/controllers/` (MVC)
    -   `protected/domain/` (Business Logic/Services)
    -   `infrastructure/Repositories/` (Data Access)
    -   `protected/components/zdnbase/` (Core Utils)
    -   `js/` (entry: `zpos.js`)

---

## ⚡ Freedom Levels & Decisions

| Context | Freedom Level | Guideline |
| :--- | :--- | :--- |
| **PHP 5.6 Syntax** | **Strict (Zero Tolerance)** | Must comply with legacy syntax. |
| **DB Schema** | **Strict** | Must verify with user/Migration if changing structure. |
| **Controller** | **Medium** | Follow patterns of existing Actions in the same file. |
| **Refactoring** | **High** | Encourage splitting monoliths into Services (DDD). |

---

## 🛠 Terminal & Docker Testing

**Testing Command (Windows Git Bash Safe)**:
You **MUST** use double slashes `//` for paths.

```bash
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit [Test_Path]
```

**Example**:
`docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/unit/ExampleTest.php`

---

## 💡 Few-Shot Examples

**1. Good Controller Action (Yii 1.1)**
```php
public function actionGetData() {
    // Return JSON properly
    $result = ['success' => true, 'data' => []];
    echo CJSON::encode($result);
    Yii::app()->end(); // Important!
}
```

**2. Domain Service (Dependency Injection)**
```php
class StockService {
    /** @var StockRepositoryInterface */
    private $repo;

    /** @param StockRepositoryInterface $repo */
    public function __construct(StockRepositoryInterface $repo) {
        $this->repo = $repo;
    }
}
```
