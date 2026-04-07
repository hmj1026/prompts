# Slash Command Quick Reference

## Review 指令選擇指南

| 場景 | 指令 | 差異 |
|------|------|------|
| PR 前快速檢查（diff only） | `/codex-review-fast` | 最快，只看 diff |
| 正式 PR 審查（含 lint+build） | `/codex-review` | 完整，含 lint 修正 |
| 整條 branch 審查 | `/codex-review-branch` | 全量 diff |
| 需要讀全專案才能判斷 | `/codex-cli-review` | Codex CLI 全磁碟存取 |
| 文件（.md）審查 | `/codex-review-doc` | 非程式碼 |

## 探索/設計指令選擇

| 場景 | 指令 |
|------|------|
| 程式碼追蹤、理解架構 | `/code-explore` (快) 或 `/code-investigate` (深) |
| 對立觀點腦力激盪（Codex） | `/codex-brainstorm` |
| 架構/設計諮詢 | `/codex-architect` |

## 完整指令表

| Command | Description | When |
|---------|-------------|------|
| `/code-explore` | Code exploration | 快速理解 |
| `/code-investigate` | Dual-perspective investigation | 深度分析 |
| `/git-investigate` | Track code history | 追蹤歷史 |
| `/git-worktree` | Manage git worktrees | 平行開發 |
| `/issue-analyze` | Issue deep analysis | 根因分析 |
| `/repo-intake` | One-time project scan | 初次 onboarding |
| `/codex-brainstorm` | Adversarial brainstorm (Codex) | 方案探索 |
| `/codex-review-fast` | Quick review (diff) | **PR 必跑** |
| `/codex-review` | Full review (lint+build) | 正式 PR |
| `/codex-review-branch` | Full branch review | 大型 PR |
| `/codex-cli-review` | CLI review (full disk) | 深度審查 |
| `/codex-review-doc` | Review .md files | 文件變更 |
| `/codex-explain` | Explain complex code | 理解程式碼 |
| `/codex-architect` | Architecture consulting | 設計決策 |
| `/codex-implement` | Codex-driven implementation | Codex 寫碼 |
| `/codex-security` | OWASP Top 10 | 安全敏感 |
| `/codex-test-gen` | Generate unit tests | 補測試 |
| `/codex-test-review` | Review test coverage | **PR 必跑** |
| `/check-coverage` | Test coverage analysis | 品質檢查 |
| `/doc-refactor` | Simplify documents | 文件精簡 |
| `/create-skill` | Create new skills | 工具 |
| `/simplify` | Code simplification | 重構 |
| `/de-ai-flavor` | Remove AI artifacts | 文件清理 |
| `/claude-health` | Claude Code config health | 環境健檢 |
| `/smart-commit` | Smart batch commit | Git |
| `/gemini-commit` | Delegate to gemini-cli | Git |
| `/opsx:new` | Start new OpenSpec change | 新功能/Bug fix |
| `/opsx:continue` | Continue OpenSpec change | 接續規劃 |
| `/opsx:apply` | Implement OpenSpec tasks | 開始實作 |
| `/opsx:verify` | Verify implementation | 驗證 |
| `/opsx:sync` | Sync delta specs | 歸檔前同步 |
| `/opsx:archive` | Archive completed change | 歸檔 |
