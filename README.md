# AI Prompt & Context Repository

集中管理 AI Agent 設定的中央儲存庫，支援用戶級別（全域）與專案級別的 rules、skills、hooks、agents，透過 symlink 部署到目標位置。

## 目錄結構

```
prompts/
├── user/                              # 用戶級別 (全域)
│   ├── .claude/
│   │   ├── CLAUDE.md                  # 全域指引
│   │   ├── CX.md                      # cx-cli 語義導覽工具指南
│   │   ├── settings.json              # Hooks (dispatcher pattern)
│   │   ├── commands/                  # 全域 slash commands
│   │   ├── rules/common/             # 語言無關規則 (8 files)
│   │   ├── rules-archive/            # 歸檔的語言規則 (參考用)
│   │   ├── agents/                   # Agent 模板庫 (不直接部署)
│   │   ├── scripts/hooks/            # Dispatcher + 語言特定 hooks
│   │   └── skills/                   # 全域 skills
│   ├── .codex/                       # Codex (OpenAI) 設定
│   └── .gemini/                      # Gemini (Google) 設定
│
├── lib/                               # 共享資源庫
│   ├── skills/                        # 跨專案共用 skills
│   │   ├── openspec-*/               # 10 個 OpenSpec skills
│   │   ├── bug-investigation/
│   │   ├── software-architecture/
│   │   └── git-smart-commit/
│   ├── commands/opsx/                 # OpenSpec commands
│   └── rules/                         # 語言規則模板
│       ├── php/
│       ├── python/
│       ├── typescript/
│       └── golang/
│
├── projects/                          # 專案級別
│   ├── zdpos_dev/                     # 完全管理 (PHP/Yii 1.1)
│   ├── ccas/                          # 自管理 (Python/TS)
│   ├── docker_run/                    # 自管理 (Docker)
│   └── line-bot/                      # 完全管理 (Laravel/LINE)
│
└── deploy/                            # 部署工具
    ├── deploy.sh                      # Symlink 部署腳本
    └── manifest.yaml                  # 宣告式部署清單
```

## 快速開始

```bash
# 檢查同步狀態
./deploy/deploy.sh --check all

# 部署到用戶目錄 (全域)
./deploy/deploy.sh user

# 部署特定專案
./deploy/deploy.sh project zdpos_dev

# 部署共享資源到自管理專案
./deploy/deploy.sh lib ccas

# 部署全部
./deploy/deploy.sh all

# 預覽 (不實際執行)
./deploy/deploy.sh --dry-run all
```

## 三層架構

```
user/          全域基底 (common rules, dispatchers, commands)
  |
lib/           共享庫 (skills, commands, language rule templates)
  |
projects/      專案特定 (agents, execution-policy, project rules)
```

### 層級優先順序

專案級別 > 用戶級別。同名資源以最靠近專案的層級為準。

### 專案管理模式

| 模式 | 說明 | 部署方式 |
|------|------|----------|
| **managed** | prompts repo 是 source of truth | `deploy.sh project <name>` |
| **self** | 專案自己的 git repo 管理 .claude/ | `deploy.sh lib <name>` (僅共享資源) |

## 注意事項

- **Symlink**: 部署建立 symlink，不複製檔案，維持單一真實來源
- **WSL**: 需啟用開發者模式或以管理員權限執行
- **Agent 模板**: `user/.claude/agents/` 是模板庫，不直接部署到 `~/.claude/agents/`
- **語言規則**: 語言特定規則在 `lib/rules/` 作為模板，部署到各專案 `.claude/rules/`

## License

MIT
