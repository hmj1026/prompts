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

## System Architecture Snapshot
- 技術基底：Yii 1.1 + DDD-like 分層（PHP 5.6.40，MySQL 5.7）。
- Web 入口：`index.php`（啟動 Yii WebApplication）。
- Console 入口：`protected/yiic.php`（`protected/config/console.php`）。
- 核心業務分層：
  - Interface Layer：`protected/controllers`、`protected/views`、`protected/modules/*`
  - Domain Layer：`domain/*`（Services/Entities/ValueObjects/DTOs）
  - Infrastructure Layer：`infrastructure/*`（Repositories/Http/Context/Exceptions/Utility）
  - Legacy Data Models：`protected/models/*`（Yii ActiveRecord）
- 前端主入口：`js/zpos.js`（POS 全域狀態與流程控制）。

## Layer Responsibility & Dependency Direction
- `Controller/Module`：處理請求、權限、流程編排；避免直接放大型商業邏輯。
- `Domain`：封裝業務規則與用語；不耦合框架細節。
- `Infrastructure`：資料庫、外部 API、I/O 技術細節；提供 Repository/Adapter。
- `Model(AR)`：既有資料表映射與舊流程相容；新商業規則優先放 Domain Service。
- 依賴方向建議：`Interface -> Domain -> Infrastructure`；避免反向耦合。

## Architecture Routing Map
- POS 結帳/交易流程：先看 `js/zpos.js` -> `protected/controllers/PosController.php` -> `domain/Services` -> `infrastructure/Repositories`
- 後台 CRUD/維護頁：先看 `protected/controllers/*Controller.php` + `protected/views/*` + `protected/models/*`
- 外部平台/API 整合：先看 `protected/modules/api`、`domain/*/{Requests,Responses,Services}`、`infrastructure/Http`
- 報表/列印：先看 `domain/Documents`、`domain/Reports`、`protected/views/report*`
- 測試對應：`protected/tests/{unit,functional,Domain,infrastructure}`

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

## Prompt-Aligned Architecture Checklist
- 先讀 `CLAUDE.md`（規範）與 `docs/prompt-reference.md`（長篇背景）再動手。
- 先用 `rg` 搜尋既有流程與同類實作，再決定插入點。
- 跨層修改時，明確標示「入口層、業務層、資料層」各自變更原因。
- 涉及 DB 或 API 契約調整時，先判斷是否觸發 OpenSpec 邊界。
- 輸出回報維持：結論 -> 變更檔案 -> 驗證 -> 風險/待確認。
