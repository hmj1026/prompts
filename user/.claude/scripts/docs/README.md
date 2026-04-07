# 📘 Claude Code Hooks Scripts 完整指南

> 統一管理的 Claude Code hooks、utilities 和配置

## 🎯 快速概覽

**現狀**: ✅ 所有 hooks 已配置並正常運行！

### 目前已啟用的功能

#### ✅ 編輯 PHP 檔案時 (PostToolUse)

| 檢查項目 | 狀態 | 速度 |
|---------|------|------|
| **PHP 語法驗證** | ⛔ Blocking | ~0.5s |
| PHP 5.6 兼容性 | ⚠️ 警告 | ~0.2s |
| 硬編碼密鑰掃描 | ⚠️ 警告 | ~0.1s |
| SQL 注入檢查 | ⚠️ 警告 | ~0.1s |
| Yii 結構驗證 | ⚠️ 警告 | ~0.1s |

#### ⚡ 會話結束時 (Stop)

- **Git 狀態摘要** - 顯示變更檔案
- **Docker 環境狀態** - 檢查容器
- **完整預提交驗證** - 最終檢查

#### 🔔 Git 操作前 (PreToolUse)

- **Git 安全檢查** - 確認危險操作
- **Docker 容器檢查** - 驗證 pos_php 運行

---

## 📂 目錄結構

```
~/.claude/scripts/
├── INDEX.md                  ← 統一入口
├── hooks/                    ← 12 個 hook 腳本
│  ├── 2 個 PreToolUse
│  ├── 7 個 PostToolUse
│  └── 3 個 Stop
├── utils/                    ← 5 個工具腳本
└── docs/
   ├── README.md             ← 本檔案
   ├── CONFIGURATION.md      ← 配置參考
   ├── QUICK-REFERENCE.md    ← 速查表
   ├── REFACTORING-SUMMARY.md ← 歷史記錄
   └── UTILITIES.md          ← 工具腳本說明
```

---

## 🔍 Hooks 腳本清單

### PreToolUse (命令執行前)

#### 1. `pre-git-operations-check.sh`
**觸發**: git push, commit, rebase, reset, clean
```
🔔 Git 操作安全檢查
指令: git push origin main
確認操作無誤再繼續
```

#### 2. `check-docker-container.sh`
**觸發**: docker, mysql 命令
```
⚠️  WARNING: Docker PHP 容器 (pos_php) 未運行
```

### PostToolUse (編輯後檢查)

#### Write 操作 (新增/複製 PHP 檔案)

3. `validate-php-syntax.sh` (async)
   - 檢查 PHP 語法
   - 非阻斷

#### Edit 操作 (編輯 PHP 檔案)

4. `validate-php-syntax-edit.sh` (blocking) ⛔
   - **關鍵**: 此 hook 會阻斷錯誤
   - 檢查 PHP 語法
   - 如果有 Parse error，停止編輯

5. `check-php56-compatibility.sh` (async)
   - 檢查 PHP 7+ 語法
   - 警告: 類型提示、null coalescing、返回類型

6. `scan-hardcoded-secrets.sh` (async)
   - 掃描密鑰字符串
   - 警告: password=, api_key=, token= 等

7. `check-security-vulnerabilities.sh` (async)
   - 掃描 SQL 注入模式
   - 警告: 直接 $var 拼接、$_GET/$_POST 存取

8. `validate-yii-controller.sh` (async)
   - 驗證 Controller 檔案
   - 檢查是否繼承 Controller 類

9. `validate-yii-model.sh` (async)
   - 驗證 Model 檔案
   - 檢查 CActiveRecord 繼承和 model() 方法

### Stop (會話結束)

10. `git-status-summary.sh` (async)
    - 顯示工作目錄變更 (前 20 項)

11. `docker-environment-status.sh` (async)
    - 顯示 Docker 容器狀態表

12. `pre-commit-validation.sh` (async)
    - 執行完整的預提交驗證
    - 檢查: PHP 語法、密鑰、SQL 注入、PHP 5.6

---

## 🚀 常用操作

### 查看詳細資訊

```bash
# 統一索引
cat ~/.claude/scripts/INDEX.md

# 快速查詢卡片
cat ~/.claude/scripts/docs/QUICK-REFERENCE.md

# 配置參考
cat ~/.claude/scripts/docs/CONFIGURATION.md

# 工具腳本說明
cat ~/.claude/scripts/docs/UTILITIES.md
```

### 測試腳本

```bash
# 測試 PHP 語法檢查
bash ~/.claude/scripts/hooks/validate-php-syntax-edit.sh /path/to/file.php

# 測試 Git 檢查
bash ~/.claude/scripts/hooks/pre-git-operations-check.sh "git push origin main"

# 驗證設置
bash ~/.claude/scripts/utils/verify-setup.sh

# 檢查依賴
bash ~/.claude/scripts/utils/check-dependencies.sh
```

### 驗證配置

```bash
# 驗證 settings.json
python3 -m json.tool ~/.claude/settings.json | head -30

# 計算 hooks 總數
python3 << 'EOF'
import json
with open('/home/paul/.claude/settings.json') as f:
    cfg = json.load(f)
    for phase in ['PreToolUse', 'PostToolUse', 'Stop']:
        count = sum(len(m['hooks']) for m in cfg['hooks'].get(phase, []))
        print(f"{phase}: {count} hooks")
EOF
```

---

## 🎯 範例: 編輯 PHP 檔案時會看到什麼

### 正常編輯 (無錯誤)

```
✅ Validating PHP syntax...
⚠️  Checking PHP 5.6 compatibility...
🔐 Scanning for hardcoded secrets...
🔍 Checking for security vulnerabilities...
```

### 語法錯誤時 ⛔

```
❌ PHP Syntax Error detected
Parse error: syntax error, unexpected '?' in Order.php on line 42
```

### 安全警告時

```
⚠️  WARNING: Possible hardcoded secret detected
  Pattern: api_key = 'abc123def456...'

⚠️  WARNING: Found potential PHP 7+ syntax incompatible with PHP 5.6
  Found: ?? (null coalescing operator)
```

---

## 🔧 新增或修改 Hooks

### 新增 Hook

```bash
# 1. 建立腳本
cat > ~/.claude/scripts/hooks/my-hook.sh << 'EOF'
#!/bin/bash
FILE_PATH="$1"
# 邏輯
EOF

chmod +x ~/.claude/scripts/hooks/my-hook.sh

# 2. 測試腳本
bash ~/.claude/scripts/hooks/my-hook.sh /test/path.php

# 3. 在 settings.json 中添加
# {
#   "type": "command",
#   "command": "bash ~/.claude/scripts/hooks/my-hook.sh \"$filePath\"",
#   "statusMessage": "...",
#   "async": true
# }

# 4. 驗證
python3 -m json.tool ~/.claude/settings.json > /dev/null && echo "✓ OK"
```

### 修改現有 Hook

編輯腳本並測試：

```bash
nano ~/.claude/scripts/hooks/validate-php-syntax-edit.sh
bash ~/.claude/scripts/hooks/validate-php-syntax-edit.sh /test/file.php
```

---

## 📊 統計信息

| 項目 | 數量 |
|------|------|
| Hooks 腳本 | 12 |
| Utility 腳本 | 5 |
| 文檔 | 5 |
| 總大小 | ~45K |

---

## ❓ 常見問題

| 問題 | 解決方案 |
|------|---------|
| Hook 不執行 | 檢查 `~/.claude/settings.json` 中的路徑 |
| JSON 格式錯誤 | `python3 -m json.tool ~/.claude/settings.json` |
| 腳本執行失敗 | 確認路徑和執行權限: `chmod +x ~/.claude/scripts/hooks/*.sh` |
| 警告太多 | 在 settings.json 中將 `async` 設為 `true` 或移除該 hook |

---

## 🔗 相關資源

- `INDEX.md` - 統一索引入口
- `CONFIGURATION.md` - 詳細配置指南
- `QUICK-REFERENCE.md` - 快速查詢卡片
- `UTILITIES.md` - 工具腳本說明
- `REFACTORING-SUMMARY.md` - 重構歷史記錄
- `~/.claude/settings.json` - 主配置文件

---

**最後更新**: 2026-02-25 | **版本**: 2.1 (整合版)
