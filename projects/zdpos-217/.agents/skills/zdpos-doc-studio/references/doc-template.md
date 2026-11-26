# 協作者技術手冊 Markdown 標準樣板 (Doc Template)

在撰寫 `docs/collaborators/<slug>/README.md` 時，嚴格依循以下章節結構與格式規範：

版面寫法（表格、清單、停止條件）見 [`mode-feature-guidelines.md`](mode-feature-guidelines.md) 的「可讀性寫法」。以下樣板中的表格與引言區塊是示範，依內容增刪。

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
新舊行為對照用表格；每格一句話，細節寫在表格下方。

| 項目 | 過去 | 本功能 |
| --- | --- | --- |
| [痛點或行為] | [過去系統限制] | [本功能的解決方式] |

### 1.2 影響範圍與前置依賴
雙層閘門，兩層都開才生效：

| 層級 | 控制點 | 預設 |
| --- | --- | --- |
| Layer 1 商家模組開關 | `customer_module` | [開／關] |
| Layer 2 機台按鈕權限 | `data_button` | [開／關] |

- 其他前置依賴：[外部 API、排程、硬體，一項一行]
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
多個情境的規則用表格；一格一個規則，超過約 120 字的說明移到表格下方。

| 情境 | 規則 | 結果 |
| --- | --- | --- |
| [輸入條件] | [計算規則] | [輸出] |

### 4.2 併發與重入防護 (如 CAS version 單調遞增計數器)
### 4.3 邊界異常防護 (作廢防死而復生、DB 重取當前點數、外部服務副作用隔離)
停止條件獨立成一段（引言區塊），不夾在長段落中：

> [!WARNING]
> ⛔ 停止條件：[哪個狀態出現就中止流程，以及中止後的處置]。
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

| Endpoint | 方法 | 請求重點 | 回應重點 |
| --- | --- | --- | --- |
| `[controller/action]` | POST | [必填參數] | [成功與失敗回應] |

---

## 6. ⭐️ 既有無限期/舊客戶導入新制度之設定 SOP 與注意事項 (若適用)
(請參閱 references/migration-sop.md 規範填寫)

---

## 7. 維護與修改指南 (Developer's Guide to Modifying)
### 7.1 擴充情境 SOP
依序要改的檔案用編號清單，一步一個動作：

1. [第一個要改的檔案與動作]。
2. [第二個要改的檔案與動作]。

### 7.2 關鍵避坑指引 (Gotchas & Traps) 🚨

| 陷阱 | 後果 | 做法 |
| --- | --- | --- |
| [容易踩的點] | [出錯現象] | [正確做法] |

---

## 8. 測試與驗證 (Testing & Verification)
### 8.1 自動化測試套件與執行指令

| 指令 | 預期 |
| --- | --- |
| `[測試指令]` | [通過數量／無錯誤] |

### 8.2 語法與型別檢查 (PHP 5.6)
```
