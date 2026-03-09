# AGENTS.md

本檔為代理入口與索引；唯一權威規範為 `CLAUDE.md`。

---

## Authority & Scope
- 規範、流程、測試、輸出格式：一律以 `CLAUDE.md` 為準。
- 本檔僅提供索引與觸發邊界，不重複定義 `CLAUDE.md` 的規則。
- 架構背景與範例參考：`docs/prompt-reference.md`。

## GPT-5.4 Prompt Guidance (Delta Only)
- 適用範圍：撰寫 prompt、skill、command、sub-agent instructions 時，可補充使用以下 GPT-5.4 偏好；專案規範仍以 `CLAUDE.md` 為準。
- 先寫最小可行 prompt：先明確 `goal`、`success criteria`、`constraints`、`output format`，觀察偏差後再補範例或進階規則。
- Completion contract 要具體：明講做到什麼算完成、何時停止、缺資料或失敗時如何回報。
- 優先用 Markdown 標題與平面條列切開 `context`、`task`、`rules`、`output`；避免長段混寫，也避免巢狀 bullets。
- few-shot 僅在格式一致性或邊界案例真的不足時再加，避免無意義擴張 context。
- Tool-using 任務要明講查找、驗證、修改、回報的順序與邊界，不要假設模型會自行補足完成條件。
- `reasoning_effort` 視為最後微調旋鈕：先補 `completeness`、`verification loop`、`tool persistence` 規則，再考慮提高；workflow / execution-heavy 任務先從 `none` 或 `low` 評估。
- 若使用 Responses API 且需自行回放 assistant history，長流程要保留 `phase`，避免 preamble 或 progress updates 被誤判為 final answer。
- Source: <https://developers.openai.com/api/docs/guides/prompt-guidance>

## Skill Source Policy
1. Canonical project-level skill path: `.agent/skills` (authoritative; `.agents/skills` is a legacy alias fallback — currently empty)
2. 優先使用專案內 skills（`./.codex/skills`、`./.agent/skills`）
3. 專案內不存在時才 fallback 到 user-level skills
4. 同名 skill 僅允許一個生效來源（以專案內為準）
5. ⚠️ Warning: 若只存在 `.agents/skills`（legacy alias），需回收至 `.agent/skills`

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
