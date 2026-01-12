# AGENTS.md

本檔提供「程式代理人」在本儲存庫工作的精簡指引。完整規範請參考 `CLAUDE.md`。

<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

---

## 指令優先序
1. 系統/平台指令
2. `CLAUDE.md`
3. 本檔
4. 使用者需求
5. 其他專案文件

---

## 語言與溝通
- 回應語言：正體中文
- 程式註解：正體中文
- 專有名詞保留英文 (Controller, Model, View, Action)
- 先給結論或建議，再補必要細節；不要輸出內部推理

---

## 建置、測試、Linting 指令

## 常用指令 (Docker/開發環境)

### Database Migrations
```bash
# 建立 Migration (需指定名稱)
docker exec -w //var/www/www.posdev/zdpos_dev pos_php php protected/yiic.php migrate create [Name]

# 執行 Migration (Up)
docker exec -w //var/www/www.posdev/zdpos_dev pos_php php protected/yiic.php migrate up
```

### 測試與驗證
```bash
# 執行單元測試
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit [Test_Path]
```

### 程式碼檢查
```bash
# 專案無 linting 工具，手動檢查以下規範
# 1. PHP 語法檢查：php -l [檔案路徑]
# 2. JavaScript 語法檢查：node --check [檔案路徑]
```

---

## 程式碼風格指南

### PHP 規範 (Yii 1.1 + PHP 5.6)
- **類別命名**：PascalCase (例：`CustomerController`, `DataItem`)
- **方法命名**：camelCase (例：`actionIndex()`, `getCustomerData()`)
- **變數命名**：camelCase (例：`$customerData`, `$isActive`)
- **常數命名**：UPPER_SNAKE_CASE (例：`const SEQUENCE_TYPE = 'CR'`)
- **陣列語法**：使用 `[]`，禁用 `array()`
- **POST 資料**：使用 `Yii::app()->request->getPost('key')`，禁用 `$_POST`
- **ActiveRecord**：必須包含 `public static function model($className=__CLASS__)`
- **PHPDoc**：完整註解，包含 `@param`, `@return`, `@property`

### JavaScript 規範 (ES6)
- **全域物件**：使用 `POS` 作為單一真相來源
- **AJAX 請求**：必須使用 `POS.list.ajaxPromise()`，禁用 `$.ajax`, `fetch`, `axios`
- **JSDoc**：完整類型定義，使用 `@typedef`, `@namespace`
- **模組系統**：使用 IIFE 模式，避免 ES6 modules

### 命名慣例
| 類型 | 格式 | 範例 |
|------|------|------|
| Controllers | PascalCase + "Controller" | `SiteController`, `CustomerController` |
| Models | PascalCase | `Customer`, `DataItem` |
| Actions | "action" + PascalCase | `actionIndex()`, `actionCreate()` |
| Views | lowercase | `index.php`, `create.php` |
| Helpers | PascalCase + "Helper" | `CommonHelper`, `DateHelper` |
| Services | PascalCase + "Service" | `CustomerService`, `PaymentService` |

### 檔案結構規範
```
protected/
├── controllers/     # MVC Controllers
├── models/         # Yii ActiveRecords
├── views/          # MVC Views
├── helpers/        # Helper classes
├── tests/          # 測試檔案
│   ├── unit/       # 單元測試
│   ├── functional/ # 功能測試
│   └── fixtures/   # 測試資料
├── extensions/     # Yii 擴充
└── vendors/        # 第三方套件
```

---

## 核心開發哲學
1. 單一真相來源 (SSOT)：每個概念只有一個權威實作，延展既有邏輯，不複製。
2. 先讀後寫：使用 `rg`/`fd` 研究既有模式，先規劃再動手。
3. 簡潔明瞭：清楚意圖 > 花俏程式。遵循 SOLID (尤其 SRP) 和 DRY。
4. 漸進執行：複雜任務拆解 (>3 步驟先寫計畫)，小步提交確保可編譯、可測試。
5. 測試驅動 (TDD)：Red → Green → Refactor。

---

## Anti-Loop Protocol (防卡死機制)
重要：同一問題連續失敗 3 次，立即停止：
1. 記錄：列出嘗試內容、錯誤訊息、假設
2. 研究：從文件或類似程式碼找 2-3 個替代方案
3. 轉向：簡化問題、改變抽象層級、換方法

---

## 專案語法規範

| 類別 | 規範 |
|------|------|
| PHP 陣列 | 使用 `[]` 語法，禁用 `array()` |
| 陣列操作 | 優先 `array_map`、`array_filter`，避免巢狀 `foreach` |
| POST 存取 | 使用 `Yii::app()->request->getPost()`，禁用 `$_POST` |
| JavaScript | 使用 ES6 語法 |
| PHP 版本 | 相容 PHP 5.6 |
| Null Coalescing | 禁用 `??`，使用 `isset($var) ? $var : $default` |
| 型別提示 | 禁用純量型別提示，使用 PHPDoc |
| 回傳型別 | 禁用 `: void`，使用 PHPDoc `@return void` |

---

## 工具選擇指南

| 任務 | 工具 | 說明 |
|------|------|------|
| 找檔案 | `fd` / Glob | 快速模式比對 |
| 搜程式碼 | `rg` (ripgrep) | 優化的正規搜尋 |
| 讀大檔案 | `head`/`tail` 或分段讀取 | 避免一次載入過多 |
| JSON/YAML | `jq` / `yq` | 結構化資料處理 |
| 程式結構 | `ast-grep` | AST 層級搜尋 |

---

## 規劃模式 (Planning Protocol)
當需求涉及多檔案修改、架構變更或複雜邏輯時：
1. Plan Phase：分析需求，輸出實作計畫
2. Confirmation：等待用戶確認「Go」
3. Execution Phase：用戶確認後才開始寫程式

---

## Docker 測試指令
```bash
# Windows Git Bash 相容格式
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit [Test_Path]

# 範例
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/unit/YosvipRedeemPointRequestTest.php
```

## 測試規範

### 測試檔案命名
- 單元測試：`[ClassName]Test.php` (例：`CustomerServiceTest.php`)
- 功能測試：`[FeatureName]FunctionalTest.php`
- 測試基類：繼承 `TestCase` 或 `DbTestCase`

### 測試結構
```php
<?php
namespace application\tests\unit\[Namespace];

use PHPUnit\Framework\TestCase;

/**
 * [ClassName] 單元測試
 *
 * @package Tests\Unit\[Namespace]
 */
class [ClassName]Test extends TestCase
{
    // 測試方法命名：test[功能描述]
    public function test[FunctionName]()
    {
        // Arrange - 準備測試資料
        // Act - 執行測試動作
        // Assert - 驗證結果
    }
}
```

---

## 錯誤處理規範

### PHP 錯誤處理
- 使用 Yii 的例外處理機制
- 自訂例外繼承 `CException`
- 記錄錯誤使用 `Yii::log()` 或 `Yii::error()`

### JavaScript 錯誤處理
- 使用 Promise 的 `.catch()` 處理非同步錯誤
- 全域錯誤記錄到 `POS.error.log`

---

## 詳細參考
- `CLAUDE.md`：專案架構與背景資訊、PHP 5.6 限制、Yii 1.1 慣例、命名規範與 PHPDoc/JSDoc 要求
- `phpunit.xml`：測試配置檔案
- `protected/tests/bootstrap.php`：測試環境設定
- 若本檔與 `CLAUDE.md` 有出入，以 `CLAUDE.md` 為準。
