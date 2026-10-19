---
name: zdpos-doc-studio
description: 為 zdpos-217 系統產出高對比、離線可開、具備互動式 Mermaid 圖表檢視器與四態 Radio 簽核系統的「協作者技術手冊 (docs/collaborators/)」與「QA 手動測試驗收手冊 (docs/qa/)」。支援 feature（協作者白箱）、qa（測試黑箱）與 both（單次盤點雙軌產出）三種模式，共用單一無損編譯、Mermaid 防裁切預渲染與 Playwright 無頭瀏覽器驗收引擎。Use when 使用者提到產出功能技術文件、協作者手冊、新舊制度導入 SOP、QA 文件、QA 手冊、手動測試 SOP、驗收手冊、撰寫測試案例、或依 Git 分支／Anchor 產出技術與測試文件。Not for 程式碼修改、單元測試 (PHPUnit) 或 Playwright E2E 腳本開發。
---

# ZDPOS 互動式文件工作台 (`zdpos-doc-studio`)

本技能整合原 `zdpos-feature-doc`（協作者白箱技術手冊）與 `zdpos-qa-doc`（QA 黑箱手動測試手冊）為**單一無損編譯、渲染與驗證引擎**，徹底杜絕雙邊樣板漂移與重複維護。

---

## 1. 模式路由與漸進式載入 (Mode Routing & Progressive Disclosure)

執行前請先依使用者需求判定目標模式（`feature`、`qa` 或 `both`），並**僅按需讀取對應的參考文件**：

| 模式 (`--mode`) | 適用情境 | 產出目標路徑 | 必讀專屬指引（按需讀取） |
| :--- | :--- | :--- | :--- |
| **`feature`**<br>（協作者技術手冊） | 產出給未來接手開發者的架構規格、DDD 分層、狀態機、DB DDL、邊界防護、舊客戶導入 SOP | `docs/collaborators/<slug>/README.md`<br>`docs/collaborators/<slug>/index.html`<br>（並註冊 `docs/collaborators/index.html`） | [`references/mode-feature-guidelines.md`](references/mode-feature-guidelines.md)<br>[`references/doc-template.md`](references/doc-template.md)<br>[`references/migration-sop.md`](references/migration-sop.md)（若含舊客導入） |
| **`qa`**<br>（QA 驗收手冊） | 產出給 QA 測試人員的前台黑箱操作手冊、「本文不測清單」、四段式 `TC-xx` 測試案例與簽核表 | `docs/qa/<module>/QA-<slug>-manual.md`<br>`docs/qa/<module>/QA-<slug>-manual.html`<br>（並註冊 `docs/qa/README.md`） | [`references/mode-qa-guidelines.md`](references/mode-qa-guidelines.md)<br>[`references/qa-case-guidelines.md`](references/qa-case-guidelines.md)<br>[`references/qa-doc-template.md`](references/qa-doc-template.md) |
| **`both`**<br>（單次盤點雙軌產出） | 給定一個 Anchor 或分支，同時建立／更新「協作者手冊」與「QA 驗收手冊」，並讓兩邊的「開發測試覆蓋 vs 本文不測清單」自動對齊 | 同時產出上述兩組路徑與雙邊總覽頁註冊 | 同時讀取 `mode-feature-guidelines.md` 與 `mode-qa-guidelines.md` |

---

## 2. 標準五步執行流程 (5-Step Workflow)

### Step 1：執行共用範圍盤點 (`inspect`)
無論是 `feature`、`qa` 或 `both` 模式，只需執行**一次**範圍掃描（支援 Git 分支差異或歷史 Anchor 字串）：
```bash
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py inspect --anchor "<anchor_string>"
```
*深入閱讀受影響之 Controller、Domain Service、Repository、Model、View、JS 與 PHPUnit/Jest 測試，區分「底層白箱防護（寫入協作者手冊 §5 & QA 手冊 §0 本文不測清單）」與「畫面可見行為（寫入 QA 手冊 TC 案例）」。*

### Step 2：建立 Markdown SSOT 腳手架 (`scaffold`)
```bash
# 單獨建立協作者手冊 (--mode feature)、QA 手冊 (--mode qa) 或雙軌同時建立 (--mode both)
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py scaffold \
  --mode <feature|qa|both> \
  --slug <slug> \
  --module <qa_module> \
  --title "<功能中文名稱>" \
  --anchor "<anchor_string>"
```

### Step 3：撰寫 Markdown 單一事實來源 (Markdown SSOT)
- **嚴禁手寫或直接編輯 `.html` 檔案**！所有文字、表格、SQL DDL、Mermaid 圖表與檢核／測試案例一律撰寫於 `.md` 檔案中。
- 語言規範：正文與圖表說明使用**正體中文**；專有名詞、類別／函式／資料表名稱保留 English。

### Step 4：執行無損確定性編譯 (`compile`)
```bash
# 編譯單一檔案（自動識別 feature 或 qa）
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py compile <path_to_md>

# 或依模式批次編譯全站手冊
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py compile --mode <feature|qa|both>
```
*`compile` 會自動執行：表格內行內程式碼 `` `a || b` `` 與 `\|` 保護、遞迴 `<details>` 解析、Mermaid 語法引號消毒、Playwright 本地 `mermaid.min.js` 批次高對比 SVG 預渲染，並自動觸發 Step 5 雙重門禁驗證。*

### Step 5：雙重門禁驗收與路由註冊 (`validate`)
```bash
# 單獨執行靜態語法 + Playwright 無頭瀏覽器實機驗收
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py validate <path_to_html_or_dir>
```
- 確認輸出包含 `✅ 靜態驗證通過` 與 `✅ [Headless 瀏覽器驗證通過]`。
- 確認總覽路由已註冊：
  - `feature` 模式：[`docs/collaborators/index.html`](../../../../zdpos-217/docs/collaborators/index.html)（以及 `docs/features/<slug>/README.md` 若存在）。
  - `qa` 模式：[`docs/qa/README.md`](../../../../zdpos-217/docs/qa/README.md) 模組分流導覽表。
- **遵守 Git 紀律**：絕不自動 commit 或 push。

---

## 3. 共用核心八大鐵律 (Eight Shared Iron Rules)

1. **單一來源與無損編譯鐵律 (Markdown SSOT -> `compile` Only)**：
   - 所有 HTML 一律由 `doc_studio.py compile` 搭配官方樣板（[`html-template.html`](references/html-template.html) / [`qa-html-template.html`](references/qa-html-template.html)）生成，嚴禁手寫拼湊 HTML 或使用 `ln -s` 建立 `index.html`。
2. **100% 離線預渲染 SVG 鐵律 (Offline Pre-rendered Mermaid)**：
   - 編譯期透過本地 `resources/mermaid.min.js` 與 `scripts/render_mermaid_cli.js` 將所有 Mermaid 預渲染為內嵌 `<svg>`，零外部 CDN 依賴，支援 `file:///` 雙擊直開。
3. **Mermaid 盒模型零裁切與排版防暴衝鐵律 (Zero Text Clipping & Dagre Layout)**：
   - **防止 `flowchart TD` 水平暴衝**：下層 `subgraph` 內嚴禁出現「零入度（0 in-degree）孤立節點」（純列舉項目請合併於同一節點，介面實作寫為 `Interface -.->|"實作介面"| Impl`），避免 Dagre 將下層 Subgraph 拉到頂層水平並排。
   - **防止方框內文字被裁切**：`render_mermaid_cli.js` 於渲染前統一設定 `line-height: 1.4` 與節點標籤 `padding: 3px 8px`，渲染後於真實 DOM 為所有 `<foreignObject>` 設定 `overflow="visible"` 並自動擴充不足之 `<foreignObject>` 與 `.label-container` 外框；HTML 樣板亦強制隔離 SVG 內部 `line-height: 1.35 !important; overflow: visible !important;`，防止繼承 `body` 行高導致多行文字下半部被切半。
4. **三層互動式圖表檢視與全螢幕燈箱 ID 保護鐵律 (3-Layer Viewer & Lightbox ID Scoping)**：
   - 每張圖表自動掛載控制列（`➖ 縮小`、`➕ 放大`、`↔ 適應寬度`、`1:1 原始尺寸`、`⛶ 全螢幕檢視`）、原位滑鼠拖曳平移（Grab-to-Pan）與全螢幕滾輪縮放燈箱（`#mermaid-lightbox-modal`，預設保底比例 `>= 82%`）。
   - **全螢幕燈箱防全黑保護**：`openLightbox()` 複製 SVG 時必須將 `origId` 同步重寫為 `origId + '_lb'`（含內部 `<style>` 與 `<marker>` 引用），**嚴禁直接 `removeAttribute('id')`**（否則內部 `#mermaid_svg_...` 樣式失效，導致燈箱內節點落回瀏覽器預設全黑填色 `#000000`）。
5. **WCAG AA/AAA 高對比與純白畫布鐵律 (High-Contrast Theme & White Canvas)**：
   - 深淺色模式皆採用高對比純色變數（對比度 > 7:1），`.callout` 內嵌表格強制使用 `background: var(--panel) !important`，且所有 Mermaid 容器強制固定為純白底色 `#ffffff !important`。
6. **四態單選 Radio、Toggle 取消與初始零狀態鐵律 (4-State Radio & Zero-State Default)**：
   - 檢核卡與測試案例卡一律使用四態互斥 `<input type="radio">`（`Pass` / `Fail` / `Blocked` / `N/A`），嚴禁使用 `checkbox` 或渲染第 5 顆 `NOT_RUN` radio。
   - 靜態 HTML 嚴禁帶有預設 `checked` 屬性（初始進度必為 `0%`）；支援**再次點擊已選中 Radio 取消勾選 (Toggle Uncheck)** 與單題重置按鈕，並與頂部進度條、快速導覽 Chips 及簽核總表即時雙向同步。
7. **即時匯出與清空重填鐵律 (Live TSV/Markdown Export & Reset All Modals)**：
   - 「📤 匯出」視窗即時由記憶體與 DOM 生成最新 TSV 與 Markdown 簽核表；「🗑️ 清空」必須彈出確認視窗，確認後一鍵將所有 Radio、備註欄、Chips、簽核表與進度條完整歸零。
8. **Playwright Headless 實機驗收門禁鐵律 (Headless Browser Gate)**：
   - 每次編譯必須通過 `scripts/validate_headless.js` 實機驗證（零 Console/Page Error、初始零狀態、`<foreignObject>` 零文字裁切、全螢幕燈箱非全黑填色、Radio 點擊／切換／Toggle 取消／單題重置／匯出／全部清空 100% 正常）。

---

## 4. 腳本與參考資源索引

| 路徑 | 說明 |
| :--- | :--- |
| [`scripts/doc_studio.py`](scripts/doc_studio.py) | 統一 CLI 入口（支援 `inspect`、`scaffold`、`compile`、`validate` 與 `--mode feature\|qa\|both`） |
| [`scripts/inspect_scope.py`](scripts/inspect_scope.py) | Git 分支與歷史 Anchor 影響範圍自動掃描器 |
| [`scripts/render_mermaid_cli.js`](scripts/render_mermaid_cli.js) | 本地 Playwright Mermaid 預渲染、行高統一與 `<foreignObject>` 防裁切擴充引擎 |
| [`scripts/validate_headless.js`](scripts/validate_headless.js) | 統一 Playwright 無頭瀏覽器互動、盒模型防裁切與全螢幕燈箱對比度驗證器 |
| [`scripts/scaffold_doc.py`](scripts/scaffold_doc.py) / [`validate_html.py`](scripts/validate_html.py) | `feature` 模式無損編譯器與靜態驗證器 |
| [`scripts/scaffold_qa.py`](scripts/scaffold_qa.py) / [`validate_qa_html.py`](scripts/validate_qa_html.py) | `qa` 模式無損編譯器與靜態驗證器 |
| [`references/mode-feature-guidelines.md`](references/mode-feature-guidelines.md) | 協作者技術手冊 8 大章節與舊客導入 SOP 規範 |
| [`references/mode-qa-guidelines.md`](references/mode-qa-guidelines.md) | QA 手冊黑箱邊界、本文不測清單與四段式 `TC-xx` 規範 |
