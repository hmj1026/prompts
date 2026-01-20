# AI Prompt & Context Repository

集中管理 AI Agent 設定的中央儲存庫，支援用戶級別（全域）與專案級別的 skills、workflows、rules，透過 symlink 部署到目標位置。

## 📂 目錄結構

```
prompts/
├── user/                           # 用戶級別 (全域)
│   ├── .gemini/                    
│   │   ├── GEMINI.md               # 用戶全域指引
│   │   └── antigravity/                 
│   │       ├── skills/             # 全域 skills
│   │       └── global_workflows/   # 全域 workflows
│   ├── .claude/                    
│   │   ├── CLAUDE.md
│   │   └── .agent/
│   └── .codex/
├── projects/                       # 專案級別
│   └── myproject/
│       ├── GEMINI.md               # 專案專屬指引
│       ├── CLAUDE.md
│       ├── AGENTS.md
│       └── .agent/                 
│           ├── skills/             # 專案專屬 skills
│           ├── workflows/
│           └── rules/
├── scripts/
│   ├── deploy.sh                   # Bash 部署腳本
│   └── deploy.ps1                  # PowerShell 部署腳本
├── .env.example                    # 環境變數範本
└── README.md
```

## 🚀 快速開始

### 1. 設定環境變數

```bash
cp .env.example .env
# 編輯 .env 設定您的路徑
```

### 2. 部署到用戶目錄（全域）

```bash
# Bash (Linux/macOS/WSL)
./scripts/deploy.sh --user

# PowerShell (Windows)
.\scripts\deploy.ps1 -User
```

### 3. 部署到專案目錄

```bash
# Bash
./scripts/deploy.sh --project zdpos_dev

# PowerShell
.\scripts\deploy.ps1 -Project zdpos_dev
```

### 4. 強制覆蓋既有連結

```bash
./scripts/deploy.sh --user --force
.\scripts\deploy.ps1 -User -Force
```

## 📋 層級說明

| 層級 | 位置 | 用途 |
|------|------|------|
| **用戶級別 (全域)** | `user/.gemini/.agent/` | 所有專案共用的預設資源 |
| **專案級別** | `projects/<name>/.agent/` | 特定專案專屬資源 |

### 優先順序

當同名資源存在於多個層級時，**專案級別** > **用戶級別**。

## 📦 包含的 Skills

| Skill | 說明 |
|-------|------|
| `software-architecture` | 軟體架構設計指引 |
| `test-driven-development` | TDD 開發流程 |
| `prompt-engineering` | Prompt 工程最佳實踐 |
| `frontend-design` | 前端設計指引 |
| `create-openspec-proposal` | OpenSpec 提案建立 |
| `brainstorming` | 創意發想流程 |
| `subagent-driven-development` | 子代理開發模式 |
| `ui-ux-pro-max` | UI/UX 進階設計 |

## 📦 包含的 Workflows

| Workflow | 說明 |
|----------|------|
| `openspec-proposal.md` | 建立 OpenSpec 提案 |
| `openspec-apply.md` | 執行 OpenSpec 變更 |
| `openspec-archive.md` | 歸檔 OpenSpec 變更 |
| `ui-ux-pro-max.md` | UI/UX 設計工作流程 |

## 🔧 新增專案

1. 在 `.env` 新增專案路徑：
   ```bash
   PROJECT_myproject="E:/projects/myproject"
   ```

2. 建立專案設定目錄：
   ```bash
   mkdir -p projects/myproject/.agent/{skills,workflows,rules}
   ```

3. 部署：
   ```bash
   ./scripts/deploy.sh --project myproject
   ```

## 📝 注意事項

- **Windows**: 建立 symlink 需要管理員權限或啟用開發者模式
- **路徑格式**: `.env` 中使用正斜線 `/`，腳本會自動處理
- **Git**: symlink 目標檔案不會被追蹤，只有此儲存庫中的來源檔案

## 📄 License

MIT
