# Project Context: zdpos_dev

> 本檔為常駐規範（always-on），供所有 AI 使用。Claude Code 專屬執行策略見 `.claude/rules/`。

## Rule Priority
1. System/Platform constraints
2. User request in current turn
3. This document (`CLAUDE.md`)
4. `AGENTS.md`
5. Other docs (e.g. `GEMINI.md`)

## Available Agents

**專案專屬**（Claude Code: `.claude/agents/` / Codex CLI: `.codex/agents/`）：

| Agent | 檔案 | Purpose |
|-------|------|---------|
| code-reviewer | `code-reviewer.md` | Code review（品質、安全、回歸風險）|
| tdd-guide-zdpos_dev | `tdd-guide-zdpos_dev.md` | TDD for PHP 5.6 + PHPUnit 5.7（含 strcasecmp、assertInternalType 等陷阱）|
| database-reviewer-mysql | `database-reviewer-mysql.md` | MySQL 5.7 query review |
| security-reviewer-zdpos_dev | `security-reviewer-zdpos_dev.md` | PHP/Yii security analysis |
| architect-zdpos_dev | `architect-zdpos_dev.md` | zdpos DDD system design |
| refactor-cleaner-zdpos_dev | `refactor-cleaner-zdpos_dev.md` | Dead code cleanup |

**通用備援**（Claude Code: `~/.claude/agents/` / Codex CLI: `~/.codex/agents/`）— 含 `bug-investigator`（root cause analysis）

---

## Planning Protocol (Conditional)

> **Claude Code 環境**：以 `.claude/rules/execution-policy.md` 為準，本節為通用 AI（Gemini 等）的備援說明。

僅在下列情況，先提出計畫並等待使用者回覆 `Go`：
1. 新功能或新能力（含：新增事件監聽、新 API 端點、新物件/方法、新頁面行為）
2. Breaking change
3. 跨 2 個以上模組且含介面/契約調整
4. 高風險資料遷移、安全/權限核心邏輯變更

其餘任務直接執行，回報關鍵檢查點即可。

## Communication Rules

- 回應語言：正體中文
- 程式註解：正體中文
- 專有名詞保留英文（Controller, Model, View, Action）
- 先給結論或建議，再補必要細節

## Core Engineering Rules

- 單一真相來源（SSOT）：延展既有邏輯，不重複造輪子。
- 先讀後寫：優先用 `rg`/`fd` 找既有模式再改。
- PHP 語法規則見 `~/.claude/rules/php/coding-style.md`

## Environment Constraints

- 架構：Yii 1.1 + DDD-like 分層 | PHP 5.6.40 | DB：`zdpos_dev_2`（MySQL 5.7.33）
- 前端：Legacy POS（Raw ES6, no build step）| 本機：`https://www.posdev.test/dev3`

## Reference Index

| 主題 | 檔案 |
|------|------|
| 執行策略 / Agent 觸發 | `.claude/rules/execution-policy.md` |
| 前端規則 | `.claude/rules/frontend.md` |
| Yii / DDD 框架參考 | `.claude/rules/php/yii-framework.md` |
| Filesystem / WSL 限制 | `.claude/rules/environment.md` |
| Prompt / 架構長文 | `docs/prompt-reference.md` |
| 層次在地規範（Claude Code 可見） | `protected/CLAUDE.md`、`domain/CLAUDE.md`、`infrastructure/CLAUDE.md`、`js/CLAUDE.md` |
| 完整 slash command 列表 | `.claude/docs/commands.md`（按需查閱） |
| EILogger 使用要點 | `.claude/docs/eilogger.md`（按需查閱） |
| Yii 常數查閱表 | `.claude/docs/yii-constants.md`（按需查閱） |
| 文件寫作規範 | `.claude/docs/docs-writing.md`（按需查閱） |
