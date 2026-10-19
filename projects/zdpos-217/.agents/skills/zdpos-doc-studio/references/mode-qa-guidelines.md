# `qa` 模式指引：QA 手動測試驗收手冊 (`docs/qa/<module>/QA-<slug>-manual.*`)

本文件為 `zdpos-doc-studio` 在 **`qa`（QA 手動測試黑箱手冊）** 或 **`both`（雙軌產出）** 模式下的專屬撰寫規範。詳細案例筆法請一併參考 [`qa-case-guidelines.md`](qa-case-guidelines.md) 與範本 [`qa-doc-template.md`](qa-doc-template.md)。

---

## 1. 產出目標與黑箱邊界鐵律

- **目標受眾**：執行門市 POS 前台與管理後台驗收的 QA 測試人員。
- **產出檔案**：
  1. `docs/qa/<module>/QA-<slug>-manual.md`（Markdown 單一事實來源 SSOT）
  2. `docs/qa/<module>/QA-<slug>-manual.html`（由 `doc_studio.py compile` 自動編譯之高對比離線互動版）
  3. 同步登錄路由表至 [`docs/qa/README.md`](../../../../../../zdpos-217/docs/qa/README.md) 的「模組分流導覽 (Domain Routing Matrix)」。
- **前台操作唯一邊界（零容忍）**：
  - 測試步驟一律描述「畫面看得見、點得到」的操作（門市、機號、選單路徑、按鈕名稱、Toast／燈號／單據變化）。
  - **嚴禁**要求 QA 手動修改 PHP 設定檔、執行 SQL 查詢或檢查資料庫底層欄位；底層資料完整性與併發鎖定一律歸入「**§0 本文不測清單（底層由開發測試覆蓋）**」。

---

## 2. 標準章節與四段式測試案例結構

1. **§0 測試前必讀：環境座標、測試資料與本文不測清單**
   - 測試網址、測試門市／機號、測試帳號、前置測試商品／會員資料表。
   - **本文不測清單**：明確列出哪些底層邏輯已由 PHPUnit／Jest 單元測試覆蓋，免除 QA 無效操作。
   - **業務流程與狀態轉換圖**：使用 `flowchart TD` 或 `sequenceDiagram` 視覺化測試路徑。
2. **§1～§3 測試案例分組（Phase Banners & 四段式 `TC-xx` 卡片）**
   - 每個測試案例 `### TC-01：<案例標題> [⭐ 核心必測]` 必須嚴格包含四個段落：
     - **適用條件**：哪家門市、哪台收銀機、哪個畫面初始狀態。
     - **在確認什麼**：用一句白話文說明此案例驗證的使用者可見行為。
     - **操作**：`1. -> 2. -> 3.` 一步一動及每步預期畫面反應。
     - **Pass / Fail 判定**：明確的 **Pass** 條件與 **Fail** 條件。
3. **§4 驗收簽核總表、§5 缺陷回報範本、§6 已知限制與免責、§7 開發技術依據**
   - 編譯器會自動將所有 `TC-xx` 連結至頂部「🧭 案例快速導覽 Chips」與「✍️ §4 即時同步驗收簽核總表」。

---

## 3. QA 手冊專屬命令

```bash
# 1. 建立 QA 手冊 Markdown SSOT 草稿
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py scaffold \
  --mode qa --module <module> --slug <slug> --title "<功能中文名稱>"

# 2. 撰寫完 QA-<slug>-manual.md 後，無損編譯並執行靜態 + Playwright Headless 驗收
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py compile \
  --mode qa docs/qa/<module>/QA-<slug>-manual.md

# 3. 批次重新編譯與驗證全站 QA 手冊
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py compile --mode qa
```
