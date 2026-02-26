# AGENTS.md

本檔為代理入口與索引；唯一權威規範為 `CLAUDE.md`。

---

## Authority & Scope
- 規範、流程、測試、輸出格式：一律以 `CLAUDE.md` 為準。
- 本檔僅提供索引與觸發邊界，不重複定義 `CLAUDE.md` 的規則。
- 架構背景與範例參考：`docs/prompt-reference.md`。

## Skill Source Policy
1. 優先使用專案內 skills（`./.codex/skills`、`./.agents/skills`）
2. 專案內不存在時才 fallback 到 user-level skills
3. 同名 skill 僅允許一個生效來源（以專案內為準）

## Skill Trigger Policy (Index Only)
- 使用者明確點名 skill：必用
- 未點名時：僅在高信心匹配任務時使用
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

## Architecture Source
- 完整架構快照、分層責任、路由導覽與檢查清單統一維護於 `docs/prompt-reference.md`。

## Sub-AGENTS Index
- `protected/AGENTS.md`：protected 全域導覽與共通後端慣例
- `protected/controllers/AGENTS.md`：Controller 實作慣例
- `protected/models/AGENTS.md`：ActiveRecord 規範
- `protected/views/AGENTS.md`：View/資產與前端限制
- `protected/components/AGENTS.md`：共用元件與基底類別
- `protected/modules/AGENTS.md`：各 module 結構與實作慣例
- `protected/tests/AGENTS.md`：測試結構、命名、執行方式
- `domain/AGENTS.md`：Domain 層命名、結構與責任
- `infrastructure/AGENTS.md`：Repository/HTTP/Utility 慣例
- `js/AGENTS.md`：Legacy POS 前端與 `zpos.js` 注意事項
