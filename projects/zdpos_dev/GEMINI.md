# Gemini AI 開發規則：

## 專案
- **專案名稱:** zdpos_dev
- **專案描述:** 這是一個基於 Yii 1.1 框架的 POS 系統，包含前端與後端功能，並採用 DDD-Like 分層架構。

## 建置與執行

**本地開發環境:**

*   **開發工具:** Laragon 8.0
*   **Web 伺服器:** Apache 2.4.62
*   **PHP:** 5.6.40
*   **資料庫:** MySQL 5.7.33
*   **作業系統:** Windows 10
*   **專案路徑:** `D:\projects\zdpos_dev`
*   **版本控制:** Git (本地儲存庫位於 `D:\projects\zdpos_dev\.git`)
*   **應用程式路徑:** `D:\laragon\www\www.zdpos\dev3` (與 `zdpos_dev` 同層級)
*   **資料庫:** `zdpos_dev_2` (MySQL)
*   **資料庫連線設定:** 位於 `zdpos_dev/protected/config/dev3.php` (組態中 `db` 元件)
*   **網站連結:**  `https://www.zdpos.test/dev3`
*   **設定檔路徑:** `D:\projects\zdpos_dev\protected\config\dev3.php` (因為 `dev3` 目錄透過軟連結與 `zdpos_dev` 同層級)
*   **專案結構:** `D:\projects\zdpos_dev\gemini\zdpos_dev_tree.txt`

## 專案速查表 (Project Cheatsheet)

- **專案核心:** `zdpos_dev` (Yii 1.1 函式庫)
- **應用程式入口:** `dev3/index.php` (與 `zdpos_dev` 同層級)
- **本地網址:** `https://www.zdpos.test/dev3`
- **主要設定檔:** `protected/config/dev3.php`
- **主要資料庫:** `zdpos_dev_2` (MySQL 5.7)
- **版本控制:** Git
- **專案結構:** `D:\projects\zdpos_dev\gemini\zdpos_dev_tree.txt`

### 關鍵目錄結構
- **Controllers:** `protected/controllers/`
- **Models:** `protected/models/`
- **Views:** `protected/views/`
- **Migrations:** `protected/migrations/` (資料庫結構變更來源)
- **核心函式庫:** `protected/components/zdnbase/`
- **POS 前端核心 JS:** `assets/zpos/zpos.js`
- **業務邏輯 (Domain):** `protected/domain/`
- **基礎設施 (Infrastructure):** `protected/infrastructure/`

## 架構與模式藍圖 (Architecture & Patterns)

### 1. 後端架構 (Backend)
- **核心框架:** Yii 1.1 MVC。
- **基礎控制器:** `protected/components/Controller.php` (所有 Controller 的父類別，整合了權限檢查與 `zdnbase`)。
- **核心工具庫 (`zdnbase`):**
    - **用途:** 提供全域共用函式，如日誌、路徑管理、DB存取。
    - **呼叫方式:** 透過基底控制器 `Controller.php` 繼承的方法或直接使用。
- **權限系統:**
    - **機制:** 基於權限碼 (Permission Code)。
    - **權限定義:** `zdn_menu` 資料表。
    - **使用者權限:** `data_employee.employee_permission` 欄位。
    - **檢查邏輯:** `Controller::filterCheckPermission` (自動在 Action 執行前觸發)。
- **分層架構 (DDD-Like):**
    - **`domain`:** 純業務邏輯，**禁止**包含任何 Yii 框架依賴。定義 `Entities`, `Services`, `Repository Interfaces`。
    - **`infrastructure`:** 實現 `domain` 的介面，負責與外部（DB, API）溝通。**可以**使用 Yii 的 `CActiveRecord` 等框架功能。

### 2. 前端架構 (Frontend - zpos.js)
- **核心物件:** 全域物件 `POS`。
- **狀態管理:** `POS.thread.step` 屬性控制當前操作流程 (例如：`1`=銷售, `6`=結帳)。
- **伺服器通訊:**
    - **方法:** `POS.post(action, data, callback)`。
    - **目標:** `PosController.php` 的 `action<Name>` 方法。
    - **格式:** 前端發送 AJAX POST，後端返回 JSON。

### 3. 完整交易流程 (範例)
1.  **前端:** `zpos.js` 收集訂單資料。
2.  **前端 -> 後端:** 呼叫 `POS.post('saveReceipt', orderData, ...)`。
3.  **後端 (Controller):** `PosController::actionSaveReceipt()` 接收請求。
4.  **後端 (分層):** `actionSaveReceipt` 呼叫 `Domain\Services\OrderService`。
5.  **後端 (Domain):** `OrderService` 執行業務邏輯，並呼叫 `Domain\Interfaces\OrderRepository->save()`。
6.  **後端 (Infrastructure):** `Infrastructure\YiiOrderRepository->save()` 使用 `CActiveRecord` 將資料寫入資料庫。
7.  **後端 -> 前端:** `PosController` 回傳 JSON 結果，例如 `{"success": true}`。
8.  **前端:** `POS.post()` 的回呼函式處理 JSON 結果，更新 UI (例如，呼叫 `saleThread.init()` 清空畫面)。