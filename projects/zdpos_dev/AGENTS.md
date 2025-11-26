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

