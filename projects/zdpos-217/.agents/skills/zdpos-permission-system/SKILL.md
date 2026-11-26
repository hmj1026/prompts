---
name: zdpos-permission-system
description: permission 後台選單權限（非前台 POS 結帳）。Use when 修改 checkPermission / filterCheckPermission、選單可見性（isItemVisible）、employee_permission（群組 vs 個別 item token）或雙 level 閘。
allowed-tools: Read, Grep, Glob, Bash(cx *)
---

# zdpos 選單權限系統（menu permission）

## 資料模型

- **`zdn_menu`**：選單定義表。`type` 0=分類 / 1=可導覽項；`permission`=整組權限 key；`controller`/`action`=路由；`show`。
  - **連動**：多個選單項共用同一 `permission` key（線上 15 組各 2–11 項）。該 key 同時作為**儲存單位**（`data_employee.employee_permission` CSV）與**驗證單位**（`checkPermission` / `filterCheckPermission`），因此純前端無法拆開連動項（memory `trap_menu_permission_shared_key_linkage`）。
  - 同 key 可跨不同 controller/action：例如 `system/permission`（選單權限設定）與 `system/station`（登入機號管理）共用 `permission` key（migration `m170630_065721`）。
- **`data_employee.employee_permission`**：CSV 字串。
- **Item token**：`zdn_menu::buildItemToken($controller, $action)` 回傳 `@<controller>/<action>`（prefix `@` 定義於 `ITEM_TOKEN_PREFIX`，與真實 key 零碰撞）。

## 兩種模式（員工級單一總開關）

| 模式 | CSV 樣態 | 驗證單位 |
|---|---|---|
| **群組**（legacy，既有員工預設） | 純整組 key：`processing,rd_search,...`（無 `*individual`） | 整組 key membership（`in_array`）；新增同 key 項目自動涵蓋 |
| **個別**（新員工預設） | `*individual` + 各授權項 `@controller/action` token + 各組整組 key（D2 rollback 安全網，live 忽略） | per-item token；新增項目須明確授權（不自動涵蓋） |

- 標記常數：`MenuAccessPolicy::INDIVIDUAL_MARKER = '*individual'`。
- 既有員工維持原模式，僅對新員工預設啟用個別模式（避免既有資料 churn）。

## Enforcement SSOT（唯一決策點：`MenuAccessPolicy::decide`）

`protected/components/MenuAccessPolicy.php::decide($permissions, $level, $itemToken, $groupKey)`：
- 群組模式 → `in_array($groupKey, $permissions)`（向後相容）。
- 個別模式 → per-item token 比對；超管救援見下節。

兩條消費路徑皆同源 `decide`，確保「看得到 ⟺ 進得去」：
1. **可見性**：`Menu::getMenu()` → `Menu::isItemVisible()`（`protected/models/Menu.php`）→ `decide`。個別模式下，分類須含 ≥1 個可見子項才顯示（umbrella key 不寫入 CSV）。
2. **存取**：`Controller::userCanAccessMenuItem()` → `decide`，由 inline `checkPermission()` 與 middleware `filterCheckPermission()` 共用。
   - **路由→權限 key**：`getNowMenuPermissionV2()`（`MenuRepository::findPermissionsByRoute`）僅於唯一命中時採用；0 筆或 2+ 筆回傳 `PERMISSION_UNDEFINED` 安全攔截。
   - **路由解析**：`resolveCurrentMenuRoute()` 一律取 `Yii::app()->controller`（而非 `$this`）——`ZadminController::actionInit` 以 `new Controller(uniqid())` 拋棄式實例呼叫 `checkPermission`，無 action context；改取 `$this` 會 fallback `defaultAction` 導致 token 推導錯誤而誤擋報表頁。（memory `trap_zadmin_throwaway_controller_checkpermission`）

## 雙 level 閘

碼基內有**兩套獨立的 level 閘**，實作與審查時依所屬閘別獨立判斷，兩者互不推導：

| 閘別 | 判式 | 語意 |
|---|---|---|
| **選單權限 / 多數功能閘**（~13 處：stock 進價、paytype、accounting、permission save…） | 精確 `getLevel() === 1` | 1 = 管理員／總店最高權人員；default 10 = guest |
| **DataTable / ztable 編輯閘** | 連續 `column->edit >= getLevel()` | 數字越小權限越高（0 最高、10 最低）；level 0 可編 `edit:0` 欄位 |

- `888` 帳號的數字 level 依商家庫而異（dev4 `zdpos_dev_2` 為 level 0 超管；本功能 QA 測試 fixture `TPERMA` 為 level 1）。驗證 level-based gate 的 RED→GREEN 一律使用 integration test 模擬高 level，以可控 fixture 取代 `888` E2E。（memory `trap_datatable_edit_level_gate_and_dev4_888`）

## level-1（超管）救援：以 per-item token 放行

2026-06-26 QA 決議超管亦依儲存設定受控，僅保留「選單權限」設定頁救援以防自我鎖死：
- **`decide`**：以 `level === 1 && $itemToken === MenuAccessPolicy::PERMISSION_PAGE_ITEM_TOKEN`（`'@system/permission'`）放行；僅用 per-item token、嚴禁用整組 key `'permission'`（否則同享該 key 的 `system/station` 會外洩）。token parity 由 `PermissionConstantsTest::testPermissionPageItemToken_matchesBuiltToken` 鎖定。
- **`checkPermission` 的 `PERMISSION_UNDEFINED` fallback**：以 `$site === PERMISSION_PAGE_GROUP_KEY`（`'permission'`）放行——該處 `$site` 為寫死引數，唯一傳入 `'permission'` 者為 `SystemController::actionPermission`，故範圍受控。
- **範圍界線**：救援僅授權「進入／可見」；`actionPermission` 的 save/reset 仍獨立檢查 `getLevel() === 1`。
- （memory `trap_permission_rescue_scope_by_item_token`）

## 後台 JS 陣列走訪慣例

後台 JS 走訪陣列一律使用 index `for` 或 `forEach`（嚴禁 `for...in`——`js/phpjs.js` 對 `Array.prototype` 加上可列舉的 `insert()`，`for...in` 會將其視為陣列元素引發 `.charAt` 等 TypeError 中斷 callback，導致 `system/permission` `#wait` 永久轉動）。（memory `trap_forin_array_prototype_insert`）

## 關鍵檔案

| 角色 | 檔案 |
|---|---|
| 決策 SSOT（純函式） | `protected/components/MenuAccessPolicy.php` |
| 可見性 | `protected/models/Menu.php`（`getMenu` / `isItemVisible`） |
| 存取 + 路由解析 | `protected/components/Controller.php`（`checkPermission` / `filterCheckPermission` / `userCanAccessMenuItem` / `getNowMenuPermissionV2` / `resolveCurrentMenuRoute`） |
| 路由→key SQL | `infrastructure/Repositories/MenuRepository.php` |
| 設定頁（save/reset，gate `===1`） | `protected/controllers/SystemController.php::actionPermission` + `protected/views/system/permission.php` + `js/permission.js` |
| 測試 | `protected/tests/unit/Permission/` + `protected/tests/integration/Permission/`（含 `PermissionConstantsTest` token parity） |

## 改動完成條件

每項權限改動結束時須全部成立：

- 可見性（`Menu::isItemVisible`）與存取（`checkPermission` / `filterCheckPermission`）皆同源 `MenuAccessPolicy::decide`，無平行授權判斷。
- 群組模式維持既有 CSV `in_array` membership，既有員工資料零自動遷移。
- 每個新增或修改的 level 判斷皆明確對應所屬閘別（`getLevel() === 1` 或 DataTable `column->edit >= getLevel()`）。
- 所有救援或例外放行皆以 per-item token 判定，無共用整組 key 放行。
- 後台 JS 陣列走訪全數使用 index `for` 或 `forEach`（零 `for...in`）。
- `protected/tests/unit/Permission/` 與 `protected/tests/integration/Permission/` 全數通過（含 `PermissionConstantsTest`），且權限改動經 `code-reviewer` 與 `security-reviewer` 審查。
