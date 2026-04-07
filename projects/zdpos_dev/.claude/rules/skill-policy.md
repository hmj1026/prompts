# Skill 選用策略

## 優先順序（多 skill 同時命中時依序選擇）

1. OpenSpec 類（new/continue/apply/verify/sync/archive）
2. bug-investigation — 觸發詞：「調查」「trace」「為什麼」「排查」「找原因」「root cause」
3. tdd-guide-zdpos_dev agent（功能或 bugfix 且需調整測試）— 注意：此為 agent，非 skill
4. architect-zdpos_dev agent（跨模組或重大設計）— 觸發詞：「架構」「DDD 層次」「跨模組設計」
5. 其他技能（最小必要集合）

## 原則

- 若已透過 `/create-dev` 路由分類，以 create-dev 的分類結果為準，不再重複觸發以下優先順序。
- 不因「可用」而使用 skill，僅因「必要」而使用。
- 使用者要求直接實作且屬小型變更時，避免套完整流程型 skill。
- 同名 skill 若有多來源，以專案內版本為唯一生效版本。
- brainstorming 僅在需求不清或方案分歧時啟用。

> **注意**：強制後置步驟與 agent 調用檢查清單詳見 `execution-policy.md`。
