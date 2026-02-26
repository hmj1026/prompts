# 🛠️ Utility 腳本參考

> ~/.claude/scripts/utils/ 中的 5 個工具腳本

## 概覽

Utility 腳本是獨立的工具，用於檢查設置、依賴和運行測試。不同於 hooks（自動觸發），utilities 需要手動執行。

```
~/.claude/scripts/utils/
├── check-dependencies.sh       (檢查依賴)
├── verify-setup.sh             (驗證設置)
├── run-phpunit-tests.sh        (運行測試)
├── phpstan-analysis.sh         (靜態分析)
└── php-code-style-check.sh     (代碼風格)
```

---

## 📋 腳本清單

### 1. `check-dependencies.sh` (212 行)

**用途**: 檢查系統依賴是否已安裝

**檢查項目**:
- ✅ PHP CLI
- ✅ PHPUnit
- ✅ PHPCS (PHP Code Sniffer)
- ✅ PHPStan
- ✅ Composer
- ✅ Git, Docker, Python, Grep

**用法**:

```bash
bash ~/.claude/scripts/utils/check-dependencies.sh
```

**輸出範例**:

```
✅ PHP 7.4.3 installed
✅ Composer installed
⚠️  PHPUnit not installed (optional)
❌ Docker not available
```

**何時使用**:
- 初始設置驗證
- 環境配置檢查
- 快速診斷環境問題

---

### 2. `verify-setup.sh` (40 行)

**用途**: 快速驗證 Claude Code hooks 設置完整性

**檢查項目**:
- 🔍 hooks/ 目錄存在
- 🔍 scripts/ 目錄存在
- 🔍 settings.json 存在
- 🔍 Hook 腳本可執行

**用法**:

```bash
bash ~/.claude/scripts/utils/verify-setup.sh
```

**輸出範例**:

```
✅ Setup valid! PHP hooks configured.
  • Hooks directory: /home/user/.claude/scripts/hooks/
  • Scripts directory: /home/user/.claude/scripts/
  • Settings file: /home/user/.claude/settings.json
```

**何時使用**:
- 初次安裝驗證
- 排查 hooks 不執行的問題
- 快速檢查設置

---

### 3. `run-phpunit-tests.sh` (81 行)

**用途**: 自動運行 PHPUnit 測試

**特點**:
- 自動偵測對應的測試檔案
- 支援 Docker 和本機 PHPUnit
- 智能跳過不存在的測試

**用法**:

```bash
# 運行特定檔案的測試
bash ~/.claude/scripts/utils/run-phpunit-tests.sh /path/to/SalesService.php

# Docker 環境自動執行
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/unit/Sales/SalesServiceTest.php
```

**運作邏輯**:

1. 檢查檔案是否存在
2. 推斷對應測試檔案
3. 使用 Docker (優先) 或本機 PHPUnit
4. 執行測試並顯示結果

**何時使用**:
- 實作新功能後驗證
- 修改現有代碼後
- 配合 TDD 工作流
- hooks 自動化測試

---

### 4. `phpstan-analysis.sh` (45 行)

**用途**: 執行 PHPStan 靜態分析

**功能**:
- 檢查類型一致性
- 檢測未定義變量
- 驗證方法調用
- 報告可能的 bug

**用法**:

```bash
# 分析單個檔案
bash ~/.claude/scripts/utils/phpstan-analysis.sh /path/to/file.php

# PHPStan 會輸出警告和錯誤
phpstan analyse --level 5 --no-interaction /path/to/file.php
```

**輸出範例**:

```
 1/1 [████████████████████████████████] 100%

 ------ ---------------------------------------------------------------
  Line   Column
 ------ ---------------------------------------------------------------
  42     Property $order is never read.
  85     Return type should be void, but function returns mixed.
 ------ ---------------------------------------------------------------

 [ERROR] Found 2 PHPStan errors
```

**何時使用**:
- 檢查類型安全性
- 偵測潛在的 bug
- 代碼質量審查
- 與 IDE 整合進行實時檢查

**先決條件**:
- PHPStan 已安裝: `composer require --dev phpstan/phpstan`

---

### 5. `php-code-style-check.sh` (41 行)

**用途**: 檢查 PHP 代碼風格 (PSR-2 標準)

**檢查項目**:
- ✅ 縮進 (4 spaces)
- ✅ 行長度 (max 120 chars)
- ✅ 命名規範
- ✅ 括號位置
- ✅ 空格使用

**用法**:

```bash
# 檢查單個檔案
bash ~/.claude/scripts/utils/php-code-style-check.sh /path/to/file.php

# PHP_CodeSniffer 檢查
phpcs --standard=PSR2 /path/to/file.php
```

**輸出範例**:

```
FILE: /path/to/Order.php
 42 | ERROR | Missing function doc comment
 85 | WARNING | Line is too long (150 chars)
 95 | ERROR | Indentation error, expected 4 spaces
```

**何時使用**:
- 風格檢查
- 代碼規範驗證
- 準備提交前

**先決條件**:
- PHP_CodeSniffer: `composer require --dev squizlabs/php_codesniffer`

---

## 🚀 常用操作

### 初始設置驗證

```bash
# 1. 檢查依賴
bash ~/.claude/scripts/utils/check-dependencies.sh

# 2. 驗證 Claude Code 設置
bash ~/.claude/scripts/utils/verify-setup.sh

# 如果都通過，hooks 已準備好
```

### 開發工作流

```bash
# 1. 編輯 PHP 檔案
# (hooks 自動驗證語法)

# 2. 運行相關測試
bash ~/.claude/scripts/utils/run-phpunit-tests.sh /path/to/file.php

# 3. 檢查代碼風格
bash ~/.claude/scripts/utils/php-code-style-check.sh /path/to/file.php

# 4. 靜態分析
bash ~/.claude/scripts/utils/phpstan-analysis.sh /path/to/file.php

# 5. 提交時自動運行 Stop hooks 進行最終檢查
```

### CI/CD 管道

```bash
# Pre-commit
bash ~/.claude/scripts/utils/check-dependencies.sh
bash ~/.claude/scripts/utils/php-code-style-check.sh

# Test stage
bash ~/.claude/scripts/utils/run-phpunit-tests.sh

# Quality gate
bash ~/.claude/scripts/utils/phpstan-analysis.sh
```

---

## 🔧 自訂和擴展

### 修改 PHPStan 分析等級

編輯 `phpstan-analysis.sh`:

```bash
# 改變從 level 5 到 level 8 (更嚴格)
phpstan analyse --level 8 --no-interaction "$FILE_PATH"
```

**PHPStan 等級**:
- 0: 最寬鬆
- 5: 平衡 (推薦)
- 9: 最嚴格

### 自訂 PHPCS 標準

編輯 `php-code-style-check.sh`:

```bash
# 改用 PSR-12 (PSR-2 的升級版)
phpcs --standard=PSR12 "$FILE_PATH"
```

---

## 📊 統計

| 腳本 | 行數 | 執行時間 |
|------|------|---------|
| check-dependencies.sh | 212 | ~2s |
| verify-setup.sh | 40 | ~0.5s |
| run-phpunit-tests.sh | 81 | ~10-30s |
| phpstan-analysis.sh | 45 | ~5-10s |
| php-code-style-check.sh | 41 | ~1-2s |

---

## ❓ 常見問題

| 問題 | 解決方案 |
|------|---------|
| "PHPUnit not found" | `composer require --dev phpunit/phpunit` |
| "PHPStan not installed" | `composer require --dev phpstan/phpstan` |
| "PHPCS not available" | `composer require --dev squizlabs/php_codesniffer` |
| 腳本執行失敗 | 確認執行權限: `chmod +x ~/.claude/scripts/utils/*.sh` |
| Docker 相關錯誤 | 確認容器正在運行: `docker ps` |

---

## 🔗 相關資源

- `README.md` - Hooks 清單
- `CONFIGURATION.md` - 配置指南
- `QUICK-REFERENCE.md` - 速查表
- `~/.claude/scripts/utils/` - 所有 utility 腳本

---

**最後更新**: 2026-02-25 | **版本**: 1.0
