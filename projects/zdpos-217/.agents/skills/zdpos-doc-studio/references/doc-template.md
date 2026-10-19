# 協作者技術手冊 Markdown 標準樣板 (Doc Template)

在撰寫 `docs/collaborators/<slug>/README.md` 時，嚴格依循以下章節結構與格式規範：

```markdown
# [功能名稱] 協作者完整技術手冊 ([Feature English Name] Architecture & Developer Guide)

| 欄位 | 值 |
| --- | --- |
| `owner` | `project-maintainers` |
| `author` | `[Author Name]` |
| `status` | `current` |
| `last-verified` | `YYYY-MM-DD` |
| `feature-anchor` | `[YYYY/MM/DD author (branch/anchor)]` |
| `canonical-source` | [README.md](file:///home/paul/projects/zdpos-217/docs/collaborators/<slug>/README.md) |
| `sensitivity` | `git-safe` |
| `retention` | `current-until-superseded` |

---

## 快速導覽與架構狀態

<div style="margin-bottom: 16px;">
  <span style="background-color: #0969da; color: white; padding: 3px 10px; border-radius: 12px; font-size: 13px; font-weight: bold; margin-right: 6px;">核心模組 Core Module</span>
  <span style="background-color: #1a7f37; color: white; padding: 3px 10px; border-radius: 12px; font-size: 13px; font-weight: bold; margin-right: 6px;">DDD 分層架構</span>
  <span style="background-color: #8250df; color: white; padding: 3px 10px; border-radius: 12px; font-size: 13px; font-weight: bold; margin-right: 6px;">PHP 5.6 嚴格相容</span>
  <span style="background-color: #bf8700; color: white; padding: 3px 10px; border-radius: 12px; font-size: 13px; font-weight: bold; margin-right: 6px;">[特有機制標籤]</span>
  <span style="background-color: #cf222e; color: white; padding: 3px 10px; border-radius: 12px; font-size: 13px; font-weight: bold;">[安全閘門標籤]</span>
</div>

> [模組簡要一句話說明，闡述本手冊對未來接手維護、擴充與重構工程師之價值]

---

## 目錄 (Table of Contents)

1. [功能概觀與商業背景 (Overview & Context)](#1-功能概觀與商業背景-overview--context)
2. [系統架構與資料流 (Architecture & Data Flow)](#2-系統架構與資料流-architecture--data-flow)
3. [檔案地圖與職責分配 (File & Component Map)](#3-檔案地圖與職責分配-file--component-map)
4. [關鍵業務邏輯與邊界處理 (Business Logic & Edge Cases)](#4-關鍵業務邏輯與邊界處理-business-logic--edge-cases)
5. [資料規格與資料庫契約 (Data Contracts & Models)](#5-資料規格與資料庫契約-data-contracts--models)
6. [⭐️ 既有無限期/舊客戶導入新制度之設定 SOP 與注意事項 (若適用)](#6-️-既有無限期點數客戶導入新制度之設定-sop-與注意事項)
7. [維護與修改指南 (Developer's Guide to Modifying)](#7-維護與修改指南-developers-guide-to-modifying)
8. [測試與驗證 (Testing & Verification)](#8-測試與驗證-testing--verification)

---

## 1. 功能概觀與商業背景 (Overview & Context)
### 1.1 商業價值與痛點解決
- 過去系統限制與痛點
- 本功能帶來的解決方案
### 1.2 影響範圍與前置依賴
- 雙層閘門（Layer 1 商家模組開關 `customer_module` / Layer 2 機台按鈕權限 `data_button`）
### 1.3 新舊單據邊界與歷史斷層 (若有 ADR 裁決，如舊單不支援新流程)

---

## 2. 系統架構與資料流 (Architecture & Data Flow)
### 2.1 DDD 領域分層與架構拓撲
```mermaid
flowchart TD
    subgraph Presentation ["Presentation Layer"]
    end
    subgraph Domain ["Domain Core"]
    end
    subgraph Infrastructure ["Infrastructure Layer"]
    end
```
### 2.2 核心時序圖 (Sequence Diagrams)
### 2.3 核心狀態機 (State Machines)

> 💡 **Mermaid 語法鐵律**：在 flowchart/graph 中，若節點文字或連線管道標籤 (`|...|`) 包含小括號 `()`、花括號 `{}`、方括號 `[]` 或換行 `<br/>`，請務必一律使用雙引號包裹（例如 `Node["執行 callback(true)"]`、`Decision{"條件 (x > 0)"}`、`A -->|"actionTabletCss(): bool"| B`、`A -.->|"calc(100% - 372px)"| B`），否則 Mermaid 10.9.8 會因括號衝突誤判為圓角標記 (PS) 並報錯 `Syntax error in text`。

---

## 3. 檔案地圖與職責分配 (File & Component Map)
| 檔案路徑 | 架構角色 | 核心職責 | 關鍵函式 / 進入點 |
|---|---|---|---|
| `domain/...` | Domain | ... | ... |

---

## 4. 關鍵業務邏輯與邊界處理 (Business Logic & Edge Cases)
### 4.1 核心演算法與計算規則
### 4.2 併發與重入防護 (如 CAS version 單調遞增計數器)
### 4.3 邊界異常防護 (作廢防死而復生、DB 重取當前點數、外部服務副作用隔離)
### 4.4 安全憑證與授權邊界 (CSRF Guard / Capability Token 4 大紅線)

---

## 5. 資料規格與資料庫契約 (Data Contracts & Models)
### 5.1 資料庫關聯圖 (ERD)
<details>
<summary><b>點擊展開：完整資料庫 DDL (MySQL Schema)</b></summary>

```sql
-- DDL 語法
```
</details>
### 5.2 JSON Schema 快照結構詳解 (若有複雜 JSON 欄位)
### 5.3 API 契約規格 (AJAX Endpoints)

---

## 6. ⭐️ 既有無限期/舊客戶導入新制度之設定 SOP 與注意事項 (若適用)
(請參閱 references/migration-sop.md 規範填寫)

---

## 7. 維護與修改指南 (Developer's Guide to Modifying)
### 7.1 擴充情境 SOP
### 7.2 關鍵避坑指引 (Gotchas & Traps) 🚨

---

## 8. 測試與驗證 (Testing & Verification)
### 8.1 自動化測試套件與執行指令
### 8.2 語法與型別檢查 (PHP 5.6)
```
