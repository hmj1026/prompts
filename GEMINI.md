# AI Prompt & Context Repository

## Overview

集中管理 AI Agent 設定的中央儲存庫，支援用戶級別（全域）與專案級別的 rules、skills、hooks、agents，透過 symlink 部署到目標位置。

## Directory Structure

### `user/`
全域用戶級別設定，適用於所有專案。

*   `.gemini/` — Gemini 全域指引、skills、workflows
*   `.claude/` — Claude 全域指引、rules、hooks、commands
*   `.codex/` — Codex 全域指引、skills

### `lib/`
跨專案共用資源庫。

*   `skills/` — 共用 skills (OpenSpec, bug-investigation, software-architecture 等)
*   `commands/` — 共用 commands (opsx/)
*   `rules/` — 語言規則模板 (php/, python/, typescript/, golang/)

### `projects/`
專案級別設定。每個子目錄對應一個開發專案。

*   `zdpos_dev/` — PHP/Yii 1.1 POS 系統 (完全管理)
*   `ccas/` — Python/TypeScript 信用卡系統 (自管理)
*   `docker_run/` — Docker 開發環境 (自管理)
*   `line-bot/` — Laravel/LINE Bot (完全管理)

### `deploy/`
部署工具。

*   `deploy.sh` — Symlink 部署腳本
*   `manifest.yaml` — 宣告式部署清單

## Three-Layer Architecture

```
user/          全域基底 (common rules, dispatchers, commands)
  |
lib/           共享庫 (skills, commands, language rule templates)
  |
projects/      專案特定 (agents, execution-policy, project rules)
```

當同名資源存在於多個層級時，**專案級別** > **用戶級別**。

## Usage Guidelines

1. **Context Loading**: Agent 開始工作時，先讀取 `projects/<project_name>/` 中的對應設定檔。
2. **Global Rules**: `user/` 中的設定為基線規則。專案設定在衝突時覆蓋全域規則。
3. **Shared Resources**: 共用 skills/commands 從 `lib/` 透過 symlink 部署到各專案。

## Deployment

```bash
# 部署全域設定
./deploy/deploy.sh user

# 部署專案設定
./deploy/deploy.sh project zdpos_dev

# 部署共享資源到自管理專案
./deploy/deploy.sh lib ccas

# 檢查同步狀態
./deploy/deploy.sh --check all
```

## Conventions

*   **File Naming**: `GEMINI.md`, `CLAUDE.md`, `AGENTS.md`
*   **Language**: 預設溝通語言為正體中文
*   **Symlinks**: 部署建立 symlink，不複製檔案，維持單一真實來源
