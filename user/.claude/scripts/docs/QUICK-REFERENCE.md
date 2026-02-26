# 📋 Hooks Scripts 快速參考

## PreToolUse (命令執行前)

```
git push / commit / rebase / reset / clean
         ↓
   pre-git-operations-check.sh
   (async: false ⛔ 阻斷)
```

| 腳本 | 觸發 | 作用 | 檔案 |
|------|------|------|------|
| `pre-git-operations-check.sh` | 危險 git 命令 | 提醒確認 | 252B |
| `check-docker-container.sh` | docker, mysql 命令 | 檢查 pos_php | 263B |

---

## PostToolUse (編輯後)

### Write (創建/新增 PHP 檔案)

```
Write .php file
         ↓
validate-php-syntax.sh
(async: true ✅ 背景執行)
```

| 腳本 | 作用 | 阻止 | 檔案 |
|------|------|------|------|
| `validate-php-syntax.sh` | 檢查語法 | ❌ | 160B |

### Edit (編輯已存在的 PHP 檔案)

```
Edit .php file
         ↓
① validate-php-syntax-edit.sh (blocking)
         ↓ (如失敗停止)
② check-php56-compatibility.sh (async)
③ scan-hardcoded-secrets.sh (async)
④ check-security-vulnerabilities.sh (async)
⑤ validate-yii-controller.sh (async)
⑥ validate-yii-model.sh (async)
```

| # | 腳本 | 檢查內容 | 阻止 | 檔案 |
|----|------|---------|------|------|
| 1 | `validate-php-syntax-edit.sh` | PHP 語法 | ✅ | 283B |
| 2 | `check-php56-compatibility.sh` | PHP 7+ 語法 | ❌ | 316B |
| 3 | `scan-hardcoded-secrets.sh` | 密鑰字符串 | ❌ | 308B |
| 4 | `check-security-vulnerabilities.sh` | SQL 注入 | ❌ | 340B |
| 5 | `validate-yii-controller.sh` | Controller 結構 | ❌ | 265B |
| 6 | `validate-yii-model.sh` | Model 結構 | ❌ | 380B |

---

## Stop (會話結束)

```
Session End
         ↓
① git-status-summary.sh (async)
② pre-commit-validation.sh (async)
③ docker-environment-status.sh (async)
```

| 腳本 | 用途 | 檔案 |
|------|------|------|
| `git-status-summary.sh` | 顯示工作目錄變更 (前 20 項) | 186B |
| `docker-environment-status.sh` | 顯示 Docker 容器狀態 | 214B |
| `pre-commit-validation.sh` | 完整預提交驗證 | (既有) |

---

## 🔧 常用操作

### 測試單個腳本

```bash
# 測試 PHP 語法檢查
bash ~/.claude/scripts/validate-php-syntax-edit.sh \
  /mnt/e/projects/zdpos_dev/domain/Services/SalesService.php

# 測試 Git 檢查
bash ~/.claude/scripts/pre-git-operations-check.sh \
  "git push origin main"

# 測試 Model 驗證
bash ~/.claude/scripts/validate-yii-model.sh \
  /mnt/e/projects/zdpos_dev/domain/Models/Order.php
```

### 驗證配置

```bash
# 驗證 JSON 格式
python3 -m json.tool ~/.claude/settings.json

# 查看所有 hooks
python3 -m json.tool ~/.claude/settings.json | grep -A 2 "command"

# 計算 hook 總數
python3 << 'EOF'
import json
with open('/home/paul/.claude/settings.json') as f:
    cfg = json.load(f)
    for phase in ['PreToolUse', 'PostToolUse', 'Stop']:
        count = sum(len(m['hooks']) for m in cfg['hooks'].get(phase, []))
        print(f"{phase}: {count} hooks")
EOF
```

### 添加新 hook

```bash
# 1. 創建腳本 (使用 heredoc 確保 LF)
cat > ~/.claude/scripts/my-hook.sh << 'EOF'
#!/bin/bash
FILE_PATH="$1"
# 你的邏輯
EOF

# 2. 設定執行權限
chmod +x ~/.claude/scripts/my-hook.sh

# 3. 測試
bash ~/.claude/scripts/my-hook.sh /test/path

# 4. 在 settings.json 中添加引用
# 編輯 ~/.claude/settings.json，在適當的 hooks 陣列中添加:
# {
#   "type": "command",
#   "command": "bash ~/.claude/scripts/my-hook.sh \"$filePath\"",
#   "statusMessage": "Running my hook...",
#   "async": true
# }

# 5. 驗證
python3 -m json.tool ~/.claude/settings.json > /dev/null && echo "✓ Valid"
```

---

## 🎯 Blocking vs Async

### Blocking (async: false) ⛔

執行在**主線程**，會**阻斷**後續操作。用於**關鍵檢查**。

- ❌ 當 hook 失敗時，停止編輯/命令
- ✅ 用於語法檢查、安全驗證
- ⚠️ 應快速完成 (< 500ms)

### Async (async: true) ✅

執行在**後台線程**，**不阻斷**主操作。用於**可選警告**。

- ✅ 即使失敗，也不影響編輯
- ✓ 用於信息性檢查、警告
- ✓ 可以耗時 (< 5s)

---

## 📂 檔案大小

| 檔案 | 大小 |
|------|------|
| pre-git-operations-check.sh | 252B |
| check-docker-container.sh | 263B |
| validate-php-syntax.sh | 160B |
| validate-php-syntax-edit.sh | 283B |
| check-php56-compatibility.sh | 316B |
| scan-hardcoded-secrets.sh | 308B |
| check-security-vulnerabilities.sh | 340B |
| validate-yii-controller.sh | 265B |
| validate-yii-model.sh | 380B |
| git-status-summary.sh | 186B |
| docker-environment-status.sh | 214B |
| **總計** | **3.0 KB** |

---

## 🌍 環境變量

### 當前路徑

```json
"command": "bash ~/.claude/scripts/script.sh \"$filePath\""
```

### 可選：使用環境變量

```bash
# 設定環境變量
export CLAUDE_HOME="$HOME/.claude"

# 修改 settings.json
"command": "bash $CLAUDE_HOME/scripts/script.sh \"$filePath\""
```

---

## ⚠️ 常見問題

| 問題 | 解決方案 |
|------|---------|
| Hook 不執行 | 檢查 shebang + 執行權限 + 行結束符 |
| JSON 錯誤 | `python3 -m json.tool ~/.claude/settings.json` |
| 路徑問題 | 確認 `~` 正確展開，或使用 `$CLAUDE_HOME` |
| 腳本超時 | 調整 `timeout` 值，或改為 `async: true` |
| 假陽性警告 | 編輯腳本 grep 正則表達式 |

---

## 📞 相關資源

| 資源 | 說明 |
|------|------|
| `README.md` | 腳本清單與詳細說明 |
| `CONFIGURATION.md` | 配置指南與最佳實踐 |
| `REFACTORING-SUMMARY.md` | 重構背景與計劃 |
| `~/.claude/settings.json` | Hooks 主配置文件 |
| `~/.claude/hooks/` | 舊文檔與 pre-commit-validation.sh |

---

**版本**: 1.0 | **更新**: 2026-02-25
