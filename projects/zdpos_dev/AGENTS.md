# AGENTS.md

本檔為代理入口與索引；唯一權威規範為 `CLAUDE.md`。

<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

---

## Priority
衝突時優先序（高 -> 低）：
1. 系統與平台限制（sandbox/權限/網路/OS）
2. 使用者本回合明確要求
3. `CLAUDE.md`
4. 本檔 `AGENTS.md`
5. 其他文件（例如 `GEMINI.md`，僅背景）

## Authority & Scope
- 規範、流程、測試、輸出格式：一律看 `CLAUDE.md`
- 本檔僅提供索引與觸發邊界，不定義實作細節
- 架構背景可參考 `GEMINI.md`，但不具規範效力

## Skill Source Policy
1. 優先使用專案內 skills（`./.codex/skills`、`./.agents/skills`）
2. 專案內不存在時，才 fallback 到 user-level skills
3. 同名 skill 只允許一個生效來源（以專案內為準）

## Skill Trigger Policy (Index Only)
- 使用者明確點名 skill：必用
- 未點名時：僅在「高信心匹配任務」時使用
- 多個 skill 命中：採最小集合，不強制全套流程
- 詳細觸發、例外與衝突處理請見 `CLAUDE.md`

## OpenSpec Trigger Boundary
需要 OpenSpec（任一符合）：
- 新功能/新能力
- Breaking change
- 跨 2 個以上模組且含介面或契約調整
- 大型效能/安全專案（影響範圍廣）

不需要 OpenSpec（可直接實作）：
- 單點 bugfix
- typo/文案/註解修正
- 不改行為的局部重構
