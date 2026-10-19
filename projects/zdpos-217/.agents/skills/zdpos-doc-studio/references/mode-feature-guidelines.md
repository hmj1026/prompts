# `feature` 模式指引：協作者技術與維護手冊 (`docs/collaborators/<slug>/`)

本文件為 `zdpos-doc-studio` 在 **`feature`（協作者白箱技術手冊）** 或 **`both`（雙軌產出）** 模式下的專屬撰寫規範。

---

## 1. 產出目標與定位

- **目標受眾**：未來接手維護、重構或擴充該功能的後端／前端開發者。
- **產出檔案**：
  1. `docs/collaborators/<slug>/README.md`（Markdown 單一事實來源 SSOT）
  2. `docs/collaborators/<slug>/README.html` 與 `docs/collaborators/<slug>/index.html`（由 `doc_studio.py compile` 自動編譯之高對比離線互動版，嚴禁使用 `ln -s` 軟連結或手寫 HTML）
  3. 自動更新總覽入口 [`docs/collaborators/index.html`](../../../../../../zdpos-217/docs/collaborators/index.html) 卡片列表。

---

## 2. 標準 8 大章節結構（參照 [`doc-template.md`](doc-template.md)）

1. **§1 功能總覽與商業背景 (Executive Summary)**
   - **1.1 核心痛點與商業價值**：解決什麼業務問題？失敗時的財務／帳務／現場衝擊為何？
   - **1.2 影響範圍與相依性**：前後端模組、外部 API、印表機／硬體或背景排程相依。
   - **1.3 向後相容與退回策略 (Fallback Design)**：參數開關關閉或外部異常時的優雅降級機制。
2. **§2 系統架構與資料流 (Architecture & Data Flow)**
   - **2.1 DDD 領域分層與架構拓撲**：使用 `flowchart TD` 繪製 `Presentation -> Domain -> Infrastructure` 分層。
   - **2.2 核心流程時序圖**：使用 `sequenceDiagram` 標註使用者動作、前端 `POS.list.ajaxPromise()`、Controller Action、Domain Service、Repository 與 DB 交易邊界。
   - **2.3 狀態機與生命週期**：使用 `stateDiagram-v2` 標註合法狀態轉移與非法攔截條件。
3. **§3 程式碼地圖與關鍵進入點 (Codebase Map & Entry Points)**
   - 依 DDD 分層表格列出每個檔案的「路徑、類別／方法、核心職責、Anchor 標記」。
4. **§4 資料庫 Schema 與設定參數 (Database & Configuration)**
   - 涉及之資料表、新增欄位、索引設計，並以 `<details><summary>展開查看完整 SQL DDL</summary>...</details>` 包裝完整建表／Migration SQL。
5. **§5 核心演算法、邊界防護與異常處理 (Core Logic & Boundary Guards)**
   - 併發防護（CAS / 悲觀鎖 / 交易隔離）、金額／精度／溢位邊界、雙重日誌（`ExceptionLogHelper` + Domain Logger）策略。
6. **§6 既有客戶導入新制度設定 SOP (Legacy Customer Migration SOP)**（參照 [`migration-sop.md`](migration-sop.md)）
   - 若涉及舊客戶升級或參數切換，以 `#### Step 1：...` 至 `#### Step N：...` 撰寫具體步驟（編譯器將自動萃取為 `MIG-01..N` 互動檢核卡）。
7. **§7 維護、除錯與擴充指南 (Maintenance, Debugging & Extension Cookbook)**
   - 常見線上異常排查路徑、日誌關鍵字查詢指令，以及「若未來要新增 X，應依序修改哪些檔案」的食譜。
8. **§8 驗證與測試覆蓋矩陣 (Verification & Test Coverage)**
   - 列出 PHPUnit 單元／整合測試指令、JS Jest／Playwright 測試指令，並撰寫 `### 8.2 協作者開發與測試驗收清單` 表格（編譯器自動轉為 `CHK-01..N` 四態 Radio 互動檢核卡）。

---

## 3. 協作者手冊專屬命令

```bash
# 1. 建立協作者手冊草稿並自動註冊 docs/collaborators/index.html
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py scaffold \
  --mode feature --slug <slug> --title "<功能中文名稱>" --anchor "<anchor_string>" [--migration]

# 2. 撰寫完 README.md 後，無損編譯並執行靜態 + Playwright Headless 驗收
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py compile \
  --mode feature docs/collaborators/<slug>/README.md

# 3. 批次重新編譯與驗證全站協作者手冊
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py compile --mode feature
```
