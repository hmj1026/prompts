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

# Gemini AI Development Rules: zdpos_dev

## Project Overview
- **Project Name:** zdpos_dev
- **Description:** A POS system based on the Yii 1.1 framework, featuring front-end and back-end functionality with a DDD-Like layered architecture.
- **Primary Database:** `zdpos_dev_2` (MySQL 5.7.33)
- **Local URL:** `https://www.zdpos.test/dev3`

## Environment & Infrastructure
- **OS:** Windows 10 (Laragon 8.0 / Apache 2.4.62)
- **PHP Version:** **5.6.40 (Legacy)**
- **Project Paths:**
    - Source Code: `D:\projects\zdpos_dev` (Git Repository)
    - Web Entry: `D:\laragon\www\www.zdpos\dev3` (Linked to source)
- **Docker Context:**
    - Container Name: `pos_php`
    - Workdir: `/var/www/www.posdev/zdpos_dev`
    - **TDD Command:** `docker exec -it pos_php /bin/sh -c "cd /var/www/www.posdev/zdpos_dev && phpunit ./protected/tests/unit/*.php"`

## 🚨 CRITICAL DEVELOPMENT RULES

### 1. PHP 5.6 Compatibility (Mandatory)
- ❌ **NO** Null Coalescing Operator (`??`). Use `isset()` or `!empty()`.
- ❌ **NO** Scalar Type Hints (e.g., `function(int $id)`). Use PHPDoc instead.
- ❌ **NO** Return Type Declarations (e.g., `: void`).
- ✅ **ALLOWED:** Short Array Syntax `[]` (Supported since PHP 5.4).
- ✅ **ActiveRecord Requirement:** Models MUST include:
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
1. **Planning:** Read/Update `openspec/proposals/*.md`. This serves as the project "Memory".
2. **Coding:** Implement in small increments. Adhere strictly to PHP 5.6 syntax.
3. **Verification:**
   - **Unit Tests:** Use the Docker PHPUnit command.
   - **Manual:** Check `https://www.posdev.test/dev3/{controller}/{action}`.
   - **Logs:** Monitor `protected/runtime/application.log` for Yii errors.
4. **Context Management:** Expect the user to use `/clear` frequently. Rely on this document and Proposal files for context rather than chat history.

## 💬 Communication Guidelines
- **Response Language:** Always respond in **Traditional Chinese (正體中文)**.
- **Code Comments:** Use **Traditional Chinese** for all logic explanations within the code.