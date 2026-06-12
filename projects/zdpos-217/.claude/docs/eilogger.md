# EILogger Usage

## Architecture

| Component | File | Role |
|-----------|------|------|
| `EILogger` | `protected/components/EILogger.php` | Static proxy (Singleton Facade) |
| `EI` | `protected/models/EI.php` | Implementation |

`EILogger::method()` → `__callstatic()` → `EI` singleton instance → actual method

## Method Signatures

**`slog($msg, $file_title, $folder = "")`** — structured log (preferred)
- `$msg`: string|array (arrays expanded via `print_r()`)
- Output: `/var/www/zdnStorage/logs/{YYYY-MM}/{HTTP_HOST}/{DB_NAME}/{folder}/{file_title}_{Ymd}.xml`

**`log($msg, $develop = false, $otherLog = false)`** — general debug log
- `$develop = true` → routes to `SaveReceiptLog_{Ymd}.xml`; `$otherLog = true` → routes to `PrintLog_{Ymd}.xml`
- Output: `.../{DB_NAME}/debug/log{Ymd}.xml` (default)

**`startMarkTime()` / `stepTimeLog($step)`** — performance timing between steps

## When to Use

| Context | Method |
|---------|--------|
| Service / Domain layer | `EILogger::slog()` static |
| Controller with `$EI` variable | `$EI->slog()` instance |
| Quick dev debug | `EILogger::log()` |
| **Never** | `Yii::log()` in business logic |

## Usage Examples

```php
// API integration log
EILogger::slog([
    'method'  => __FUNCTION__,
    'message' => 'operation description',
    'request' => $request->getAttributes(),
], $this->getFileTitle(), $this->getLogFolder());

// Error / exception log
EILogger::slog([
    'class'   => __CLASS__,
    'method'  => __FUNCTION__,
    'message' => 'error description',
    'error'   => $exception->getMessage(),
    'code'    => $exception->getCode(),
], $fileTitle, $logFolder);
```

**Blacklist**: `slog()` has built-in filter (`getBlackListTitle()` / `getBlackListFolder()`) — matching title or folder silently skips write.

## When to Log

| Scenario | Required? |
|----------|-----------|
| Exception caught then re-thrown | **mandatory** |
| External API call (request + response) | **mandatory** |
| Financial calculation result | **mandatory** |
| Payment / refund key steps | **mandatory** |
| DB transaction open/close | recommended |
| Scheduled command result | recommended |
| Debug during development | optional (`EILogger::log()`) |
| Controller action entry/exit | **forbidden** (too noisy) |

## Severity Semantics

| Level | Meaning | Method |
|-------|---------|--------|
| ERROR | Needs human intervention (payment failure, data inconsistency) | `slog()` + dedicated fileTitle |
| WARNING | Auto-recoverable but needs attention | `slog()` + general fileTitle |
| INFO | Normal business flow | `slog()` |
| DEBUG | Dev-only; must not exist in production | `log()` |

## Forbidden Patterns

- `Yii::log()` / `error_log()` — bypasses EILogger, no central management
- `var_dump()` / `print_r()` — pollutes HTTP response
- Logging full request body with passwords — sensitive data leak
- `slog()` without `__METHOD__` — untraceable source
