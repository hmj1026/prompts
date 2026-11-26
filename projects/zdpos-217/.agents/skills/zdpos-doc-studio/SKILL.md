---
name: zdpos-doc-studio
description: 文件工作台（doc-studio）：產出並編譯 zdpos-217 協作者技術手冊（docs/collaborators/）與 QA 手動測試驗收手冊（docs/qa/），支援 feature／qa／both 三模式。Use when 產出或更新功能技術手冊／舊客導入 SOP、撰寫 QA 手動測試驗收手冊與 TC 測試案例、或依 Git 分支／Anchor 同步產出雙軌文件。Not for 程式碼修改、PHPUnit 測試或 Playwright E2E 腳本開發。
---

# ZDPOS 互動式文件工作台（`zdpos-doc-studio`）

單一無損編譯、渲染與驗證引擎，整合協作者白箱技術手冊（`feature`）與 QA 黑箱手動測試手冊（`qa`）。

## 1. 模式路由與按需載入

執行前先依需求決定 `--mode`（`feature`、`qa` 或 `both`），僅載入對應模式的必讀參考檔：

| 模式 (`--mode`) | 適用情境 | 產出路徑與註冊目標 | 必讀指引（按需讀取） |
| :--- | :--- | :--- | :--- |
| **`feature`**<br>（協作者技術手冊） | 架構規格、DDD 分層、狀態機、DB DDL、邊界防護、舊客戶導入 SOP | `docs/collaborators/<slug>/README.md`<br>`docs/collaborators/<slug>/index.html`<br>註冊 `docs/collaborators/index.html` | [`references/mode-feature-guidelines.md`](references/mode-feature-guidelines.md)<br>[`references/doc-template.md`](references/doc-template.md)<br>[`references/migration-sop.md`](references/migration-sop.md)（含舊客導入時） |
| **`qa`**<br>（QA 驗收手冊） | 前台黑箱操作手冊、四段式 `TC-xx` 測試案例與簽核表（只放需要測試的畫面行為） | `docs/qa/<module>/QA-<slug>-manual.md`<br>`docs/qa/<module>/QA-<slug>-manual.html`<br>註冊 `docs/qa/README.md` | [`references/mode-qa-guidelines.md`](references/mode-qa-guidelines.md)<br>[`references/qa-case-guidelines.md`](references/qa-case-guidelines.md)<br>[`references/qa-doc-template.md`](references/qa-doc-template.md)<br>[`references/ui-label-sources.md`](references/ui-label-sources.md) |
| **`both`**<br>（雙軌產出） | 同一 Anchor／分支同步建置或更新雙邊手冊；底層與程式面入協作者手冊，QA 手冊只留畫面可測內容 | 同步產出上述兩組路徑與雙邊總覽註冊 | 同時載入 `feature` 與 `qa` 兩列必讀檔 |

## 2. 標準五步工作流

### Step 1：共用範圍盤點（`inspect`）
所有模式共用一次範圍掃描（支援 Git 分支差異或歷史 Anchor）：
```bash
python3 .agents/skills/zdpos-doc-studio/scripts/doc_studio.py inspect --anchor "<anchor_string>"
```
深入閱讀受影響的 Controller、Domain Service、Repository、Model、View、JS 與 PHPUnit／Jest 測試，區分「底層白箱防護（寫入協作者手冊 §4～§5，QA 手冊不列）」與「畫面可見行為（寫入 QA 手冊 TC 案例）」。
- **完成條件**：已跑完 `inspect`，且全部受影響檔案已歸類為白箱規格或黑箱可見行為。

### Step 2：建立 Markdown SSOT 腳手架（`scaffold`）
```bash
python3 .agents/skills/zdpos-doc-studio/scripts/doc_studio.py scaffold \
  --mode <feature|qa|both> \
  --slug <slug> \
  --module <qa_module> \
  --title "<功能中文名稱>" \
  --anchor "<anchor_string>"
```
- **完成條件**：目標 `.md` 腳手架已生成，且 `--mode`、`--slug`、`--module`、`--title`、`--anchor` 皆正確填入。

### Step 3：撰寫 Markdown SSOT
- 所有文字、表格、SQL DDL、Mermaid 圖表與檢核／測試案例一律寫於 `.md`，由 Step 4 `compile` 產生 `.html`（禁止手寫或直接修改 `.html`）。
- 語言：正文與圖表說明用正體中文；專有名詞、類別／函式／資料表名保留 English。
- **QA 手冊三原則**（`qa`／`both` 的 QA 端必守，細則見 [`references/mode-qa-guidelines.md`](references/mode-qa-guidelines.md) §2；`feature` 協作者手冊不受此限，技術細節放那裡）：
  1. 名詞與實際畫面一致：寫畫面上的字、選單路徑或頁面標題，省略 action／route／商家代號。
  2. 以白話取代程式術語：placeholder、前綴比對、EXPLAIN、Console 等皆改寫為操作與畫面描述。
  3. 只放需要測試的內容：略去 DB／索引／測試檔名／ADR 編號／實作位置表／自動化紀錄附錄與預設的「本文不測清單」；可合併的案例合併，單一 TC 控制在約 5 步內。
- **完成條件**：`.md` 完整覆蓋對應模式必要章節；QA 端每個詞彙都能在畫面找到或讓 QA 直接看懂，否則已改寫或刪除。

### Step 3.5：畫面字串查證（`qa`／`both` 模式）
引號內的選單、按鈕、欄位、提示字串，先依 [`references/ui-label-sources.md`](references/ui-label-sources.md) 查證來源再寫入；`compile` 會自動執行 `verify_labels.py` 列出未命中字串。
- **完成條件**：`verify_labels.py` 回報之未命中字串已全數結案（改為原始碼真名，或確認只存在 DB 後完成登記）。

### Step 3.6：環境前提核對（`qa`／`both` 模式）
畫面行為依賴 DB 設定的案例，依 [`references/mode-qa-guidelines.md`](references/mode-qa-guidelines.md)「環境前提」把設定名與值記入 metadata `env-preconditions`。交付前、以及每輪 QA 開測或判讀 N/A／Blocked 前，用唯讀 MCP（DEV＝`mysql-dev-remote`）查詢 `SELECT config_value, uby, udate FROM <db>.system_config WHERE config_name IN (...)` 逐項比對；值不符時先回報（含 `uby`／`udate`），維持手冊判定不動。
- **完成條件**：每個 `env-preconditions` 項目皆有本輪實查結果（相符，或已附 `uby`／`udate` 回報差異）。

### Step 4：無損確定性編譯（`compile`）
```bash
# 單檔編譯（自動識別 feature 或 qa）
python3 .agents/skills/zdpos-doc-studio/scripts/doc_studio.py compile <path_to_md>
# 依模式批次編譯全站手冊
python3 .agents/skills/zdpos-doc-studio/scripts/doc_studio.py compile --mode <feature|qa|both>
```
`compile` 自動執行：表格行內程式碼 `` `a || b` `` 與 `\|` 保護、遞迴 `<details>` 解析、Mermaid 語法引號消毒、Playwright 本地 `mermaid.min.js` 批次高對比 SVG 預渲染，並串接 Step 5 雙重門禁驗證。
- **完成條件**：目標 `.html` 已由 `compile` 重新生成，且無編譯錯誤。

### Step 5：雙重門禁驗收與路由註冊（`validate`）
```bash
python3 .agents/skills/zdpos-doc-studio/scripts/doc_studio.py validate <path_to_html_or_dir>
```
- 總覽路由註冊：
  - `feature` 模式：[`docs/collaborators/index.html`](../../../../zdpos-217/docs/collaborators/index.html)（若存在 `docs/features/<slug>/README.md` 亦同步確認）。
  - `qa` 模式：[`docs/qa/README.md`](../../../../zdpos-217/docs/qa/README.md) 模組分流導覽表。
- Git 紀律：保留工作樹變更由使用者手動 commit／push，不自動執行。
- **完成條件**：驗證輸出同時包含 `✅ 靜態驗證通過` 與 `✅ [Headless 瀏覽器驗證通過]`、對應總覽路由已完成註冊，且未自動 commit／push。

## 3. 共用核心八大鐵律

修改編譯器、樣板或手冊時，以下八條全數適用：

1. **Markdown SSOT → `compile`**：所有 HTML 統一由 `doc_studio.py compile` 搭配官方樣板（[`html-template.html`](references/html-template.html)／[`qa-html-template.html`](references/qa-html-template.html)）生成；禁止手寫 HTML 或以 `ln -s` 建立 `index.html`。
2. **100% 離線預渲染 SVG**：編譯期以本地 `resources/mermaid.min.js` 與 `scripts/render_mermaid_cli.js` 將 Mermaid 預渲染為內嵌 `<svg>`，零外部 CDN 依賴，支援 `file:///` 雙擊直開。
3. **Mermaid 盒模型零裁切與 Dagre 排版**：
   - **防 `flowchart TD` 水平暴衝**：下層 `subgraph` 內每個節點皆須具入度（純列舉項目合併於同一節點，介面實作寫為 `Interface -.->|"實作介面"| Impl`；禁止下層出現零入度孤立節點，避免 Dagre 將下層 Subgraph 拉至頂層水平並排）。
   - **防方框內文字裁切**：`render_mermaid_cli.js` 渲染前設 `line-height: 1.4` 與節點標籤 `padding: 3px 8px`，渲染後於真實 DOM 為所有 `<foreignObject>` 設 `overflow="visible"` 並自動擴充不足的 `<foreignObject>` 與 `.label-container` 外框；HTML 樣板隔離 SVG 內部 `line-height: 1.35 !important; overflow: visible !important;`，防止繼承 `body` 行高切斷多行文字下半部。
4. **三層互動式檢視與燈箱 ID 保護**：
   - 每張圖表自動掛載控制列（`➖ 縮小`、`➕ 放大`、`↔ 適應寬度`、`1:1 原始尺寸`、`⛶ 全螢幕檢視`）、原位拖曳平移（Grab-to-Pan）與全螢幕滾輪縮放燈箱（`#mermaid-lightbox-modal`，原生 `<dialog>` 以 `showModal()` 開啟，Esc／點外側／關閉鈕關閉並清空內容，預設保底比例 `>= 82%`）。
   - **燈箱防全黑保護**：`openLightbox()` 複製 SVG 時將 `origId` 同步重寫為 `origId + '_lb'`（含內部 `<style>` 與 `<marker>` 引用）；禁止直接 `removeAttribute('id')`（否則內部 `#mermaid_svg_...` 樣式失效，節點落回全黑 `#000000`）。
5. **WCAG AA/AAA 高對比與純白畫布**：
   - 未儲存偏好時以 `color-scheme` meta＋`prefers-color-scheme` 跟隨系統深淺色（不靠 JS）；兩態切換鈕切回與系統相同時清除覆寫；樣板深色規則集中寫於 `@dark-theme` 區段由編譯器展開。
   - 深淺色模式皆採高對比純色變數（對比度 > 7:1），`.callout` 內嵌表格套用 `background: var(--panel) !important`，所有 Mermaid 容器固定純白底色 `#ffffff !important`。
6. **四態單選 Radio、Toggle 取消與初始零狀態**：
   - 檢核卡與測試案例卡統一用四態互斥 `<input type="radio">`（`Pass`／`Fail`／`Blocked`／`N/A`；禁止改用 `checkbox` 或渲染第 5 顆 `NOT_RUN` radio）。
   - 靜態 HTML 不帶預設 `checked`（初始進度必為 `0%`）；支援再次點擊已選 Radio 取消勾選（Toggle Uncheck）與單題重置按鈕，與頂部進度條、快速導覽 Chips 及簽核總表即時雙向同步。
7. **即時匯出與清空重填**：
   - 「📤 匯出」由記憶體與 DOM 即時生成最新 TSV 與 Markdown 簽核表，複製結果顯示於 `role="status"`；「🗑️ 清空」彈出確認視窗（預設焦點在「取消」），確認後將所有 Radio、備註欄、Chips、簽核表與進度條完整歸零。兩者皆用原生 `<dialog>`，依賴原生行為不手寫 focus trap 或 Esc 處理。
8. **Playwright Headless 實機驗收門禁**：
   - 每次編譯須通過 `scripts/validate_headless.js` 實機驗證：零 Console／Page Error、初始零狀態、`<foreignObject>` 零文字裁切、全螢幕燈箱非全黑填色、Radio 點擊／切換／Toggle 取消／單題重置／匯出／全部清空 100% 正常、各視窗按 Esc 可關閉、表頭具 `<th scope>`、未儲存偏好時跟隨系統深淺色。執行時須能解析 `playwright`（在含 `node_modules/playwright` 的專案根目錄執行，或設定 `NODE_PATH`）。

## 4. 腳本與參考資源索引

| 路徑 | 說明 |
| :--- | :--- |
| [`scripts/doc_studio.py`](scripts/doc_studio.py) | 統一 CLI 入口（支援 `inspect`、`scaffold`、`compile`、`validate` 與 `--mode feature\|qa\|both`） |
| [`scripts/inspect_scope.py`](scripts/inspect_scope.py) | Git 分支與歷史 Anchor 影響範圍掃描器 |
| [`scripts/render_mermaid_cli.js`](scripts/render_mermaid_cli.js) | 本地 Playwright Mermaid 預渲染、行高統一與 `<foreignObject>` 防裁切擴充引擎 |
| [`scripts/validate_headless.js`](scripts/validate_headless.js) | Playwright 無頭瀏覽器互動、盒模型防裁切與燈箱對比度驗證器 |
| [`scripts/scaffold_doc.py`](scripts/scaffold_doc.py) / [`validate_html.py`](scripts/validate_html.py) | `feature` 模式無損編譯器與靜態驗證器 |
| [`scripts/scaffold_qa.py`](scripts/scaffold_qa.py) / [`validate_qa_html.py`](scripts/validate_qa_html.py) | `qa` 模式無損編譯器與靜態驗證器 |
| [`scripts/verify_labels.py`](scripts/verify_labels.py) | 抓手冊引號字串並以 `git grep` 比對原始碼（`compile` 自動執行，可加 `--ref`） |
| [`references/mode-feature-guidelines.md`](references/mode-feature-guidelines.md) | 協作者技術手冊 8 大章節與舊客導入 SOP 規範 |
| [`references/mode-qa-guidelines.md`](references/mode-qa-guidelines.md) | QA 手冊黑箱邊界、本文不測清單與四段式 `TC-xx` 規範 |
| [`references/ui-label-sources.md`](references/ui-label-sources.md) | QA 手冊畫面字串查證來源（選單、欄位、視窗、提示） |
