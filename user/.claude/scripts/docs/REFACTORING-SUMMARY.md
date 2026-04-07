# Hooks Scripts 重構摘要

**完成日期**: 2026-02-25

## 🎯 重構目標

將 Claude Code hooks 從內聯 commands（在 settings.json 中） 抽取到獨立的可執行腳本，提供：
- ✅ 更好的可維護性
- ✅ 模組化設計
- ✅ 易於版本控制
- ✅ 支持環境變量化

## 📊 重構前後對比

### Before (內聯 Commands)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "if [[ \"$filePath\" == *.php ]]; then php -l \"$filePath\" 2>&1 | grep -q 'Parse error' && (echo '❌ PHP Syntax Error detected'; exit 1) || echo '✅ PHP syntax valid'; fi"
          }
        ]
      }
    ]
  }
}
```

**問題**：
- 命令長且難讀
- 難以測試
- 難以重用

### After (獨立腳本)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/validate-php-syntax-edit.sh \"$filePath\""
          }
        ]
      }
    ]
  }
}
```

**優勢**：
- 簡潔清晰
- 易於維護
- 易於測試和重用

## 📁 新建結構

### 目錄組織

```
~/.claude/
├── scripts/                          # ← 新增
│   ├── README.md                     # 腳本文檔
│   ├── CONFIGURATION.md              # 配置指南
│   ├── REFACTORING-SUMMARY.md        # 本文件
│   ├── pre-git-operations-check.sh
│   ├── check-docker-container.sh
│   ├── validate-php-syntax.sh
│   ├── validate-php-syntax-edit.sh
│   ├── check-php56-compatibility.sh
│   ├── scan-hardcoded-secrets.sh
│   ├── check-security-vulnerabilities.sh
│   ├── validate-yii-controller.sh
│   ├── validate-yii-model.sh
│   ├── git-status-summary.sh
│   └── docker-environment-status.sh
├── hooks/                            # 既有 (文檔 + 大型腳本)
│   ├── pre-commit-validation.sh
│   ├── check-dependencies.sh
│   └── (其他文檔)
├── settings.json                     # 更新 (使用新腳本路徑)
└── ...
```

## 📋 抽取的 11 個腳本

| # | 腳本名稱 | 目的 | 型態 | Async |
|----|---------|------|------|-------|
| 1 | pre-git-operations-check.sh | 檢查危險 git 操作 | PreToolUse | ❌ |
| 2 | check-docker-container.sh | 驗證 Docker 容器 | PreToolUse | ✅ |
| 3 | validate-php-syntax.sh | Write 後檢查語法 | PostToolUse | ✅ |
| 4 | validate-php-syntax-edit.sh | Edit 後檢查語法 (blocking) | PostToolUse | ❌ |
| 5 | check-php56-compatibility.sh | 檢查 PHP 7+ 語法 | PostToolUse | ✅ |
| 6 | scan-hardcoded-secrets.sh | 掃描硬編碼密鑰 | PostToolUse | ✅ |
| 7 | check-security-vulnerabilities.sh | SQL 注入檢查 | PostToolUse | ✅ |
| 8 | validate-yii-controller.sh | Yii Controller 驗證 | PostToolUse | ✅ |
| 9 | validate-yii-model.sh | Yii Model 驗證 | PostToolUse | ✅ |
| 10 | git-status-summary.sh | 會話結束顯示狀態 | Stop | ✅ |
| 11 | docker-environment-status.sh | 會話結束顯示 Docker 狀態 | Stop | ✅ |

## 🔄 遷移步驟

### ✅ 已完成

1. **建立 `~/.claude/scripts/` 目錄**
2. **創建 11 個腳本文件**
   - 使用 Bash heredoc 確保 LF 行結束符
   - 設定所有腳本可執行權限
3. **更新 `~/.claude/settings.json`**
   - 移除內聯 commands
   - 添加腳本引用 (使用 `bash ~/.claude/scripts/xxx.sh`)
4. **驗證 JSON 格式**
5. **建檔文檔**
   - README.md - 腳本清單與快速參考
   - CONFIGURATION.md - 詳細配置指南
   - REFACTORING-SUMMARY.md - 本摘要

### 📌 後續步驟 (可選)

1. **環境變量化** - 在 `.bashrc` 中設定 `$CLAUDE_HOME`
2. **進一步模組化** - 根據用途將 hooks 分組
3. **擴展監控** - 添加更多安全檢查 (PHPStan, PHPCS 等)

## 🚀 驗證和測試

### 驗證 JSON 格式

```bash
python3 -m json.tool ~/.claude/settings.json > /dev/null && echo "✅ Valid"
```

### 測試個別腳本

```bash
# 測試 PHP 語法檢查
bash ~/.claude/scripts/validate-php-syntax-edit.sh /mnt/e/projects/zdpos_dev/domain/Services/SalesService.php

# 測試 Git 檢查
bash ~/.claude/scripts/pre-git-operations-check.sh "git push origin main"

# 測試 Yii Model 檢查
bash ~/.claude/scripts/validate-yii-model.sh /mnt/e/projects/zdpos_dev/domain/Models/Order.php
```

### 驗證 Hooks 執行

在 Claude Code 中執行相應操作，確認 hooks 正確觸發：
- **PreToolUse**: 執行 `git push` 或 `git commit` 命令
- **PostToolUse**: 編輯任何 `.php` 文件
- **Stop**: 結束 Claude Code 會話

## 💡 環境變量化建議

### 方案 A：使用 Shell 環境變量

編輯 `~/.zshrc` 或 `~/.bash_profile`：

```bash
export CLAUDE_HOME="$HOME/.claude"
```

然後修改 settings.json 中的命令：

```json
"command": "bash $CLAUDE_HOME/scripts/validate-php-syntax-edit.sh \"$filePath\""
```

**優點**：
- 支持自訂 Claude 根目錄
- 易於在多個環境間遷移

**缺點**：
- 需要手動配置環境變量
- 需要更新所有 settings.json 引用

### 方案 B：使用相對路徑符號

```json
"command": "bash ~/.claude/scripts/validate-php-syntax-edit.sh \"$filePath\""
```

**優點**：
- 無需環境變量配置
- 即時可用

**缺點**：
- 假設用戶主目錄為 `~`
- 不支持自訂 Claude 根目錄

### 當前採用

**方案 B** (使用 `~/.claude/scripts/`) - 簡潔且足以應對目前需求

## 📈 性能影響

### Hook 執行時間

| Hook | 類型 | 預期時間 | 影響 |
|------|------|---------|------|
| validate-php-syntax-edit.sh | Blocking | 50-200ms | ⚠️ 會阻止編輯 |
| 其他 async hooks | 後台 | 100-500ms | ✅ 無影響 |

**建議**：
- Blocking hooks 應盡快完成（< 500ms）
- 複雜檢查應設為 async

## 🛡️ 安全考慮

### 腳本驗證

所有腳本：
- ✅ 使用相對路徑引用（無硬編碼路徑）
- ✅ 正確處理檔名中的空格 (`"$filePath"`)
- ✅ 使用 `set -e` 或 `|| true` 錯誤處理
- ✅ 不執行動態程式碼（無 `eval`）

### 潛在風險

⚠️ **注意**：
- 某些 grep 模式可能產生假正解
- Docker 檢查依賴容器名稱 (pos_php)
- 密鑰掃描基於簡單正則表達式

## 📝 維護檢查清單

在進行以下操作時，記得更新本重構摘要：

- [ ] 添加新 hook 腳本
- [ ] 修改現有 hook 邏輯
- [ ] 調整 hook 執行順序
- [ ] 變更超時時間或 async 設定

## 🔗 相關文件

| 文件 | 用途 |
|------|------|
| `~/.claude/scripts/README.md` | 腳本清單和快速參考 |
| `~/.claude/scripts/CONFIGURATION.md` | 詳細配置指南 |
| `~/.claude/settings.json` | Hooks 主配置文件 |
| `~/.claude/hooks/` | 舊文檔和大型驗證腳本 |

## 📊 統計數據

- **新增腳本**: 11 個
- **新增文檔**: 3 個 (README, CONFIGURATION, REFACTORING-SUMMARY)
- **修改文件**: 1 個 (settings.json)
- **代碼行數減少**: ~250 行 (從 settings.json 中移出)
- **可維護性提升**: ⬆️⬆️⬆️

---

**完成狀態**: ✅ 100%
**下次審視**: 2026-03-25
**版本**: 1.0
