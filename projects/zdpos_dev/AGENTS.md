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

在處理任務前，請先閱讀 .agent/rules/rules.md

# OpenSpec Instructions for zdpos_dev

You are an expert developer working on the `zdpos_dev` legacy system.
Your goal is to modernize functionality while strictly adhering to legacy constraints.

## ⚠️ 語言與溝通 (Language Requirement)
- **回應語言**：所有對話、解釋、計畫與建議，**必須強制使用正體中文 (Traditional Chinese)**。
- **程式註解**：程式碼中的註解 (Comments) 請使用正體中文。
- **專有名詞**：保留英文 (如 Controller, Model, View, Action)。

## 🧠 規劃模式 (Planning Protocol)
當需求涉及多個檔案修改、架構變更或複雜邏輯時，**嚴禁直接生成程式碼**。請遵循以下步驟：
1.  **Plan Phase**:
    - 分析需求並閱讀 `@AGENTS.md` 與 `@CLAUDE.md`。
    - 輸出一份 **[實作計畫]**，列出：
        - 涉及的檔案清單 (File List)。
        - 每個檔案的修改摘要 (Summary of Changes)。
        - 潛在風險或相容性問題 (PHP 5.6/Yii 1.1)。
2.  **Confirmation**:
    - 詢問用戶：「此計畫是否可行？」
3.  **Execution Phase**:
    - 只有在用戶回答「是」或「Go」之後，才開始輸出程式碼。

## 📋 The Proposal Workflow (Spec-Driven Development)

When the user asks for a feature or complex change:

1.  **Check for existing proposals** in `openspec/proposals/`.
2.  **Create a new proposal** if none exists (e.g., `openspec/proposals/001-feature-name.md`).
3.  **Define the Plan**:
    -   Identify necessary changes in DB Schema.
    -   List new/modified PHP files (Controller, Model, Service).
    -   Define Frontend changes (JS, Views).
    -   **Compatibility Check**: Explicitly state "PHP 5.6 compliant".
4.  **Wait for Approval**: Do not write code until the user confirms the proposal.
5.  **Update Status**: Mark items as `[x]` as you complete them.

## 💾 Context Management
-   Since the user frequently uses `/clear`, **the Proposal file is your memory**.
-   Always read the active proposal at the start of a session to know what to do next.

## 🔍 Code Quality Standards
-   **Security**: Validate all inputs using Yii validation rules. SQL Injection protection via AR or bound parameters.
-   **Logic**: Keep Controllers thin. Move logic to Services or Models.

# AGENTS.md

本檔提供「程式代理人」在本儲存庫工作的精簡指引。為落實單一真相來源，完整且權威的規範、專案背景與所有細節請一律參考 `CLAUDE.md`。本檔僅保留執行重點與索引，避免與 `CLAUDE.md` 重複。

## 核心原則（請詳閱 CLAUDE.md 對應章節）
- 單一真相來源：所有原則、流程、架構、命名與語法限制以 `CLAUDE.md` 為準
- 變更前先搜尋：先尋找可延用/擴展的實作，再決定是否新增
- 結構優先：嚴禁在根目錄新增檔案；輸出放 `output/`；依既有目錄放置程式
- 任務拆解：超過 3 步驟先撰寫計畫（使用你所在工具的 TODO/Plan）
- 編輯前先讀：在修改任何檔案前，完整閱讀並理解相關檔案
- 命名與註解：依 `CLAUDE.md` 的命名規範與 PHPDoc/JSDoc 要求執行
- 相依套件：優先使用既有套件/工具（如 phpqrcode、Yii 1.1、CommonHelper），避免新增依賴

## 工作要點（不重述細節）
- 專案架構/環境、路徑與入口、資料庫設定：請直接閱讀 `CLAUDE.md`
- PHP 5.6 語法限制與替代方案、Yii 1.1 慣例、JS 規範：請直接閱讀 `CLAUDE.md`
- 程式風格、模組化與品質要求：請直接閱讀 `CLAUDE.md`

## 參考索引（位於 CLAUDE.md）
- 核心原則與心態
- 任務前檢查清單
- 核心開發規則（禁止/必做）
- 專案架構與背景資訊（含環境/路徑/指令）
- 設定與資料庫
- PHP 5.6 程式碼風格與限制
- Yii 1.1 特定慣例
- 開發規則與標準（命名、註解、相依）
- JavaScript ES6 規範（js/zpos.js）

## 適用範圍與優先順序
- 本檔適用於整個儲存庫
- 若本檔與 `CLAUDE.md` 有出入，請以 `CLAUDE.md` 為準

