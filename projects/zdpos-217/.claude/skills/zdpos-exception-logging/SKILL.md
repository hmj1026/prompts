---
name: zdpos-exception-logging
description: catch 區塊：同時寫 ExceptionLogHelper 與領域 logger。Use when 寫 try/catch，或決定 side-effect 失敗要 degrade 還是 re-throw。
allowed-tools: Read, Grep, Glob
---

# Exception Logging（catch convention）

## Hard Rule

每個 `catch (\Exception $e)` SHALL 同時呼叫下列兩者：

1. `\application\helpers\ExceptionLogHelper::logCaughtExceptionToApplication($e, $context)`
   - 寫入 `application.log`，含 stack trace
   - category 自動為 `exception.<class>.<httpStatus?>.caught`
   - 對 `CDbException` 自動去重 SQL
   - 自動補 `REQUEST_URI` / `HTTP_REFERER`

2. **Domain logger**（如 `SalesWeatherLogger::error('<channel>', $method, $msg, $ctx)`）— 供 ops grep。

## Strategy（依失敗位置決定 re-throw）

| 失敗類型 | 策略 |
|----------|------|
| **Side-effect 失敗**（context insert / metrics 等次要寫入） | log + safe degrade（status='error'，**不** re-throw） |
| **Main-flow error**（主流程失敗） | log + re-throw 或設 `status='error'` 由上游 escalate |

## 參考實作

- 慣例與最完整範例：`protected/controllers/PosController.php`
- Domain logger 樣板：`SalesWeatherLogger`（`domain/SalesWeather/Support/SalesWeatherLogger.php`）
- Helper：`application\helpers\ExceptionLogHelper`

## 反模式（禁止）

```php
// 禁止 1：empty catch
try { ... } catch (\Exception $e) { }

// 禁止 2：// ignore
try { ... } catch (\Exception $e) { /* ignore */ }

// 禁止 3：只寫 EILogger 沒寫 ExceptionLogHelper
try { ... } catch (\Exception $e) {
    EILogger::error(...);  // 缺少 ExceptionLogHelper::logCaughtExceptionToApplication
}
```

## 相關

- always-loaded floor：`.claude/rules/php/patterns.md`
- EILogger 用法：`.claude/docs/eilogger.md`
