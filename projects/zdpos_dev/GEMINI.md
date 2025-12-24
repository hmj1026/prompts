
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

# Part 1: Global Development Guidelines

## 🎯 Core Development Philosophy
1.  **Single Source of Truth (SSOT)**: Ensure one authoritative implementation per concept. Extend existing logic; never duplicate.
2.  **Read First, Code Later**: Use `Grep`/`Glob` to study existing patterns before coding. Plan first to prevent technical debt.
3.  **Simplicity & Clarity**: **Clear intent > Clever code.** Follow SOLID and DRY. Choose the "boring," obvious solution.
4.  **Incremental Execution**: Decompose complex tasks (>3 steps). Commit small changes that always compile and pass tests.
5.  **Pragmatic Mindset**: **Pragmatic > Dogmatic.** Base development on verifiable facts, not guesses (Anti-Hallucination).
6.  **Test-Driven (TDD)**: Write tests first to guarantee correctness and robustness.

## 🔍 Task Execution Flow
1.  **Preparation & Exploration**: Fully understand requirements; use `rg` or `fd` to find existing patterns.
2.  **Planning (The Staging Strategy)**: For complex tasks, create `IMPLEMENTATION_PLAN.md` and update status continuously.
3.  **Implementation Loop (TDD)**:
    - **Study**: Review similar existing code patterns.
    - **Red**: Write a failing test.
    - **Green**: Write **minimal** code to pass the test.
    - **Refactor**: Optimize while keeping tests green.
    - **Commit**: Specific message linking to the Plan Stage.
4.  **Anti-Loop Protocol (When Stuck)**: If a specific issue fails **3 times**, STOP. Document the failure, research alternatives, and pivot.

## ✍️ Coding & Technical Standards
- **Consistency First**: Follow existing project patterns and naming conventions. Find 3 similar features before coding.
- **Architecture**: Composition > Inheritance. Explicit > Implicit. Interfaces > Singletons.
- **Error Handling**: **Fail Fast** with descriptive messages. No silent failures or swallowed exceptions.
- **Documentation**: Add PHPDoc/JSDoc for all new units. Comments must be concise.

## ✅ Quality Assurance & "Definition of Done"
- **Commit Checklist**: Code must compile, pass all tests, include new tests, and have no lint errors.
- **Test Guidelines**: Test **behavior**, not implementation. Tests must be deterministic (not flaky).
- **Critical Rules**: **NEVER** use `--no-verify` or disable tests to fix CI. **ALWAYS** self-review before committing.

## 🤖 Agent Execution Environment
- **Tool Selection**: Use `fd` for files, `rg` for text, and `ast-grep` for code structure.
- **Execution Strategy**: Read large files in chunks (250-line blocks). Do not introduce new dependencies without justification.

---

# Part 2: Project-Specific Rules (zdpos_dev)

## 📝 Project Overview
- **Project Name:** zdpos_dev
- **Description:** A POS system based on the Yii 1.1 framework, featuring a DDD-Like layered architecture.
- **Primary Database:** `zdpos_dev_2` (MySQL 5.7.33)
- **Local URL:** `https://www.zdpos.test/dev3`

## 💻 Environment & Infrastructure
- **OS:** Windows 10 (Laragon 8.0 / Apache 2.4.62)
- **PHP Version:** **5.6.40 (Legacy)**
- **Project Paths:**
    - Source Code: `E:\projects\zdpos_dev`
    - Web Entry: `E:\laragon\www\www.zdpos\dev3`
- **Docker Context:**
    - Container Name: `pos_php`
    - Workdir: `/var/www/www.posdev/zdpos_dev`
    - **TDD Command:** `docker exec -it pos_php /bin/sh -c "cd /var/www/www.posdev/zdpos_dev && phpunit ./protected/tests/unit/*.php"`

## 🚨 CRITICAL DEVELOPMENT RULES

### 1. PHP 5.6 Compatibility (Mandatory)
- ❌ **NO** Null Coalescing Operator (`??`). Use `isset()` or `!empty()`.
- ❌ **NO** Scalar Type Hints (e.g., `function(int $id)`). Use PHPDoc.
- ❌ **NO** Return Type Declarations (e.g., `: void`).
- ✅ **ALLOWED:** Short Array Syntax `[]` (Supported since PHP 5.4).
- ✅ **ActiveRecord Requirement**: Models MUST include:
  `public static function model($className=__CLASS__) { return parent::model($className); }`

### 2. File System Constraints
- 🔴 **ROOT (`E:\projects\zdpos_dev\`)**: Treat as **READ-ONLY**.
- 🟢 **WEB ROOT (`E:\laragon\www\www.zdpos\dev3`)**: Treat as **WRITEABLE**.
- All dynamic artifacts (reports/images) must be stored in the `output/` directory.

### 3. Frontend Constraints (zpos.js)
- ❌ **DO NOT** use `$.ajax`, `fetch`, or `axios` directly.
- ✅ **MUST USE:** `POS.list.ajaxPromise()` for all asynchronous requests.
- **State Management:** The global `POS` object is the single source of truth for frontend state.

## 📂 Architecture & File Map

| Directory | Purpose | Rules / Implementation |
| :--- | :--- | :--- |
| `protected/models/` | Yii ActiveRecords | Inherit from `CActiveRecord` |
| `protected/controllers/` | MVC Controllers | Inherit from `Controller` (Permission checks integrated) |
| `protected/domain/` | Business Logic | **Pure PHP.** No dependencies on Yii framework. |
| `protected/infrastructure/` | Data Access | Implements Domain interfaces using Yii's AR or DAO. |
| `protected/components/zdnbase/` | Core Library | Global helpers (Logs, Paths, DB Access). |
| `protected/config/dev3.php` | Config | Main DB and system configuration. |
| `assets/zpos/zpos.js` | POS Frontend Core | Handles POS flow and `POS.thread.step`. |

## 🛠 Development Workflow (The "Clear" Strategy)
1. **Planning**: Read/Update `openspec/proposals/*.md`. This serves as the project "Memory".
2. **Coding**: Implement in small increments. Adhere strictly to PHP 5.6 syntax.
3. **Verification**:
   - **Unit Tests**: Use the Docker PHPUnit command.
   - **Manual**: Check `https://www.posdev.test/dev3/{controller}/{action}`.
   - **Logs**: Monitor `protected/runtime/application.log` for Yii errors.
4. **Context Management**: Rely on this document and Proposal files for context rather than chat history when `/clear` is used.

## 💬 Communication Guidelines
- **Response Language:** Always respond in **Traditional Chinese (正體中文)**.
- **Code Comments:** Use **Traditional Chinese** for all logic explanations within the code.