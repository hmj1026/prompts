> This file extends `~/.claude/rules/common/security.md` with PHP logging standards.

# PHP 日誌標準

## 唯一日誌系統：EILogger

專案統一使用 `EILogger`（完整 API 見 `.claude/docs/eilogger.md`），禁止 `Yii::log()`、`error_log()`、`var_dump()`。

## 何時記錄

| 場景 | 必要性 |
|------|--------|
| 例外捕獲後重新拋出 | **強制** |
| 外部 API 呼叫（request + response） | **強制** |
| 金額計算結果 | **強制** |
| 付款/退款流程關鍵步驟 | **強制** |
| 資料庫交易開始/結束 | 建議 |
| 排程/Command 執行結果 | 建議 |
| 一般 debug（開發中） | 可選（`EILogger::log()`） |
| Controller action 進入/離開 | **禁止**（過於冗余） |

## 嚴重等級語意

| 等級 | 用途 | EILogger 方法 |
|------|------|--------------|
| ERROR | 需人工介入（付款失敗、資料不一致） | `slog()` + 專用 fileTitle |
| WARNING | 可自動恢復但需關注 | `slog()` + 通用 fileTitle |
| INFO | 正常業務流程 | `slog()` |
| DEBUG | 開發除錯，正式環境不應存在 | `log()` |

## 禁止模式

- `Yii::log()` / `error_log()` — 不走 EILogger，無法統一管理
- `var_dump()` / `print_r()` — 汙染 HTTP response
- 記錄完整 request body 含密碼 — 洩漏敏感資訊
- 未包含 `__METHOD__` 的 slog() — 無法追蹤來源

> 完整方法簽名、呼叫範例、脫敏規則、file_title 命名 → `.claude/docs/eilogger.md`
