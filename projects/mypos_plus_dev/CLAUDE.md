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

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyPOS Plus 是一個基於 Laravel 5.4 的 POS 點餐系統，支援多種業務模式：線上點餐、掃碼點餐、零售、桌位點餐，並深度整合 LINE 平台（Messaging API、Notify、Login）和外送平台（Uber Eats、Nidin）。

## Development Commands

```bash
# 安裝依賴
composer install
npm install

# 前端建構
npm run dev          # 開發版本
npm run prod         # 正式版本
npm run watch        # 監聽模式

# 開發伺服器
php artisan serve

# 測試
vendor/bin/phpunit
```

## Architecture

### 混合式架構（Laravel + DDD）

| 層級 | 目錄 | 命名空間 | 用途 |
|------|------|----------|------|
| App | `app/` | `App\` | 標準 Laravel 元件（Controllers、Models、Middleware） |
| Domain | `domain/` | `Domain\` | 業務邏輯（Services、DTOs、Interfaces） |
| Infrastructure | `infrastructure/` | `Infrastructure\` | 資料存取（Repositories）、公用程式 |

### 多租戶資料庫切換

**關鍵機制**：`DBChange` 中介層根據路由參數動態切換資料庫連線。

路由前綴對應資料庫前綴：
- `/general/{id}`, `/order/{id}`, `/retail/{id}`, `/seats/{id}` → `zdpos_{id}`
- `/mypos/{id}` → `conductor_{id}`（特例：`newswan`、`mellow` 用 `zdpos_`）
- Session 參數 `bbpos` → `bbpos_{id}`
- Session 參數 `conductor` → `conductor_{id}`

### 模組化控制器

每個業務模組有獨立的控制器組（結構相同，命名空間不同）：

| 模組 | 路由前綴 | 控制器命名空間 |
|------|----------|----------------|
| General | `/general/{id}` | `App\Http\Controllers\General\` |
| Order | `/order/{id}` | `App\Http\Controllers\Order\` |
| Retail | `/retail/{id}` | `App\Http\Controllers\Retail\` |
| Seats | `/seats/{id}` | `App\Http\Controllers\Seats\` |
| Mypos | `/mypos/{id}` | `App\Http\Controllers\Mypos\` |

### 重要目錄

- `app/Defined/` - 系統常數與列舉（OrderType、PayTypes、OrderStatus 等）
- `app/Http/Middleware/` - 中介層（DBChange、CheckSession、LineCheck、Validation）
- `domain/Services/OrderService.php` - 訂單核心業務邏輯
- `domain/DTOs/` - 資料傳輸物件（ZposSales 系列）
- `infrastructure/Repositories/` - 資料存取層

## Tech Constraints

### PHP 5.6 相容性

Laravel 5.4 需要 PHP >= 5.6.4，注意避免較新的 PHP 語法：
- ✅ 可用短陣列語法 `[]`
- ❌ 避免 Null Coalescing `??`，改用 `isset()` 或 `!empty()`

### 中介層執行順序

典型路由的中介層堆疊：
1. `DBChange` - 資料庫連線切換
2. `CheckSession` - Session 驗證
3. `LineCheck` - LINE 用戶驗證

## Key Integrations

- **LINE Bot SDK** (`linecorp/line-bot-sdk`) - Webhook 在 `/line/webhook`
- **LINE Notify** - 各模組 `lineController` 處理
- **外送平台** - Uber Eats、Nidin、MyOrder 透過 webhook 整合
