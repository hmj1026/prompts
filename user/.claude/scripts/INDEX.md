# 📚 Claude Code Scripts 目錄索引

> **統一管理中心** - 所有 hooks、utilities 和文檔都在此目錄下

## 📂 目錄結構

```
~/.claude/scripts/
├── hooks/              ← 12 個 Claude Code hooks 腳本
├── utils/              ← 5 個 實用工具腳本
├── docs/               ← 完整文檔集
└── INDEX.md            ← 本文件
```

---

## 🎯 快速導覽

### 1️⃣ Hooks 腳本 (12 個) - `hooks/`

**觸發點**:
- **PreToolUse** (命令執行前) - 2 個
- **PostToolUse** (編輯後) - 7 個
- **Stop** (會話結束) - 3 個

**快速查看**:
```bash
ls -lah ~/.claude/scripts/hooks/
cat ~/.claude/scripts/docs/README.md          # 詳細清單
cat ~/.claude/scripts/docs/QUICK-REFERENCE.md # 快速查詢
```

### 2️⃣ Utility 腳本 (5 個) - `utils/`

**用途**:
- `check-dependencies.sh` - 檢查依賴安裝狀態
- `verify-setup.sh` - 驗證 Claude Code 配置
- `run-phpunit-tests.sh` - 執行單元測試
- `phpstan-analysis.sh` - PHPStan 靜態分析
- `php-code-style-check.sh` - PHP 代碼風格檢查

**使用**:
```bash
bash ~/.claude/scripts/utils/check-dependencies.sh
bash ~/.claude/scripts/utils/verify-setup.sh
```

### 3️⃣ 文檔 (5 個) - `docs/`

| 文檔 | 用途 |
|------|------|
| `README.md` | Hooks 清單與說明 ⭐ |
| `CONFIGURATION.md` | 詳細配置指南 |
| `QUICK-REFERENCE.md` | 快速查詢卡片 |
| `UTILITIES.md` | 工具腳本說明 ⭐ (新) |
| `REFACTORING-SUMMARY.md` | 重構背景與計劃 |

**已整合/刪除的過期檔案**:
- ✗ ADVANCED-CONFIG.md (整合到 CONFIGURATION.md)
- ✗ QUICKSTART.md (整合到 README.md)
- ✗ DEPENDENCY-*.md (過期運行報告)
- ✗ INSTALLATION-COMPLETE.md (過期運行報告)
- ✗ INSTALL-MISSING-DEPENDENCIES.md (使用 utils/check-dependencies.sh)

---

## 🔗 配置參考

### settings.json 路徑

所有 hooks 現在引用 `~/.claude/scripts/hooks/`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "command": "bash ~/.claude/scripts/hooks/pre-git-operations-check.sh \"$command\""
    }],
    "PostToolUse": [{
      "command": "bash ~/.claude/scripts/hooks/validate-php-syntax-edit.sh \"$filePath\""
    }],
    "Stop": [{
      "command": "bash ~/.claude/scripts/hooks/git-status-summary.sh"
    }]
  }
}
```

### 驗證配置

```bash
# 驗證 JSON 格式
python3 -m json.tool ~/.claude/settings.json

# 計數 hooks
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

## 🚀 常用操作

### 查看單個腳本說明

```bash
# 查看 hooks 清單
cat ~/.claude/scripts/docs/README.md

# 快速查詢卡片
cat ~/.claude/scripts/docs/QUICK-REFERENCE.md

# 詳細配置指南
cat ~/.claude/scripts/docs/CONFIGURATION.md
```

### 測試腳本

```bash
# 測試 hook 腳本
bash ~/.claude/scripts/hooks/validate-php-syntax-edit.sh /path/to/file.php

# 測試 utility 腳本
bash ~/.claude/scripts/utils/check-dependencies.sh
bash ~/.claude/scripts/utils/verify-setup.sh
```

### 添加新腳本

#### 新增 Hook

```bash
# 1. 創建腳本
cat > ~/.claude/scripts/hooks/my-hook.sh << 'EOF'
#!/bin/bash
FILE_PATH="$1"
# 邏輯
EOF

chmod +x ~/.claude/scripts/hooks/my-hook.sh

# 2. 更新 settings.json
# 編輯 ~/.claude/settings.json，添加到適當的 hooks 陣列

# 3. 驗證
python3 -m json.tool ~/.claude/settings.json > /dev/null && echo "✓ OK"
```

#### 新增 Utility

```bash
# 1. 創建腳本
cat > ~/.claude/scripts/utils/my-util.sh << 'EOF'
#!/bin/bash
# 邏輯
EOF

chmod +x ~/.claude/scripts/utils/my-util.sh

# 2. 測試
bash ~/.claude/scripts/utils/my-util.sh
```

---

## 📋 Scripts 內容速查

### hooks/ 目錄

```
PreToolUse (2):
  ├─ pre-git-operations-check.sh       (Git 安全)
  └─ check-docker-container.sh         (Docker 檢查)

PostToolUse (7):
  ├─ validate-php-syntax.sh            (Write: 語法)
  ├─ validate-php-syntax-edit.sh       (Edit: 語法, blocking)
  ├─ check-php56-compatibility.sh      (Edit: PHP 5.6)
  ├─ scan-hardcoded-secrets.sh         (Edit: 密鑰)
  ├─ check-security-vulnerabilities.sh (Edit: SQL 注入)
  ├─ validate-yii-controller.sh        (Edit: Controller)
  └─ validate-yii-model.sh             (Edit: Model)

Stop (3):
  ├─ git-status-summary.sh             (Git 狀態)
  ├─ docker-environment-status.sh      (Docker 狀態)
  └─ pre-commit-validation.sh          (詳細驗證)
```

### utils/ 目錄

```
工具腳本 (5):
  ├─ check-dependencies.sh    (檢查 PHP、PHPUnit 等)
  ├─ verify-setup.sh          (驗證設置完整性)
  ├─ run-phpunit-tests.sh     (運行 PHPUnit)
  ├─ phpstan-analysis.sh      (PHPStan 分析)
  └─ php-code-style-check.sh  (PHP 代碼風格)
```

---

## 🔍 故障排除

| 問題 | 解決方案 |
|------|---------|
| Hook 不執行 | 檢查 `~/.claude/settings.json` 中的路徑是否指向 `hooks/` |
| 腳本執行錯誤 | 確認腳本可執行: `chmod +x ~/.claude/scripts/{hooks,utils}/*.sh` |
| 路徑錯誤 | 檢查 `~` 是否正確展開，使用 `echo ~` 驗證 |
| JSON 驗證失敗 | 執行 `python3 -m json.tool ~/.claude/settings.json` |

---

## 📊 統計信息

- **Hooks 腳本**: 12 個 (PreToolUse: 2, PostToolUse: 7, Stop: 3)
- **Utility 腳本**: 5 個
- **文檔**: 10 個
- **總大小**: ~188K
- **組織**: 分層清晰，易於維護

---

## 🗂️ 備用目錄

**`~/.claude/hooks/`** 現已清空，作為備用目錄保留。

遷移完成，所有內容已統一到 `~/.claude/scripts/`。

---

## 📌 相關文件

| 位置 | 說明 |
|------|------|
| `~/.claude/settings.json` | Hooks 主配置 (已更新) |
| `~/.claude/scripts/hooks/` | 12 個 hook 腳本 |
| `~/.claude/scripts/utils/` | 5 個工具腳本 |
| `~/.claude/scripts/docs/` | 10 個文檔 |
| `~/.claude/projects/-mnt-e-projects-zdpos-dev/memory/MEMORY.md` | 項目記憶 (已更新) |

---

**最後更新**: 2026-02-25
**版本**: 2.0 (統一管理版本)
**狀態**: ✅ 完全遷移
