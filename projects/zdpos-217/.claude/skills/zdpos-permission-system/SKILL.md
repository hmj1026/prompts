---
name: zdpos-permission-system
description: zdpos 後台選單權限（menu permission）領域模型與 enforcement SSOT — 群組 vs 個別模式、`*individual` + `@controller/action` token 格式、`zdn_menu.permission` 共用 key「連動」、雙 level 制度（`=== 1` 管理員精確值 vs DataTable `>= getLevel()` 連續制、888 依商家庫）、level-1 救援以 per-item token 判定、ZadminController 拋棄式實例驗權、後台 JS `for...in` array 陷阱。Use when 改 / 查 system/permission · maintain/permission · 選單權限 · employee_permission · checkPermission · filterCheckPermission · getNowMenuPermissionV2 · MenuAccessPolicy · Menu::getMenu / isItemVisible · 個別/群組模式 · 權限繞過 / 看得到進得去 · 員工權限等級 level。Not for：純業務邏輯 / 非權限的 Controller·Model·View 編輯、前台 POS 結帳、報表計算（即使句中出現 controller/action/level 等字）。
allowed-tools: Read, Grep, Glob, Bash(cx *)
---

# zdpos 選單權限系統（menu permission）

> 後台「選單權限」(`system/permission`) 的領域模型 + enforcement 匯流點 SSOT。改任何權限驗證 / 選單可見性前先讀本檔，避免重蹈散落 memory trap 的坑。

## 資料模型

- **`zdn_menu`**：選單定義表。`type` 0=分類 / 1=可導覽項；`permission`=整組權限 key；`controller`/`action`=路由；`show`。
  - 「**連動**」＝**多個選單項共用同一 `permission` key**（線上 15 組各 2-11 項）。該 key 同時是 **儲存單位**（`data_employee.employee_permission` CSV）與 **驗證單位**（`checkPermission` / `filterCheckPermission`）。⚠️ 同 key 可跨不同 controller/action：例 `system/permission`（選單權限設定）與 `system/station`（登入機號管理）**共用 `permission` key**（migration `m170630_065721`）。
- **`data_employee.employee_permission`**：CSV。
- **`zdn_menu::buildItemToken($controller,$action)`** = `@<controller>/<action>`（prefix `@` 為 `ITEM_TOKEN_PREFIX`，與真實 key 零碰撞）。

## 兩種模式（以員工為單位的單一總開關）

| 模式 | CSV 樣態 | 驗證單位 |
|---|---|---|
| **群組**（legacy，預設既有員工） | 純整組 key：`processing,rd_search,...`（無 `*individual`） | 整組 key membership（`in_array`）；新增同 key 項目自動涵蓋 |
| **個別** | `*individual` + 各授權項 `@controller/action` token + 各組整組 key（D2 rollback 安全網，live 忽略） | per-item token；新增項目**不**自動授權 |

- 標記常數：`MenuAccessPolicy::INDIVIDUAL_MARKER = '*individual'`。
- 既有員工不被自動轉換（無 churn）；新員工預設個別。

## Enforcement SSOT（唯一決策點：`MenuAccessPolicy::decide`）

`protected/components/MenuAccessPolicy.php::decide($permissions, $level, $itemToken, $groupKey)`：
- 群組模式 → `in_array($groupKey, $permissions)`（向後相容）。
- 個別模式 → per-item token 比對；**例外救援**見下。

兩條消費路徑（皆同源 `decide`，故「看得到 ⟺ 進得去」）：
1. **可見性**：`Menu::getMenu()` → `Menu::isItemVisible()`（`protected/models/Menu.php`）→ `decide`。個別模式分類「有 ≥1 可見子項才顯示」（umbrella key 不在 CSV）。
2. **存取**：`Controller::userCanAccessMenuItem()` → `decide`，由 **inline `checkPermission()`** 與 **middleware `filterCheckPermission()`** 共用。
   - 路由→權限 key：`getNowMenuPermissionV2()`（`MenuRepository::findPermissionsByRoute`，唯一命中才採用，0/2+ → `PERMISSION_UNDEFINED` 安全攔截）。
   - 路由解析：`resolveCurrentMenuRoute()` 一律用 `Yii::app()->controller`（**非** `$this`）——因 `ZadminController::actionInit` 以 `new Controller(uniqid())` 拋棄式實例呼叫 checkPermission，無 action context；用 `$this` 會 fallback defaultAction → token 推導錯誤 → 報表頁誤擋。（memory `trap_zadmin_throwaway_controller_checkpermission`）

## 雙 level 制度（易混淆，務必分清）

本碼基有**兩套不相干的 level 閘**：

| 閘 | 判式 | 語意 |
|---|---|---|
| **選單權限 / 多數功能閘**（~13 處：stock 進價、paytype、accounting、permission save…） | **精確 `getLevel() === 1`** | 1 = 「管理員 / 總店最高權人員」。default 10 = guest。 |
| **DataTable / ztable 編輯閘** | **連續 `column->edit >= getLevel()`** | **數字越小權限越高**（0 最高、10 最低）；level 0 可編 `edit:0` 欄位。 |

- ⚠️ 兩者並存、勿互推：選單權限用「**等於 1**」不是「≤1」；DataTable 用「**≥ 比較**」。
- `888` 帳號的數字 level **依商家庫不同**（dev4 `zdpos_dev_2` 為 level 0 超管；本功能 qa 測試 fixture TPERMA 用 level 1）。要證 level-based gate 的 RED→GREEN 用 integration test 模擬高 level，別靠 888 E2E。（memory `trap_datatable_edit_level_gate_and_dev4_888`）

## level-1（超管）救援：以 per-item token，非整組 key

2026-06-26 QA 反轉「level-1 個別模式全通」→ 超管亦照儲存設定；**僅**保留「選單權限」設定頁救援以免自我鎖死：
- `decide`：`level===1 && $itemToken === MenuAccessPolicy::PERMISSION_PAGE_ITEM_TOKEN('@system/permission')` → 放行。**禁用整組 key `'permission'`**——`system/station` 同享該 key，會外洩。parity 由 `PermissionConstantsTest::testPermissionPageItemToken_matchesBuiltToken` 鎖定。
- `checkPermission` 的 `PERMISSION_UNDEFINED` fallback 例外用 `$site === PERMISSION_PAGE_GROUP_KEY('permission')`——該處 `$site` 是寫死引數，唯一傳 `'permission'` 者為 `SystemController::actionPermission`，故安全。
- 救援只給「進入/可見」；`actionPermission` 的 save/reset 仍獨立 gate `getLevel()===1`。
- （memory `trap_permission_rescue_scope_by_item_token`）

## 前端陷阱

- **後台 JS 禁 `for...in` over array**：`js/phpjs.js` 對 `Array.prototype` 加可列舉 `insert()`，for-in 會把它當元素 → `.charAt` 等呼叫 TypeError 中斷 callback（`system/permission` 載入 #wait 永久轉動即此症）。一律 index for / `forEach`。（memory `trap_forin_array_prototype_insert`）
- 共用同一 `permission` key 的選單項「連動」純前端無法解（key 同時是儲存+驗證單位）。（memory `trap_menu_permission_shared_key_linkage`）

## 關鍵檔案

| 角色 | 檔 |
|---|---|
| 決策 SSOT（純函式） | `protected/components/MenuAccessPolicy.php` |
| 可見性 | `protected/models/Menu.php`（`getMenu` / `isItemVisible`） |
| 存取 + 路由解析 | `protected/components/Controller.php`（`checkPermission` / `filterCheckPermission` / `userCanAccessMenuItem` / `getNowMenuPermissionV2` / `resolveCurrentMenuRoute`） |
| 路由→key SQL | `infrastructure/Repositories/MenuRepository.php` |
| 設定頁（save/reset，gate `===1`） | `protected/controllers/SystemController.php::actionPermission` + `protected/views/system/permission.php` + `js/permission.js` |
| 測試 | `protected/tests/unit/Permission/` + `protected/tests/integration/Permission/`（含 `PermissionConstantsTest` token parity） |

## 改動前 checklist

1. 動 `decide` / `checkPermission` / `filterCheckPermission` / `isItemVisible` → 確認可見性與存取**同源**，群組模式維持 byte-identical（零回歸）。
2. 任何 level 判斷 → 先確認用哪套閘（`===1` vs `>=`）。
3. 新增「救援 / 例外放行」→ 以 per-item token（唯一 controller/action）判定，**勿用共用整組 key**（會外洩到同 key 項目）。
4. 改完跑 `protected/tests/{unit,integration}/Permission/` + code-reviewer + security-reviewer（權限=auth）。
