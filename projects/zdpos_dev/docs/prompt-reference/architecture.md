# Prompt Reference / Architecture

## 架構概觀
- 架構：Yii 1.1 + DDD-like 分層
- PHP 版本：5.6.40（Legacy）
- 前端：Legacy POS（Raw ES6，無 build step）
- 資料庫：`zdpos_dev_2`（MySQL 5.7.33）
- 本機網址：`https://www.posdev.test/dev3`
- 安全：資料庫操作必須使用 PDO prepared statements
- 本地開發環境使用 docker 容器開發

## 入口與啟動
- Web 入口：`index.php`（建立 Yii WebApplication）。
- Console 入口：`protected/yiic.php`（載入 `protected/config/console.php`）。
- 環境設定：`protected/config/*.php`（例如 `dev3.php`）。

## 分層責任與依賴方向
- Interface Layer：`protected/controllers`、`protected/views`、`protected/modules/*`
- Domain Layer：`domain/*`（Services/Entities/ValueObjects/DTOs）
- Infrastructure Layer：`infrastructure/*`（Repositories/Http/Context/Exceptions/Utility）
- Legacy Data Models：`protected/models/*`（Yii ActiveRecord）
- 依賴方向建議：`Interface -> Domain -> Infrastructure`；避免反向耦合。

責任邊界：
- `Controller/Module`：請求處理、權限檢查、流程編排。
- `Domain`：業務規則與領域語意，不耦合框架細節。
- `Infrastructure`：DB/API/I/O 技術細節與適配。
- `Model(AR)`：既有資料映射與舊流程相容；新業務規則優先放 Domain Service。

## 架構路由地圖（從需求反查入口）
- POS 結帳/交易流程：`js/zpos.js` -> `protected/controllers/PosController.php` -> `domain/Services` -> `infrastructure/Repositories`
- 後台 CRUD/維護頁：`protected/controllers/*Controller.php` + `protected/views/*` + `protected/models/*`
- 外部平台/API 整合：`protected/modules/api`、`domain/*/{Requests,Responses,Services}`、`infrastructure/Http`
- 報表/列印：`domain/Documents`、`domain/Reports`、`protected/views/report*`
- 測試對應：`protected/tests/{unit,functional,Domain,infrastructure}`

## 架構與檔案地圖
前端入口以 `js/zpos.js` 為主；`js/` 內含歷史與外掛資產，變更前請先確認用途。

| 目錄 | 用途 | 規範 |
| :--- | :--- | :--- |
| `protected/models/` | Yii ActiveRecords | `class Post extends CActiveRecord` |
| `protected/controllers/` | MVC Controllers | `class SiteController extends Controller` |
| `protected/helpers/` | Helpers | `class CommonHelper` |
| `domain/` | Business Logic | Domain Service/Use Case（DDD-like，避免耦合 Yii） |
| `infrastructure/Repositories/` | Data Access | Namespace `Infrastructure\\Repositories` |
| `js/zpos.js` | Frontend Entry | POS 入口（主要入口檔） |

## 子目錄 AGENTS 索引
- `protected/AGENTS.md`：protected 全域導覽與共通後端慣例
- `protected/controllers/AGENTS.md`：Controller 實作慣例
- `protected/models/AGENTS.md`：ActiveRecord 規範
- `protected/views/AGENTS.md`：View/資產與前端限制
- `protected/components/AGENTS.md`：共用元件與基底類別
- `protected/modules/AGENTS.md`：各 module 結構與實作慣例
- `protected/tests/AGENTS.md`：測試結構、命名、執行方式
- `domain/AGENTS.md`：Domain 層命名、結構與責任
- `infrastructure/AGENTS.md`：Repository/HTTP/Utility 慣例
- `js/AGENTS.md`：Legacy POS 前端與 `zpos.js` 注意事項

## Prompt 對齊檢查清單
- 先讀 `CLAUDE.md`（規範）與本檔（架構）再動手。
- 先用 `rg` 搜尋既有流程與同類實作，再決定插入點。
- 跨層修改時，標示「入口層、業務層、資料層」各自變更原因。
- 涉及 DB 或 API 契約調整時，先判斷是否觸發 OpenSpec 邊界。
- 輸出回報維持：`結論 -> 變更檔案 -> 驗證 -> 風險/待確認`。
