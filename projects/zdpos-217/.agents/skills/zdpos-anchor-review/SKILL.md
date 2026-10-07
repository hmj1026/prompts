---
name: zdpos-anchor-review
description: feature 分支合併前的最後一關：盤點 anchor、phpDoc jsDoc、coding style 與命名，經使用者確認後一次完成所有調整（含改名的呼叫端與測試）並驗證。Use when 使用者提到 anchor 檢查、分支盤點、補 anchor、doc 整理、或貼上日期加人名加方括號主題格式的 anchor 字串要求檢查本次開發。Not for 功能實作、bug 修正，或不涉及 anchor／doc／style 合規的一般 code review。
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(git *), Bash(rg *), Bash(grep *), Bash(cx *), Bash(php -l *), Bash(docker exec *)
---

# Anchor Review（分支合規盤點）

本技能是 feature 分支合併前的最後一關：針對整個分支盤點 anchor、doc、風格與命名，
使用者確認後一次完成所有調整並驗證，不需另外再跑其他規範檢查。
§4 的規則完整內嵌於本技能，判定不依賴規範檔是否存在於當前分支；
`CODING_STANDARDS.md` 等規範檔是給需求分支開發時遵循的，本技能只在需要細節時參考。
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
- 勾選 style 模組且差異含 `protected/views/**` 時，對 view 加跑三項偵測，
  結果列入 style 類，判定依據見 §4 第 8 項：
  - HTML 本體或 `<script>` 內的新增行含 PHP 流程控制：
    `<?php if`、`<?php elseif`、`<?php else`、`<?php foreach`、`<?php }` 或三元輸出。
    只比對 PHP 標籤內的關鍵字，JS 的 if／else 不算；檔頭 PHP 區不算。
  - 本次新增的 PHP→JS 注入，與同一個 `<script>` 區塊內其他 `<?php echo` 或 `<?=` 疊在一起。
  - `<script>` 內新增的 `<?php echo` 或 `<?=` 未經 `CJSON::encode` 或 `CJavaScript::encode`。
- 勾選 style 模組時，列出本分支新增的方法（新檔的全部方法；既有檔只取 diff 新增的方法宣告），
  逐一對照 §4 第 11、13、20 條判定是否需要改名，改名依 §4.2 程序。

## 2. Anchor 規則

anchor 由日期、作者、方括號主題、描述組成，
前後可為雙斜線、井字號、星號、HTML 註釋。

view 檔（含新增檔、新增區段、修改段落）依 anchor 所在位置選註釋形式：

- HTML 區用 `<!-- anchor -->`。
- `<script>` 區塊內用 `// anchor`。
- 檔頭或其他 PHP 區用 `// anchor`。
- 不得用 PHP 註釋包 HTML。

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
- view 檔的註釋形式見 §2 開頭。

## 3. phpDoc jsDoc 規則

- 對象為本次分支所有新增或修改的方法與物件之註釋。
- anchor 行不得調整或刪除。
- 其餘 doc 文字用 writing-for-agents 技能風格重整，
  去除重複與難讀術語，優先引用 CONTEXT 實作術語對照表中文寫法。
  例如歸零前快照、寫後回讀、來源綁定、回應內容、
  門市鎖、權限閘、失敗即中止。
- 英文對照只在對照既有討論時參考，不寫進註釋。

## 4. Coding style（只判新增或修改區塊，測試檔一併適用）

以下規則可獨立判定；括號內「出處」為專案內的完整規則，需要細節或例外時再查。
範圍依 `CODING_STANDARDS.md` §1 Scope Rule。`CODING_STANDARDS.md` 位於 prompts repo 的
`projects/zdpos-217/` 下，zdpos 根目錄有一份相同副本。`.claude/rules/php/coding-style.md` 只是部分英文摘要，
沒有 § 編號也沒有 §9，查 § 時須讀 `CODING_STANDARDS.md`。
本節與出處衝突時以出處為準，並在盤點表註明衝突。

1. **調用階梯**：優先級為 `專案 Support Helper（Arr/Str/Date） > Yii 框架核心（Request/DbCriteria） > 原生 PHP`；嚴禁直接存取 `$_POST` 等超全域變數或重複造輪子。（出處：CODING_STANDARDS §4.1、§5；Controller 確認鍵存在後整批讀 `$_POST` 的例外見 §4.1）
2. **陣列語法**：一律使用短陣列語法 `[]`，嚴禁使用 `array()`，測試檔斷言亦同。（出處：CODING_STANDARDS §3）
3. **枚舉常數**：避免 hardcode，多處共用之狀態或下拉值優先繼承 `AbstractEnum`，單一類別內標記使用類別常數。（出處：CODING_STANDARDS §6）
4. **持久層規範**：Controller 內嚴禁 inline SQL；新增查詢優先走既有 Repository 或 `queryBuilder`，寫入操作亦走 `queryBuilder`，禁止直接以 `createCommand` 拼裝 SQL；toolkit 確實不適用時才走 `createCommand`，DDL 或動態表名依第 18 條。（出處：`protected/controllers/AGENTS.md`、`infrastructure/AGENTS.md` Database Query Toolkit 段、`.claude/rules/php/patterns.md` DB Query Layering）
5. **變數命名**：物件變數採大駝峰（PascalCase，如 `$PayAction`），陣列/集合採小寫蛇型（snake_case，如 `$order_items`）。（出處：CODING_STANDARDS §8）
6. **DDD 與介面收斂**：抽 Service 模組化並保持 early return；相似職責的 Domain/Service 相同業務動作應對齊同名方法（以利介面抽取）；Domain 層嚴禁依賴 SQL 與 HTTP。Policy 的決策動詞一律 `passes()`（true = 放行），不用 static `decide()`。（出處：`domain/AGENTS.md`、CODING_STANDARDS §9、`.claude/rules/php/patterns.md` Policy 類落點與形狀）
7. **Controller 瘦身**：私有通用商業邏輯考慮收進 trait，避免 fat controller。（出處：`protected/controllers/AGENTS.md`）
8. **無邏輯視圖（Logic-less View）**：View 僅負責變數渲染；業務邏輯、資料過濾與條件組裝一律提前於 Controller/Service 完成；嚴禁內嵌大段 `<script>` 或 `<style>`，評估抽離為獨立靜態檔。（出處：`protected/views/AGENTS.md` View hygiene baseline、`.claude/rules/php/view-architecture.md` View 段、`.claude/rules/frontend.md` View-layer PHP → JS Data Passing；偵測步驟見 §1）
   PHP→JS 資料傳遞判定要點：
   - 資料收進一個 config 物件（`configs`，或 `pageConfig`／`pageConfigs`）：
     由 Controller 傳入，或在 view 檔頭 PHP 區組成。
   - 整頁只有一個注入點，用 `CJSON::encode` 或 `CJavaScript::encode` 輸出，JS 以解構取值後處理。
   - legacy 例外（依 view-architecture.md 開頭的 Scope Rule，只適用於未實質改寫的既有 view）：
     既有 view 已有其他 `<?php echo` 注入時，不順手重構既有注入。
     新增資料優先併入既有 config 物件；沒有可併的物件時，
     另開一個只含 config 注入的 `<script>` 區塊，不疊進既有 script。
   - HTML 本體與 `<script>` 內不得夾 PHP 流程控制（`if`／`elseif`／`foreach`／三元），
     頂層 `widget()`、必要 include、最小 guard 除外；也不得以 `echo` 輸出 JS 切換流程。
   - 不手寫 `json_encode` 旗標或以字串拼接 JS；跳脫交給上述兩個 encode。
   - 本次新增或依賴的 render 變數，檔頭 PHPDoc 要有對應的 `@var`。
9. **前端 JS**：新增或修改優先使用 ES6 原生語法，僅在存取既有頁面之 jQuery 元件時方可使用 jQuery。判定時：新檔與新抽出的 leaf 必須 ES6 原生；修改既有 jQuery 檔跟隨原檔風格，不列違規；從巨檔機械抽出（`zdpos-legacy-js-refactor`）維持 IIFE + `var`。（出處：`.claude/rules/frontend.md` Hard Limits、`js/AGENTS.md`）
10. **方法放置**：新增方法預設加在檔案最下端；同領域之方法群可就近集中於相關既有方法旁以維持內聚性；常數與屬性放類別頂端，不夾在方法之間。（出處：CODING_STANDARDS §9）
11. **Policy 形狀**：Domain 決策類一律放 `domain/Policies/`（namespace `Domain\Policies`，不依模組切子目錄）；instance-based，不寫 static；決策動詞一律 `passes()`，true = 放行，不放行訊息用 `message()`（對齊 Laravel Rule 物件）；同一次 request 內固定的環境值進 constructor，決策方法只吃被判定的標的。（出處：`.claude/rules/php/patterns.md` Policy 類落點與形狀）
12. **catch 慣例**：每個 `catch (\Exception $e)` 都要同時呼叫 `ExceptionLogHelper::logCaughtExceptionToApplication()` 與領域 logger；不得空 catch 或只寫 `// ignore`。（出處：`.claude/rules/php/patterns.md` Exception Logging、技能 `zdpos-exception-logging`）
13. **方法名長度**：一般方法名不得超過 32 字元；PHPUnit `testXxx` 豁免。縮短方式：刪 `ForXxx` 後綴、`Constructor` 縮成 `Ctor`、省略類別名已表達的模組詞。（出處：CODING_STANDARDS §7）
14. **PHP 5.6 語法**：禁 `??`、`?->`、純量型別宣告與回傳型別、`fn() =>`、`match`、具名參數、多重 catch、短 list 解構、匿名類別；PHP 7 函式改用 polyfill（如 `random_int` → `openssl_random_pseudo_bytes`、`intdiv` → `(int)($a / $b)`）。此條不受 Scope Rule 豁免。（出處：CODING_STANDARDS §2、根 AGENTS.md Critical Constraints）
15. **前端 AJAX**：新功能禁用 `$.ajax`、`$.post`、`$.get`、`fetch`、`axios`，一律走既有 wrapper，新功能優先 `POS.list.ajaxPromise()`；核心檔（`zpos.js`、`mpos.js`、`pos_core.js`、`main.js`）定義 wrapper，豁免。（出處：`.claude/rules/frontend.md` Hard Limits）
16. **測試檔**：方法用 `public function testXxx()`，命名 `test[Subject]_[Condition]_[ExpectedOutcome]`；斷言優先 `assertSame()`；PHPUnit 5.7 語法（例外斷言新寫優先 `expectException()`，不用 PHPUnit 6+ API）；`unit/` 不得碰 `Yii::app()` 或 DB；主類別名等於檔名；UTF-8 無 BOM；避開 Giant／Inspector／Flicker／Silent／Chain／Mockery 壞模式。（出處：`.claude/rules/php/testing.md`、`protected/tests/AGENTS.md`）
17. **魔術值範圍**：裸 `0`／`'0'`／`1` 不只禁於查詢條件，Controller 業務分支與 view 渲染分支同樣禁止；權限字串、ACL marker、sentinel 字串收進對應類別常數。（出處：CODING_STANDARDS §6、`.claude/rules/php/coding-style.md` Magic Values）
18. **Repository 細則**：方法名帶業務語意與必要欄位（禁 `insertRow`、`updateBy`、`executeRaw` 類泛用名）；鄰近程式用 `createCommand` 不構成前例，無法升級時另開 `queryBuilder` 版 V2 平行方法並在舊方法標 `@see`；IN 查詢 builder 用 `whereIn()`、`CDbCriteria` 用 `addInCondition()`，傳入前 `array_values()`、先擋空陣列；DDL 或動態表名的 raw SQL 須先 `assertValidTableName()`。（出處：`.claude/rules/php/patterns.md` DB Query Layering、IN / NOT IN、Raw SQL vs Query Builder）
19. **AJAX／API 回應契約**：依呼叫端選格式，不自創新格式、不改既有端點格式。POS 前台端點（`POS.list.ajaxPromise` 等）用 `{err, date, result, msg, data}`，經 `PosController::response()`，非 PosController 端點須輸出相同鍵；後台頁面 AJAX 用 `{success, data, message}`，新程式以 `ApiResponse::success()`／`fail()` 組裝、`Respondable::respond()` 輸出；ZTable 內建 callback 成功回純文字 `success`、錯誤用 `ZTableErrorResponse::end()`；api module 用其 trait 的 `json()`／`error()`；整頁請求錯誤拋 `CHttpException`。（出處：CODING_STANDARDS §10、`.claude/rules/php/patterns.md` Controller Response）
20. **命名對齊 Laravel**：新命名先找 Laravel 對應概念並沿用其名稱（Policy 的 `passes()`／`message()`、閘門 `ensureXxx()`、`authCheck()`、`expectsJson()`、取值不加 `get` 前綴、`validateXxx()` 回傳違規訊息或 `null`）；無對應時依專案慣例。解析外部格式用 `parseXxx()`，`fromXxx()` 只用於回傳本類別實例的工廠方法。同性質類別的相同動作用相同方法名與參數順序。（出處：CODING_STANDARDS §14）

### 4.1 條件式檢查（diff 含對應檔案時才判定）

- **Migration**（`protected/migrations/**`）：檔名 `m{YYMMDD}_{HHMMSS}_217_{Author}_{Operation}_{Target}.php` 且類別名等於檔名；用 `safeUp()`／`safeDown()`；DDL／DML 先檢查存在性（冪等）；docblock 寫日期、作者、理由與證據（列數、engine、鎖表影響）；`data_action` 以 `action_method` 為鍵。（出處：`protected/migrations/AGENTS.md`）
- **FormRequest**（新增 DTO 或 Controller 驗證）：新 DTO 繼承 `AbstractFormRequest`；規則只在 `rules()` 宣告，Controller 不重複驗證。（出處：`.claude/rules/php/patterns.md` FormRequest / Validation）
- **Event**（新增 Event 或 Listener）：只用 `Yii::app()->eventDispatcher`，不自行 new（單元測試除外）；listener 只在 `EventDispatcherBootstrap::registerListeners()` 註冊。（出處：`.claude/rules/php/patterns.md` Event Dispatch）
- **View 輸出與 SQL**：純顯示文字用 `CHtml::encode()`；view 內不得有 SQL。（出處：`.claude/rules/php/security.md` XSS、`.claude/rules/php/patterns.md` DB Query Layering 第 2 點）
- **components 與 modules**：`protected/components/` 不放單一功能邏輯；module 內遵循該 module 自身慣例，不移植根目錄 MVC 寫法。（出處：`protected/components/AGENTS.md`、`protected/modules/AGENTS.md`）

### 4.2 命名調整程序（改名類項目）

- **可改範圍**：只改本分支新增、基準分支不存在的方法。基準分支既有的方法不改名，除非本分支整個重寫該方法。
- **不可改名**（名稱會被當成字串或資料使用，改了會在執行期失效）：
  - Controller 的 `actionXxx`：URL 路由、`data_action` 權限資料與前端呼叫都依賴它。
  - AJAX 分派鍵（如 `case 'xxx'`、前端 `ajaxPromise('xxx')` 的字串）。
  - 以字串呼叫的方法（`call_user_func`、Reflection、測試以字串帶方法名）若無法同步改到所有字串，列為不改並註明。
- **找呼叫端**：`cx references --name 舊名` 加 `rg -n '舊名'`，範圍含 `domain/`、`infrastructure/`、`protected/`（含 views、tests）與 `js/`。本分支新增的符號不用 `gitnexus_impact`（索引以已提交主線為準，會漏報）。
- **其他未合併分支**：以 `git grep -n '舊名' <分支>` 檢查其他尚未合併的 feature 分支是否呼叫；有呼叫時在盤點表註明，由使用者決定合併順序。
- **一次改齊**：方法宣告、所有呼叫端、測試（含以字串帶方法名者）、docblock 內提到的名稱在同一輪修正；改名不新增或移動 anchor。
- **拆帳分支**：依該分支 `docs/workflow/execution-policy.md` §4，測試原始碼、docblock、anchor 的任何變更都會使 Golden Master／evidence receipt 失效；在拆帳分支執行前先在盤點表標示，由使用者決定是否同輪重做 receipt。

### 4.3 不屬本技能

正確性（如批次標記競態）改用 code-reviewer；PDO、CSRF、授權改用 security-reviewer；ESLint tier 與 `@ts-check` 改用技能 `zdpos-js-lint-config`、`zdpos-js-static-check-strategy`。

## 5. Refactor rule

- 檔案搬遷重構保持既有樣式含註釋，
  不得順手重排無關段落。

## 6. 兩階段工作流（強制）

### Phase A 盤點（先做，不改碼）

輸出表格，每列包含檔案與行號、類型、
現況、預計調整加內容範例；改名類另列呼叫端數量與涉及檔案，以及其他未合併分支的呼叫情形。
結尾必須詢問使用者審核，確認後才開始修正，然後停下等待。

### Phase B 修正（使用者明確確認後）

- 一次完成使用者確認的全部項目，含改名的所有呼叫端與測試；anchor 行原樣插入，不改既有 anchor。
- 新方法放檔案最下端，遵守 PHP 5.6 語法。
- 修正後驗證，任一步失敗即修正後重跑，不得帶著失敗結束：
  1. 每個變更的 PHP 檔跑 `php -l`。
  2. 有 view 變更時重跑 §1 的 view 偵測，結果須為零。
  3. 以 `rg` 確認舊方法名在程式碼與測試中已無殘留。
  4. 在容器內跑受影響的測試：
     `docker exec -i -w /var/www/www.posdev/zdpos-217 pos_php php -d memory_limit=1G vendor/bin/phpunit -c protected/tests/phpunit.xml <測試路徑>`；
     既有且與本次無關的失敗須以基準分支或 commit 歷史證明為既有，並列出。
- 最後列出差異統計摘要、驗證結果與未處理項目。不自動 commit；建議改名類調整與其他調整分成獨立的 `refactor:` commit。
