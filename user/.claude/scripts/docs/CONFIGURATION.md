# ⚙️ Hooks 配置指南

> 如何配置、自訂和擴展 Claude Code hooks

## 📌 基本概念

### Hooks 觸發點

```
PreToolUse  → 命令執行前 (git push 等)
PostToolUse → 編輯後 (Edit / Write 工具)
Stop        → 會話結束
```

### 執行方式

- **async: false** ⛔ - 阻斷式，用戶必須等待 (用於關鍵檢查)
- **async: true** ✅ - 背景執行，不影響主流程 (用於資訊性檢查)

---

## 🔧 當前配置

### settings.json 路徑更新

所有 hooks 現在引用 `~/.claude/scripts/hooks/`:

```json
{
  "type": "command",
  "command": "bash ~/.claude/scripts/hooks/validate-php-syntax-edit.sh \"$filePath\""
}
```

**注意**: 路徑已從 `~/.claude/hooks/` 更新為 `~/.claude/scripts/hooks/`

---

## 🎯 配置方案

### 方案 1: 最小設置 (推薦入門)

**特點**: 快速、輕量、主要檢查語法

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/hooks/validate-php-syntax-edit.sh \"$filePath\"",
            "timeout": 10,
            "statusMessage": "✓ Validating PHP syntax",
            "async": false
          }
        ]
      }
    ]
  }
}
```

**何時適用**:
- 新專案快速開始
- 驗證基本語法即可

---

### 方案 2: 安全導向 (推薦生產)

**特點**: 包含安全掃描和 PHP 5.6 檢查

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/hooks/validate-php-syntax-edit.sh \"$filePath\"",
            "timeout": 10,
            "async": false
          },
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/hooks/check-php56-compatibility.sh \"$filePath\"",
            "statusMessage": "Checking PHP 5.6",
            "async": true
          },
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/hooks/scan-hardcoded-secrets.sh \"$filePath\"",
            "statusMessage": "Scanning for secrets",
            "async": true
          },
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/hooks/check-security-vulnerabilities.sh \"$filePath\"",
            "statusMessage": "Checking vulnerabilities",
            "async": true
          }
        ]
      }
    ]
  }
}
```

**何時適用**:
- 生產環境
- 需要安全掃描

---

### 方案 3: 完整驗證 (推薦團隊)

**特點**: 包含所有 hooks + Yii 驗證

當前部署方案，已包含所有 12 個 hooks。

**何時適用**:
- 團隊協作
- 高品質要求

---

## 🚀 新增或修改 Hook

### 新增自訂 Hook

#### Step 1: 建立腳本

```bash
cat > ~/.claude/scripts/hooks/my-custom-check.sh << 'EOF'
#!/bin/bash
FILE_PATH="$1"

if [[ "$FILE_PATH" == *.php ]]; then
  # 你的邏輯
  if grep -E "TODO|FIXME" "$FILE_PATH"; then
    echo "⚠️  Found TODO/FIXME comments"
  fi || true
fi
EOF

chmod +x ~/.claude/scripts/hooks/my-custom-check.sh
```

#### Step 2: 測試腳本

```bash
bash ~/.claude/scripts/hooks/my-custom-check.sh /path/to/file.php
```

#### Step 3: 在 settings.json 添加引用

編輯 `~/.claude/settings.json`，在適當的 `hooks` 陣列中添加：

```json
{
  "type": "command",
  "command": "bash ~/.claude/scripts/hooks/my-custom-check.sh \"$filePath\"",
  "statusMessage": "Checking TODO/FIXME...",
  "async": true
}
```

#### Step 4: 驗證

```bash
python3 -m json.tool ~/.claude/settings.json > /dev/null && echo "✓ JSON valid"
```

---

## 🔍 參數說明

| 參數 | 說明 | 示例 |
|------|------|------|
| `type` | Hook 類型 | `command` |
| `command` | 執行命令 | `bash ~/.claude/scripts/hooks/validate.sh` |
| `timeout` | 超時秒數 | `5`, `10`, `30` |
| `statusMessage` | 執行訊息 | `"檢查..."` |
| `async` | 非同步執行 | `true` / `false` |
| `matcher` | 觸發工具 | `Bash`, `Edit`, `Write` |

---

## 🔄 Hook 執行流程

### Edit (編輯 PHP 檔案)

```
Edit file.php
    ↓
① validate-php-syntax-edit.sh (blocking)
    ↓ (失敗則停止)
② check-php56-compatibility.sh (async)
③ scan-hardcoded-secrets.sh (async)
④ check-security-vulnerabilities.sh (async)
⑤ validate-yii-controller.sh (async)
⑥ validate-yii-model.sh (async)
    ↓
編輯完成
```

### Stop (會話結束)

```
Session ends
    ↓
① git-status-summary.sh (async)
② docker-environment-status.sh (async)
③ pre-commit-validation.sh (async)
    ↓
會話終止
```

---

## 🐛 調試 Hooks

### 測試單個 Hook

```bash
# 手動執行
bash ~/.claude/scripts/hooks/validate-php-syntax-edit.sh /path/to/file.php

# 檢查退出碼
echo $?  # 0 = 成功, 1 = 失敗
```

### 驗證配置

```bash
# 檢查 JSON 格式
python3 -m json.tool ~/.claude/settings.json

# 統計 hooks 數量
grep -c '"command"' ~/.claude/settings.json

# 查看路徑是否正確
grep 'scripts/hooks' ~/.claude/settings.json | wc -l
```

---

## ⚙️ 性能優化

### Blocking Hooks 應快速完成

```json
{
  "command": "bash ~/.claude/scripts/hooks/my-hook.sh \"$filePath\"",
  "timeout": 10,      ← 根據實際調整 (秒數)
  "async": false      ← blocking 用於關鍵檢查
}
```

### 預期執行時間

| Hook | 時間 |
|------|------|
| validate-php-syntax-edit.sh | ~500ms |
| check-php56-compatibility.sh | ~200ms |
| scan-hardcoded-secrets.sh | ~100ms |
| check-security-vulnerabilities.sh | ~150ms |
| validate-yii-*.sh | ~100ms each |

---

## 📝 最佳實踐

1. **Keep Scripts Small** - 單一職責，快速完成
2. **Use Async for Non-Critical** - 語法檢查 blocking，警告改 async
3. **Fail Fast** - 關鍵檢查遇錯即停
4. **Document Changes** - 更新 MEMORY.md
5. **Test Before Deploy** - 手動驗證後再啟用

---

## 🔗 相關資源

- `README.md` - Hooks 清單和說明
- `QUICK-REFERENCE.md` - 快速查詢卡片
- `UTILITIES.md` - 工具腳本說明
- `~/.claude/settings.json` - 主配置文件

---

**最後更新**: 2026-02-25 | **版本**: 2.1 (整合版)
