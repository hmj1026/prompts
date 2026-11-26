---
status: accepted
---

# ZDPOS 技能整併與三層邊界

`projects/zdpos-217/.agents/skills/` 過去因各自演進而累積薄轉發包裝、單條規則微型技能與未清理的評測工作區，同時 `.claude/skills/` 仍殘留過期的逐支符號連結，造成跨 Agent（Claude Code、Codex、Antigravity、Cursor）觸發雜訊與維護漂移。

我們決定將 `zdpos-*` 技能收斂為高內聚的 **Canonical Source** 集合（16 目錄收斂為 10 支 **Skill**），以「**Skill** 承載跨 Agent 工作流／工具包／高內聚技術手冊、**Rule** 維持常駐底線、**Reference**／**Guide** 漸進載入細節」作為邊界，並完全停用 `projects/zdpos-217/.claude/skills/` 的逐支 `zdpos-*` 符號連結維護，統一由 `.agents/skills/` 投影。

## Considered Options

- **維持單條規則獨立微型 Skill 與薄轉發別名**：觸發單純，但每支常駐 `description` 持續消耗所有 Agent 的 context load，且重複維護薄包裝與多處符號連結。
- **將所有規範全數併入 `.claude/rules/`**：減少 skill 數量，但 Codex、Antigravity、Cursor 不自動載入 `.claude/rules/`，且會膨脹 Claude Code 每次編輯的常駐脈絡。

## Consequences

- 新增單一 PHP/JS 微型慣例時，併入既有領域 **Skill**（`zdpos-php-patterns`、`zdpos-js-modernization`）或其 `references/`，不另開新 **Skill**。
- 刪除或更名 **Skill** 時，需同步更新 `prompts` 內跨檔引用（`.claude/rules/`、`.claude/manifests/`、各 `SKILL.md`）與目標專案／本機 Agent 環境的殘留 **Projection** 符號連結。
