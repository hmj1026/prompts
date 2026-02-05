---
trigger: always_on
---

# Project Context: zdpos_dev
> ℹ️ **Project Knowledge**: For architecture details, code patterns, and directory structure explanations, please refer to [CLAUDE.md](file:///e:/projects/zdpos_dev/CLAUDE.md) in the project root.

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
    -   `domain/` (Business Logic/Services)
    -   `infrastructure/` (Data Access/Interfaces)
    -   `protected/components/zdnbase/` (Core Utils)
    -   `js/` (entry: `zpos.js`)

### 4. 🌍 Environment & Database
-   **Database**: `zdpos_dev_2` (MySQL 5.7.33)
-   **Local URL**: `https://www.zdpos.test/dev3`
-   **PHP Version**: 5.6.40 (Legacy)

---

## ⚡ Freedom Levels & Decisions

| Context | Freedom Level | Guideline |
| :--- | :--- | :--- |
| **PHP 5.6 Syntax** | **Strict (Zero Tolerance)** | Must comply with legacy syntax. |
| **DB Schema** | **Strict** | Must verify with user/Migration if changing structure. |
| **Controller** | **Medium** | Follow patterns of existing Actions in the same file. |
| **Refactoring** | **High** | Encourage splitting monoliths into Services (DDD). |

---

## 🛠 Terminal & Docker Commands

**Core Principle**: You **MUST** use double slashes `//` for paths in Git Bash.

### 1. Testing (PHPUnit)
```bash
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit [Test_Path]
# Example: docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/unit/ExampleTest.php
```

### 2. Database Migrations
```bash
# Create Migration (Must specify name)
docker exec -w //var/www/www.posdev/zdpos_dev pos_php php protected/yiic.php migrate create [Name]

# Run Migrations (Up)
docker exec -w //var/www/www.posdev/zdpos_dev pos_php php protected/yiic.php migrate up
```

---

