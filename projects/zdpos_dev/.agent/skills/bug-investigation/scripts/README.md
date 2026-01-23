# Bug Investigation Scripts

這個資料夾包含 Bug 調查時常用的輔助腳本和工具。所有腳本已通用化，可用於調查任何功能或資料表。

## 🚀 快速開始

### 1. 檢查必要工具

```bash
./check-tools.sh
```

此腳本會檢查以下專業工具是否已安裝，並提供安裝指引：

| 工具 | 用途 | 必要性 |
|------|------|--------|
| `ripgrep` (rg) | 程式碼搜尋 | ⭐⭐⭐ 必要 |
| `fd` | 檔案搜尋 | ⭐⭐ 建議 |
| `ast-grep` | AST 層級分析 | ⭐⭐ 建議 |
| `jq` | JSON 處理 | ⭐ 可選 |
| `yq` | YAML 處理 | ⭐ 可選 |

💡 **提示**：可請 AI 助手協助安裝缺少的工具。

### 2. 設定執行權限

```bash
chmod +x *.sh
```

---

## 📋 腳本列表

### 1. check-tools.sh ⚙️
**功能**: 檢查 Bug 調查所需的工具是否已安裝

**用法**:
```bash
./check-tools.sh
```

**輸出**:
- ✅ 已安裝的工具及版本
- ❌ 缺少的工具及安裝指引
- 📦 各平台的安裝命令

---

### 2. trace-data-flow.sh 🔍
**功能**: 追蹤任意變數的資料流（通用化）

**用法**:
```bash
./trace-data-flow.sh <variable_name> [search_path] [file_types]
```

**參數**:
- `variable_name`: 要追蹤的變數名稱（必要）
- `search_path`: 搜尋路徑（預設: `.`）
- `file_types`: 檔案類型（預設: `php,js,ts,jsx,tsx`）

**範例**:
```bash
# 追蹤特定變數
./trace-data-flow.sh <variable_name>

# 只在特定目錄搜尋
./trace-data-flow.sh <variable_name> <path/to/directory>

# 只搜尋特定類型檔案
./trace-data-flow.sh <variable_name> . php
```

**輸出**:
- 📍 變數賦值位置（寫入）
- 📍 變數讀取位置（讀取）
- 📍 函數參數（資料傳遞）

---

### 3. search-database-queries.sh 💾
**功能**: 搜尋程式碼中與特定資料表相關的 SQL 查詢（通用化）

**用法**:
```bash
./search-database-queries.sh <table_name> [search_path]
```

**範例**:
```bash
# 搜尋特定資料表相關查詢
./search-database-queries.sh <table_name>

# 只在特定目錄搜尋
./search-database-queries.sh <table_name> <path/to/directory>
```

**輸出**:
- 📍 SELECT 查詢
- 📍 INSERT 操作
- 📍 UPDATE 操作
- 📍 DELETE 操作

---

### 4. analyze-function-calls.sh 🔗
**功能**: 分析任意檔案中的函數呼叫關係

**用法**:
```bash
./analyze-function-calls.sh <file_path> [output_file]
```

**建議輸出路徑**: `docs/knowledge/[feature-name]/function-analysis.txt`

**範例**:
```bash
# 預設輸出到 docs/knowledge/
./analyze-function-calls.sh src/components/Checkout.js

# 指定輸出位置（建議放在 docs/knowledge/）
./analyze-function-calls.sh src/api/payment.php docs/knowledge/payment/function-calls.txt
```

**輸出**:
- 📍 函數定義列表
- 📍 函數呼叫頻率
- 📍 物件方法呼叫

💡 **提示**: 安裝 `ast-grep` 可獲得更精確的 AST 層級分析。

---

### 5. generate-flow-diagram.sh 📊
**功能**: 從任意函數生成 Mermaid 流程圖

**用法**:
```bash
./generate-flow-diagram.sh <function_name> <file_path> [output_file]
```

**建議輸出路徑**: `docs/knowledge/[feature-name]/diagrams/`

**範例**:
```bash
# 預設輸出到 docs/knowledge/
./generate-flow-diagram.sh processCheckout src/checkout.js

# 指定輸出位置（建議放在 docs/knowledge/）
./generate-flow-diagram.sh handlePayment src/payment.php docs/knowledge/payment/diagrams/flow.md
```

**輸出**: Mermaid 格式的流程圖（需手動調整以反映邏輯）

---

## 🎯 使用情境

### 情境 1: 調查資料不同步問題

```bash
# 1. 找出不一致的資料（使用 SQL 模板）

# 2. 追蹤關鍵變數
./trace-data-flow.sh orderStatus

# 3. 搜尋相關資料表操作
./search-database-queries.sh orders

# 4. 分析相關檔案（建議輸出到 docs/knowledge/）
./analyze-function-calls.sh src/OrderController.php docs/knowledge/orders/function-calls.txt

# 5. 生成流程圖（建議輸出到 docs/knowledge/）
./generate-flow-diagram.sh processOrder src/OrderController.php docs/knowledge/orders/diagrams/flow.md
```

### 情境 2: 理解新功能流程

```bash
# 1. 檢查工具
./check-tools.sh

# 2. 分析主要檔案（輸出到 docs/knowledge/）
./analyze-function-calls.sh src/feature.js docs/knowledge/feature/analysis.txt

# 3. 生成流程圖（輸出到 docs/knowledge/）
./generate-flow-diagram.sh mainFunction src/feature.js docs/knowledge/feature/diagrams/flow.md

# 4. 追蹤關鍵資料流
./trace-data-flow.sh featureData

---

## 🔧 工具安裝指引

### Windows (推薦使用 Scoop)

```powershell
# 安裝 Scoop (若未安裝)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# 安裝所有工具
scoop install ripgrep fd jq yq
npm install -g @ast-grep/cli
```

### macOS (使用 Homebrew)

```bash
brew install ripgrep fd jq yq ast-grep
```

### Linux (Debian/Ubuntu)

```bash
sudo apt install ripgrep fd-find jq
snap install yq
npm install -g @ast-grep/cli
```

---

## 💡 AI 助手協助

如果您希望 AI 助手幫忙安裝工具，可以說：

> "請幫我安裝 Bug 調查所需的工具（ripgrep, fd, ast-grep 等）"

AI 會根據您的作業系統執行適當的安裝命令。

---

## 📚 延伸閱讀

- [ripgrep 官方文檔](https://github.com/BurntSushi/ripgrep)
- [fd 官方文檔](https://github.com/sharkdp/fd)
- [ast-grep 官方文檔](https://ast-grep.github.io/)
- [jq 官方文檔](https://stedolan.github.io/jq/)
- [yq 官方文檔](https://mikefarah.gitbook.io/yq/)

---

## 🤝 貢獻

如果你開發了新的實用腳本，歡迎加入此目錄並更新 README。
