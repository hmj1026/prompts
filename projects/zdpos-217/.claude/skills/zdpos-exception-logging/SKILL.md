---
name: zdpos-exception-logging
description: zdpos catch 區塊統一規範：所有 `catch (\Exception $e)` 必須同時呼叫 ExceptionLogHelper::logCaughtExceptionToApplication() 寫 application.log + 領域 logger（如 SalesWeatherLogger）。使用時機：寫 try / catch、處理 CDbException、ExceptionLogHelper、EILogger、SalesWeatherLogger、PosController catch 範例、application.log 例外紀錄、side-effect 失敗 vs main-flow error 策略決定。一般查詢 / 純讀取程式碼不需要載入。
allowed-tools: Read, Grep, Glob
---

# Exception Logging（catch convention）

> 從 `.claude/rules/php/patterns.md` 抽出，改為按需載入。
> 觸發詞：catch / Exception / ExceptionLogHelper / SalesWeatherLogger / EILogger / application.log / 例外紀錄 / re-throw / safe degrade。

## Hard Rule

每個 `catch (\Exception $e)` SHALL 同時呼叫下列兩者：

1. `\application\helpers\ExceptionLogHelper::logCaughtExceptionToApplication($e, $context)`
   - 寫入 `application.log`，含 stack trace
   - category 自動為 `exception.<class>.<httpStatus?>.caught`
   - 對 `CDbException` 自動去重 SQL
   - 自動補 `REQUEST_URI` / `HTTP_REFERER`

2. **Domain logger**（如 `SalesWeatherLogger::error('<channel>', $method, $msg, $ctx)`）— 供 ops grep。

**SHALL NOT** 留空 catch 或 `// ignore`。

## Strategy（依失敗位置決定 re-throw）

| 失敗類型 | 策略 |
|----------|------|
| **Side-effect 失敗**（context insert / metrics 等次要寫入） | log + safe degrade（status='error'，**不** re-throw） |
| **Main-flow error**（主流程失敗） | log + re-throw 或設 `status='error'` 由上游 escalate |

## 參考實作

- 慣例與最完整範例：`protected/controllers/PosController.php`
- Domain logger 樣板：`SalesWeatherLogger`（`domain/SalesWeather/Logging/`）
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

## 全域規則參考

- 主規則檔：`.claude/rules/php/patterns.md`（已縮短，本主題已搬到本 skill）
- EILogger 用法細節：`.claude/docs/eilogger.md`
