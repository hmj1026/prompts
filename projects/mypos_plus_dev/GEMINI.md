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

# MyPOS Plus Project Context

## 📋 Project Overview

**MyPOS Plus** is a comprehensive Point of Sale (POS) and ordering system built on the **Laravel 5.4** framework. It is designed to handle various business models including:
*   **General Ordering:** Standard web-based ordering.
*   **Table/Seat Ordering:** QR code scanning for dine-in customers (`/seats`).
*   **Retail:** Specific flows for retail environments (`/retail`).
*   **Integration:** Deep integration with **LINE** (Messaging API, Notify, Login) and external delivery platforms (Uber Eats, Nidin).

## 🏗 Architecture & Design

The project follows a hybrid architecture, combining standard Laravel patterns with Domain-Driven Design (DDD) concepts.

### Key Architectural Layers
*   **App (Standard Laravel):**
    *   `App\Http\Controllers`: Handles HTTP requests, heavily segmented by module (`General`, `Order`, `Retail`, `Seats`, `Mypos`).
    *   `App\Defined`: Contains Enums/Constants for business rules (e.g., `OrderType`, `PayTypes`, `OrderStatus`).
    *   `App\Models`: Eloquent models (Database/ORM).
*   **Domain (Business Logic):**
    *   Located in `domain/`.
    *   `Services`: Core business logic (e.g., `OrderService`).
    *   `DTOs`: Data Transfer Objects for structured data passing (e.g., `ZposSales`).
    *   `Interfaces`: Contracts for repositories and models.
*   **Infrastructure (Data & External):**
    *   Located in `infrastructure/`.
    *   `Repositories`: Data access implementation (e.g., `OrderRepository`).
    *   `Utility`: Helper classes.

### Multi-Tenancy & Database
*   **Dynamic Database Switching:** The application uses middleware (`DBChange`) to dynamically switch database connections based on the route parameter (`{id}` or `{store}`).
*   **Middleware:** Heavy use of middleware for session checks (`CheckSession`), LINE validation (`LineCheck`), and database context.

## 🛠 Tech Stack

### Backend
*   **Language:** PHP (>= 5.6.4, tailored for Laravel 5.4).
*   **Framework:** Laravel 5.4.
*   **Key Libraries:**
    *   `ixudra/curl`: HTTP Client.
    *   `linecorp/line-bot-sdk`: LINE Platform integration.

### Frontend
*   **Build Tool:** Laravel Mix (Webpack).
*   **Frameworks:** Vue.js 2, jQuery.
*   **Styling:** Bootstrap Sass.

## 📂 Directory Structure Highlights

| Directory | Purpose |
| :--- | :--- |
| `app/Defined` | **Crucial.** Contains system-wide constants and enumerations. Check here for status codes and types. |
| `domain` | **Business Logic.** Contains Services, DTOs, and Business Rules. |
| `infrastructure` | **Data Access.** Repositories and external service implementations. |
| `routes` | **Entry Points.** `web.php` is segmented by functional modules (`/general`, `/order`, `/retail`, `/seats`). |
| `config` | **Configuration.** Standard Laravel config files. |

## 🚀 Development & Commands

### Prerequisites
*   PHP 5.6+ (Compatible with Laravel 5.4).
*   Composer.
*   Node.js & NPM.

### Build & Run
```bash
# Install Backend Dependencies
composer install

# Install Frontend Dependencies
npm install

# Build Frontend Assets (Dev)
npm run dev

# Build Frontend Assets (Prod)
npm run prod

# Watch Assets
npm run watch

# Run Local Server
php artisan serve
```

### Testing
```bash
vendor/bin/phpunit
```

## ⚠️ Important Notes
1.  **Legacy Framework:** This is an older Laravel version (5.4). Be careful with modern PHP syntax compatibility and documentation references.
2.  **Context Switching:** When working on controllers, always verify which module (`General`, `Retail`, `Seats`) you are affecting.
3.  **Database Connection:** Local development may require specific configuration to mock the dynamic database switching logic found in `DBChange` middleware.
