> This file extends [common/coding-style.md](../common/coding-style.md) with PHP error handling patterns.

# PHP 錯誤處理模式

## 分層原則

| 層次 | 處理方式 |
|------|---------|
| **Domain / Service** | 拋出例外 + `EILogger::slog()` |
| **Repository** | 捕獲 DB 例外 → 記錄 → 重新拋出 |
| **Controller (AJAX)** | 捕獲例外 → `$this->error($e->getMessage())` |
| **Controller (頁面)** | 捕獲例外 → Flash message + redirect |

## 標準 JSON 回應（新程式碼強制）

- 成功：`$this->json(['success' => true, 'data' => $result, 'message' => ''])`
- 失敗：`$this->error('原因')`
- 新增 AJAX action 必須使用 `Response` trait（`protected/controllers/traits/Response.php`）
- 既有 legacy `['err' => 0/1]` 格式：修改時逐步遷移

## 禁止模式

| 禁止 | 替代 |
|------|------|
| `echo "success"` / `echo "fail"` | `$this->json(...)` |
| 空 catch `catch (Exception $e) {}` | 至少 `EILogger::slog()` |
| `die()` / `exit()` 在業務邏輯中 | 拋出例外 |
| `@` 錯誤抑制運算符 | 明確處理 |
| `trigger_error()` 在應用層 | 拋出例外 |

## HTTP 狀態碼

| 狀態碼 | 場景 | 方法 |
|--------|------|------|
| 200 | 正常回應 | `$this->json(...)` |
| 400 | 參數驗證失敗 | `$this->error('...', 400)` |
| 403 | 權限不足 | `throw new CHttpException(403, '...')` |
| 404 | 資源不存在 | `$this->notFound('...')` |

> 完整 code examples 見 `.claude/docs/error-handling-examples.md`
