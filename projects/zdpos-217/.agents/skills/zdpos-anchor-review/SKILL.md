---
name: zdpos-anchor-review
description: 審查 feature 分支 anchor、phpDoc jsDoc 與 coding style 是否合規。Use when 使用者提到 anchor 檢查、分支盤點、補 anchor、doc 整理、或貼上日期加人名加方括號主題格式的 anchor 字串要求檢查本次開發。
allowed-tools: Read, Grep, Glob, Shell
---

# Anchor Review（分支合規盤點）

針對整個 feature 分支檢查 anchor、doc 與風格。
全程繁體中文回覆。程式註釋用繁體中文，技術術語維持 English。

## 0. 輸入參數

- 以技能參數傳入本次開發分支 anchor，全字串比對。
  範例格式為日期加作者加方括號主題加描述。
- 若參數為空，停下來問使用者要檢查哪個 anchor，不得自行臆測。
- 比對基準預設為 origin master，可用 BASE 參數覆寫。
- 新物件定義為在基準分支不存在、本分支新增的檔案，
  以 diff-filter A 的新增檔案清單判定。

## 0.5 模組勾選（每次執行先問）

- 本技能含四個模組，分別為 anchor、doc、style、refactor。
- 每次執行先問使用者本次要跑哪些模組，預設為全部都跑。
- 使用者可只選其中幾項，例如只要 anchor，或只要語法檢測。
- 只執行被選中的模組盤點與修正，未選模組不得順手改動。

## 1. 盤點範圍（只看本分支差異）

- 只檢查差異檔案，列出 php、js、html、vue 變更。
- 同時列出新增檔案清單以判定新物件。
- 未更動的既有程式一律不碰。
- 搬遷或重新命名檔案視為既有物件，跟隨重新命名偵測判定。

## 2. Anchor 規則

anchor 由日期、作者、方括號主題、描述組成，
前後可為雙斜線、井字號、星號、HTML 註釋。

### 2.1 新增物件（基準分支沒有、本分支新增的檔案）

- 物件註釋包含 anchor 恰一次。
- 物件內所有方法不得重複出現 anchor。
- 新 Service 的 class docblock 範例為先寫功能描述，
  空一行後寫 anchor 行，再空一行寫補充說明。

### 2.2 既有物件加新增方法

- 新增方法的 docblock 內包含 anchor 一次。
- php 範例為功能描述加 anchor 行加 param 描述。
- js 範例為功能描述加 anchor 行。
- 既有物件新增的 use 引用行屬於本次變更，一併需要 anchor。
  多行 use 只需在區段開頭放一行 anchor。

### 2.3 既有物件加既有方法（修改段落）

- 修改段落開頭第一行包含 anchor 的行註釋。
- 同一方法內連續多個 hunk 屬於同一次修改，
  只需在第一個 hunk 開頭放 anchor，不需每個 hunk 重複。
- 範例為先寫 anchor 行註釋，再寫實際程式碼行。
- view 檔用 HTML 註釋包 anchor，不得用 PHP 註釋包 HTML。

## 3. phpDoc jsDoc 規則

- 對象為本次分支所有新增或修改的方法與物件之註釋。
- anchor 行不得調整或刪除。
- 其餘 doc 文字用 writing-for-agents 技能風格重整，
  去除重複與難讀術語，優先引用 CONTEXT 實作術語對照表中文寫法。
  例如歸零前快照、寫後回讀、來源綁定、回應內容、
  門市鎖、權限閘、失敗即中止。
- 英文對照只在對照既有討論時參考，不寫進註釋。

## 4. Coding style（只判新增或修改區塊，測試檔一併適用）

1. **調用階梯**：優先級為 `專案 Support Helper（Arr/Str/Date/Log） > Yii 框架核心（Request/DbCriteria） > 原生 PHP`；嚴禁直接存取 `$_POST` 等超全域變數或重複造輪子。
2. **陣列語法**：一律使用短陣列語法 `[]`，嚴禁使用 `array()`，測試檔斷言亦同。
3. **枚舉常數**：避免 hardcode，多處共用之狀態或下拉值優先繼承 `AbstractEnum`，單一類別內標記使用類別常數。
4. **持久層規範**：Controller 內嚴禁 inline SQL；新增查詢優先走既有 Repository 或 `queryBuilder`，寫入操作亦走 `queryBuilder`，禁止直接以 `createCommand` 拼裝 SQL。
5. **變數命名**：物件變數採大駝峰（PascalCase，如 `$PayAction`），陣列/集合採小寫蛇型（snake_case，如 `$order_items`）。
6. **DDD 與介面收斂**：抽 Service 模組化並保持 early return；相似職責的 Domain/Service 相同業務動作應對齊同名方法（以利介面抽取）；Domain 層嚴禁依賴 SQL 與 HTTP。
7. **Controller 瘦身**：私有通用商業邏輯考慮收進 trait，避免 fat controller。
8. **無邏輯視圖（Logic-less View）**：View 僅負責變數渲染；業務邏輯、資料過濾與條件組裝一律提前於 Controller/Service 完成；嚴禁內嵌大段 `<script>` 或 `<style>`，評估抽離為獨立靜態檔。
9. **前端 JS**：新增或修改優先使用 ES6 原生語法，僅在存取既有頁面之 jQuery 元件時方可使用 jQuery。
10. **方法放置**：新增方法預設加在檔案最下端；同領域之方法群可就近集中於相關既有方法旁以維持內聚性。

## 5. Refactor rule

- 檔案搬遷重構保持既有樣式含註釋，
  不得順手重排無關段落。

## 6. 兩階段工作流（強制）

### Phase A 盤點（先做，不改碼）

輸出表格，每列包含檔案與行號、類型、
現況、預計調整加內容範例。
結尾必須詢問使用者審核，確認後才開始修正，然後停下等待。

### Phase B 修正（使用者明確確認後）

- 逐項修正，anchor 行原樣插入，不改既有 anchor。
- 新方法放檔案最下端，遵守 PHP 5.6 語法。
- 修正後列出差異統計摘要。
