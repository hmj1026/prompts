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

# Project Context: zdpos_dev

> **Note**: These project-specific rules override general guidelines where conflicts occur.

## 指令優先序
1. 系統/平台指令
2. 本檔
3. `AGENTS.md`
4. 使用者需求
5. 其他專案文件

## 溝通規則
- 回應語言：正體中文
- 程式註解：正體中文
- 專有名詞保留英文 (Controller, Model, View, Action)
- 先給結論或建議，再補必要細節；不要輸出內部推理

## 核心原則
- 單一真相來源 (SSOT)：每個概念只有一個權威實作，延展既有邏輯，不複製。
- 先讀後寫：使用 `rg`/`fd` 研究既有模式，先規劃再動手。
- 簡潔明瞭：清楚意圖 > 花俏程式。遵循 SOLID (尤其 SRP) 和 DRY。
- 漸進執行：複雜任務拆解 (>3 步驟先寫計畫)，小步提交確保可編譯、可測試。
- 測試驅動 (TDD)：Red → Green → Refactor。

## 架構概觀
- 架構：Yii 1.1 + DDD-like 分層。
- PHP 版本：5.6.40（Legacy）。
- 前端：Legacy POS（Raw ES6，無 build step）。
- 資料庫：`zdpos_dev_2`（MySQL 5.7.33）。
- 本機網址：`https://www.zdpos.test/dev3`。
- 安全：資料庫操作必須使用 PDO prepared statements。

## 嚴格環境限制 (PHP 5.6)
| 禁止 | 替代方案 / 要求 |
|------|------------------|
| `??` (Null Coalescing) | 使用 `isset($var) ? $var : $default` |
| 純量型別提示 `function(int $id)` | 使用 PHPDoc `@param int $id` |
| 回傳型別 `: void` | 使用 PHPDoc `@return void` |
| 直接存取 `$_POST` | 使用 `Yii::app()->request->getPost()` |

其他要求：
- PHP 陣列使用 `[]`，禁用 `array()`。
- ActiveRecord 必須包含：`public static function model($className=__CLASS__) { return parent::model($className); }`

## 檔案系統限制
- 專案根目錄 `E:\projects\zdpos_dev\` 視為唯讀。
- 可寫入位置：`E:\projects\www.posdev\dev3` (Web Root)；必要時可使用 `output/` 產出檔案。
- 相對路徑需考量 Web Root 結構。

## 前端限制
- 禁用 `$.ajax`、`fetch`、`axios`。
- 必須使用 `POS.list.ajaxPromise()` 進行非同步請求。
- 全域 `POS` 物件為單一真相來源。
- 語法：ES6。

## 架構與檔案地圖
> 前端入口以 `js/zpos.js` 為主；`js/` 內含歷史與外掛資產，變更前請確認用途。

| 目錄 | 用途 | 規範 |
| :--- | :--- | :--- |
| `protected/models/` | Yii ActiveRecords | `class Post extends CActiveRecord` |
| `protected/controllers/` | MVC Controllers | `class SiteController extends Controller` |
| `protected/helpers/` | Helpers | `class CommonHelper` |
| `domain/` | Business Logic | Domain Service/Use Case（DDD-like，避免耦合 Yii） |
| `infrastructure/Repositories/` | Data Access | Namespace `Infrastructure\Repositories` |
| `js/zpos.js` | Frontend Entry | POS 入口（主要入口檔） |

## 典型範例
> 範例僅供風格與結構參考，實作需依實際模組與既有模式調整。

### Controller Action (Yii 1.1)
```php
public function actionGetData() {
    // 1. 取得參數（使用 Yii request wrapper）
    $id = Yii::app()->request->getParam('id');

    // 2. 呼叫 Service（避免直接操作 Model）
    try {
        $service = new StockService(new StockRepository());
        $data = $service->getData($id);

        // 3. 回傳 JSON
        $result = ['success' => true, 'data' => $data];
    } catch (Exception $e) {
        $result = ['success' => false, 'msg' => $e->getMessage()];
    }

    echo CJSON::encode($result);
    Yii::app()->end();
}
```

### Domain Service (Dependency Injection)
```php
// protected/domain/Stock/StockService.php
class StockService {
    /** @var StockRepositoryInterface */
    private $repo;

    /**
     * 建構式注入 Repository
     * @param StockRepositoryInterface $repo
     */
    public function __construct(StockRepositoryInterface $repo) {
        $this->repo = $repo;
    }

    /**
     * 取得可用庫存
     * @param int $productId
     * @return int
     */
    public function getAvailableStock($productId) {
        if ($productId <= 0) {
            throw new InvalidArgumentException('Invalid Product ID');
        }
        return $this->repo->findByProductId($productId)->quantity;
    }
}
```

## 整體專案架構（補充）

### 入口與啟動
- Web 入口：`index.php` → 讀取 `protected/config/main.php` → 建立 Yii WebApplication。
- 環境設定：`protected/config/*.php`（例如 `dev3.php`）提供連線與環境差異設定。
- Console 入口：`protected/yiic.php` 與 `protected/commands/`。

### 後端分層
- MVC：`protected/controllers/`、`protected/models/`、`protected/views/`。
- Modules：`protected/modules/*`（例如：`api`、`retail`、`webOrder`、`lugun`、`uorder`、`workflow`…）。
- 共用元件：`protected/components/`、`protected/helpers/`、`protected/extensions/`、`protected/vendors/`。
- 既有底層基礎：`protected/zdnbase/`（control/filter/session/tool 等）。

### DDD/領域層
- Domain：`domain/`（Documents/Entities/Services/Traits/ValueObjects/Validators…）。
- Infrastructure：`infrastructure/`（Repositories/Http/Context/Exceptions/Utility…）。

### 前端與靜態資產
- 主要 JS：`js/`（入口為 `js/zpos.js`，並有 `modules/`、`components/`、`utils/`）。
- 樣式與主題：`css/`、`themes/zdn/`。
- 其他資產：`images/`、`media/`、`ckeditor/`、`ckfinder/`。
- 上傳/下載：`upload/`、`download/`、`offline/`。

### 測試與輸出
- PHPUnit 測試：`protected/tests/`（含 unit/functional/Domain/infrastructure）。
- 手動測試：`tests/manual/`。
- 執行輸出與日誌：`protected/runtime/`、`protected/output/`、`output/`。

## 規劃模式 (Planning Protocol)
當需求涉及多檔案修改、架構變更或複雜邏輯時：
1. Plan Phase：分析需求，輸出實作計畫
2. Confirmation：等待用戶確認「Go」
3. Execution Phase：用戶確認後才開始以 TDD 寫程式

## 開發流程 (Clear Strategy)
1. Planning：讀取/更新 `openspec/proposals/*.md`
2. Coding：依提案小步實作
3. Checking：使用者完成驗證後再提交 `git commit`
4. Clearing：建議使用者常用 `/clear`；上下文以 `CLAUDE.md` 與提案檔為準

## Anti-Loop Protocol (防卡死機制)
同一問題連續失敗 3 次，立即停止：
1. 記錄：列出嘗試內容、錯誤訊息、假設
2. 研究：從文件或類似程式碼找 2-3 個替代方案
3. 轉向：簡化問題、改變抽象層級、換方法

## 測試與驗證
- 單元測試：Docker PHPUnit
- 手動驗證：`https://www.posdev.test/dev3/controller/action`
- 日誌：`protected/runtime/application.log`

Docker 測試指令：
```bash
# Windows Git Bash 相容格式
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit [Test_Path]

# 範例
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/unit/ExampleTest.php
```
