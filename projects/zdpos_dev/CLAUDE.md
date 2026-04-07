# Project Context: zdpos_dev

> 本檔為常駐規範（always-on），供所有 AI 使用。Claude Code 專屬執行策略見 `.claude/rules/`。

## Rule Priority
1. System/Platform constraints
2. User request in current turn
3. This document (`CLAUDE.md`)
4. `AGENTS.md`
5. Other docs (e.g. `GEMINI.md`)

## Communication Rules

- 回應語言：正體中文
- 程式註解：正體中文
- 專有名詞保留英文（Controller, Model, View, Action）
- 先給結論或建議，再補必要細節

## Core Engineering Rules

- 單一真相來源（SSOT）：延展既有邏輯，不重複造輪子。
- 先讀後寫：優先用 `rg`/`fd` 找既有模式再改。
- PHP 語法規則見 `~/.claude/rules/php/coding-style.md`

## Reference Index

| 主題 | 檔案 |
|------|------|
| 執行策略 / Agent 觸發 | `.claude/rules/execution-policy.md` |
| Agent 導覽（Codex） | `AGENTS.md` |
| 前端規則 | `.claude/rules/frontend.md` |
| Yii / DDD 框架參考 | `.claude/rules/php/yii-framework.md` |
| Filesystem / WSL 限制 | `.claude/rules/environment.md` |
| 層次在地規範 | `protected/CLAUDE.md`、`domain/CLAUDE.md`、`infrastructure/CLAUDE.md`、`js/CLAUDE.md` |
| EILogger | `.claude/docs/eilogger.md` |
| Yii 常數 | `.claude/docs/yii-constants.md` |
| 文件寫作規範 | `.claude/docs/docs-writing.md` |
| Page Service | `docs/page-service-pattern.md` |
| Compact 策略 | `.claude/docs/compact-strategy.md` |
