
# Project Context: zdpos_dev

> **Note**: These project-specific rules override general guidelines where conflicts occur.

## Rule Priority
1. System/Platform constraints
2. User request in current turn
3. This document (`CLAUDE.md`)
4. `AGENTS.md`
5. Other docs (e.g. `GEMINI.md`)

## Execution Policy
- 預設直接執行使用者目標，不先過度規劃
- 任務模式：
  - Small change: inspect -> patch -> targeted verification
  - Medium change: inspect -> brief plan -> patch -> tests
  - Large/ambiguous: proposal/spec first (OpenSpec)

## Skill Conflict Resolution
當多個 skill 同時命中時，依下列順序決定：
1. OpenSpec 類（new/continue/apply/verify/sync/archive）
2. bug-investigation（僅調查問題、定位 root cause 時）
3. test-driven-development（功能或 bugfix 且需新增/調整測試時）
4. software-architecture（跨模組或重大設計變更時）
5. 其他技能（依任務必要性選最小集合）

原則：
- 不因「可用」而使用 skill，僅因「必要」而使用
- 若使用者要求直接實作且屬小型變更，避免先套完整流程型 skill
- 同名 skill 若有多來源，以專案內版本為唯一生效版本

## Brainstorming/TDD Guardrails
- brainstorming：僅在需求不清、方案分歧、涉及產品設計取捨時啟用
- test-driven-development：優先用於可明確驗證行為變更的任務；不強制於 typo、註解、純文案修改

## 索引（AGENTS）
- `protected/AGENTS.md`：後端 MVC 與基礎結構總覽。
- `protected/tests/AGENTS.md`：測試規範與 PHPUnit 慣例。

## 提示詞最佳實務（Best Practices）
- 精簡清楚：只提供必要上下文，明確指定目標、輸出格式與步驟順序。
- 逐步與失敗回復：先做最小可行查找；遇到工具/權限/編碼錯誤時停止重試並回報具體錯誤與替代路徑。

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
- 本機網址：`https://www.posdev.test/dev3`。
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
