# Coding Style 規則（`zdpos-anchor-review` §4）

本文件完整內嵌 `zdpos-anchor-review` 的 §4 檢查規則（只判新增或修改區塊，測試檔一併適用），判定不依賴目標分支是否存在 `CODING_STANDARDS.md` 等規範檔。

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
9. **前端 JS**：新增或修改優先使用 ES6 原生語法，僅在存取既有頁面之 jQuery 元件時方可使用 jQuery。判定時：新檔與新抽出的 leaf 必須 ES6 原生；修改既有 jQuery 檔跟隨原檔風格，不列違規；從巨檔機械抽出（`zdpos-js-modernization`）維持 IIFE + `var`。（出處：`.claude/rules/frontend.md` Hard Limits、`js/AGENTS.md`）
10. **方法放置**：新增方法預設加在檔案最下端；同領域之方法群可就近集中於相關既有方法旁以維持內聚性；常數與屬性放類別頂端，不夾在方法之間。（出處：CODING_STANDARDS §9）
11. **Policy 形狀**：Domain 決策類一律放 `domain/Policies/`（namespace `Domain\Policies`，不依模組切子目錄）；instance-based，不寫 static；決策動詞一律 `passes()`，true = 放行，不放行訊息用 `message()`（對齊 Laravel Rule 物件）；同一次 request 內固定的環境值進 constructor，決策方法只吃被判定的標的。（出處：`.claude/rules/php/patterns.md` Policy 類落點與形狀）
12. **catch 慣例**：每個 `catch (\Exception $e)` 都要同時呼叫 `ExceptionLogHelper::logCaughtExceptionToApplication()` 與領域 logger；不得空 catch 或只寫 `// ignore`。（出處：`.claude/rules/php/patterns.md` Exception Logging、技能 `zdpos-php-patterns`）
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

正確性（如批次標記競態）改用 code-reviewer；PDO、CSRF、授權改用 security-reviewer；ESLint tier 與 `@ts-check` 改用技能 `zdpos-js-modernization`。
