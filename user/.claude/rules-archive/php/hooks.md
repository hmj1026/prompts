> This file extends [common/hooks.md](../common/hooks.md) with PHP specific content.

# PHP Hooks

> **Reference only** — 實際 hook 實作見 `~/.claude/settings.json` + `~/.claude/scripts/hooks/`。
> 完整腳本清單見 `~/.claude/scripts/INDEX.md`。

## 已啟用的 PHP Hooks

| 腳本 | 觸發點 | Blocking | 說明 |
|------|--------|----------|------|
| `validate-php-syntax.sh` | Write | No (async) | PHP 語法驗證 |
| `validate-php-syntax-edit.sh` | Edit | **Yes** | PHP 語法驗證（blocking） |
| `check-php56-compatibility.sh` | Write + Edit | No (async) | PHP 5.6 相容性檢查（強化版：23 項 PHP 7+ 語法偵測） |
| `scan-hardcoded-secrets.sh` | Write + Edit | No (async) | 硬編碼密鑰掃描 |
| `check-security-vulnerabilities.sh` | Write + Edit | No (async) | SQL 注入等安全漏洞 |
| `validate-yii-controller.sh` | Write + Edit | No (async) | Yii Controller 結構 |
| `validate-yii-model.sh` | Write + Edit | No (async) | Yii Model 結構 |
| `check-frontend-banned-apis.sh` | Write + Edit | No (async) | 前端禁用 API 檢測 |
| `file-size-warning.sh` | Write + Edit | No (async) | 檔案大小（>800 行）+ 函式長度（>50 行）警告 |
| `check-legacy-response-format.sh` | Write + Edit | No (async) | Legacy API response 格式偵測（echo "success"、die()） |
| `check-slog-method.sh` | Write + Edit | No (async) | EILogger::slog() 缺少 __METHOD__ 偵測 |

## 未啟用（可選）

- **PHPStan**: 需安裝 `phpstan`，可透過 `~/.claude/scripts/utils/phpstan-analysis.sh` 手動執行
- **PHP_CodeSniffer**: 已設定 `phpcs.xml`，可透過 `phpcs --standard=phpcs.xml` 手動執行
