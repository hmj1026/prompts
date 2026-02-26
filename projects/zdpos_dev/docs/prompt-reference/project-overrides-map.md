# Prompt Reference / Project Overrides Map

本表用於落實「Yii 內建不敷使用時，優先沿用專案既有改寫方法」規則。

## 專案常見改寫方法對照表

| 使用情境 | Yii 內建/一般寫法 | 專案優先改寫方法 | 位置/索引 | 備註 |
| :--- | :--- | :--- | :--- | :--- |
| 前端非同步請求（POS 主流程） | `$.ajax` / `fetch` / `axios` | `POS.list.ajaxPromise()` | `js/zpos.js` | 專案硬性限制，禁用 `$.ajax`/`fetch`/`axios` |
| 資料存取（Repository 層） | `Yii::app()->db->createCommand()` | `EntityRepository::createCommand()` / `queryAll()` / `queryRow()` | `infrastructure/Repositories/EntityRepository.php` | 先沿用 Repository 基底封裝 |
| DB Command（跨層/舊碼相容） | `Yii::app()->db->createCommand()` | `UnitOfWork::createCommand()` | `infrastructure/Context/UnitOfWork.php` | 已有 UnitOfWork 流程時優先沿用 |
| Controller Request 取值 | `$_POST` / `$_GET` | `Yii::app()->request->getPost()/getParam()/getQuery()` | `protected/components/Controller.php`（含 request 包裝） | 符合 `CLAUDE.md` 限制 |
| Controller 權限檢查 | 自行撰寫判斷 | `checkPermission()` / `filterCheckPermission()` | `protected/components/Controller.php` | 先沿用現有權限機制 |
| JSON 回應結束流程 | `echo json_encode(...); exit;` | `echo CJSON::encode(...); Yii::app()->end();` | 多數 `protected/controllers/*.php` | 保持 Yii 生命週期一致 |

## 使用規則
1. 先找是否已有「同責任」改寫方法（`rg` 搜尋目錄與 call site）。
2. 找得到就擴充既有方法，不平行新增第二套封裝。
3. 找不到才新增封裝，並補上對照表。
4. 新封裝需在子目錄 `AGENTS.md` 或本檔補一行索引，避免知識遺失。

## 快速搜尋指令
```bash
rg -n "ajaxPromise|createCommand\(|queryAll\(|queryRow\(|UnitOfWork::createCommand|checkPermission|filterCheckPermission|CJSON::encode|Yii::app\(\)->end\(" js infrastructure protected
```
