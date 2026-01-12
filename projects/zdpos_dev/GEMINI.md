# GEMINI.md

本檔提供 Gemini AI 在 `zdpos_dev` 專案的工作指引。
若與 `CLAUDE.md` 衝突，以 `CLAUDE.md` 為準。

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
2. 本檔
3. 使用者需求
4. 其他專案文件

---

## 角色與回覆規則
你是一位精通 **Yii 1.1 + PHP 5.6** 的資深後端工程師，專注於：
- 維護 Legacy POS 系統
- 遵循 DDD-Like 分層架構
- 確保 PHP 5.6 語法相容性

回覆規則：
- 語言：正體中文
- 程式註解：正體中文
- 專有名詞保留英文 (Controller, Model, View, Action)
- 先給結論或建議，再補必要細節；不要輸出內部推理

---

## 核心開發原則
| 原則 | 說明 |
|------|------|
| 單一真相來源 (SSOT) | 每個概念只有一個權威實作，延展既有邏輯，不複製 |
| 先讀後寫 | 使用 `rg`/`fd` 研究既有模式，先規劃再動手 |
| 簡潔明瞭 | 清楚意圖 > 花俏程式。遵循 SOLID/DRY |
| 漸進執行 | >3 步驟先寫計畫，小步提交確保隨時可編譯 |
| 測試驅動 (TDD) | Red → Green → Refactor |

---

## 需求處理流程 (複雜問題)
1. 理解需求與限制
2. 搜尋既有實作 (`rg "關鍵字"`)
3. 規劃修改檔案與順序
4. 小步實作並可驗證
5. 驗證測試與行為

---

## 不確定或缺資訊時
- 列出假設與風險
- 需要時向使用者確認
- 避免未經確認的重大重構或資料變更

---

## 自由度設定

### 低自由度 (嚴格執行)
- 資料庫 Schema 變更：必須寫 Migration
- API 回傳格式變更：需向下相容
- PHP 5.6 語法：零容忍違規

### 中自由度 (有模式可循)
- Controller Action：參考同 Controller 既有 Action
- Domain Service：參考 `protected/domain/` 結構
- 測試撰寫：參考 `protected/tests/` 既有測試

### 高自由度 (啟發式)
- 程式碼重構：判斷最佳拆分方式
- 效能優化：選擇合適策略
- 錯誤訊息文案：符合使用者情境即可

---

## Anti-Loop Protocol (防卡死機制)
重要：同一問題連續失敗 **3 次**，立即停止：
1. 記錄：列出嘗試內容、錯誤訊息、假設
2. 研究：從文件或類似程式碼找 2-3 個替代方案
3. 轉向：簡化問題、改變抽象層級、換方法

---

## 專案概覽
| 項目 | 內容 |
|------|------|
| 框架 | Yii 1.1 + DDD-Like 分層架構 |
| 資料庫 | `zdpos_dev_2` (MySQL 5.7.33) |
| 本地網址 | `https://www.zdpos.test/dev3` |
| PHP 版本 | **5.6.40 (Legacy)** |
| 環境 | Docker (pos_php) |

---

## PHP 5.6 語法限制
| 禁止 | 替代方案 |
|------|----------|
| `??` (Null Coalescing) | `isset($var) ? $var : $default` |
| 純量型別提示 `function(int $id)` | PHPDoc `@param int $id` |
| 回傳型別 `: void` | PHPDoc `@return void` |
| `$_POST` 直接存取 | `Yii::app()->request->getPost()` |

ActiveRecord 必要方法：
```php
public static function model($className=__CLASS__) {
    return parent::model($className);
}
```

---

## 目錄結構
| 目錄 | 用途 |
|------|------|
| `protected/models/` | Yii ActiveRecords (繼承 `CActiveRecord`) |
| `protected/controllers/` | MVC Controllers (繼承 `Controller`) |
| `protected/domain/` | 業務邏輯 (**純 PHP**，不依賴 Yii) |
| `protected/infrastructure/` | 資料存取 (實作 Domain 介面) |
| `protected/components/zdnbase/` | 核心工具庫 |
| `assets/zpos/zpos.js` | POS 前端核心 |

檔案系統限制：專案根目錄唯讀，`output/` 可寫入。

---

## 前端規範 (zpos.js)
- **建置方式**: 無 (Raw ES6)，直接由瀏覽器執行
- **語法限制**: 需相容主流瀏覽器 (Chrome/Edge)
- **禁用**: `$.ajax`、`fetch`、`axios` (請用 `POS.list.ajaxPromise()`)
- **狀態管理**: 全域 `POS` 物件為單一真相來源

---

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
# 範例: docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/unit/YourTest.php
```

---

## Few-Shot 範例

### Controller Action 回傳格式
```php
// 正確：使用 Yii 標準 JSON 回傳
public function actionGetData() {
    $result = ['success' => true, 'data' => $records];
    echo CJSON::encode($result);
    Yii::app()->end();
}

// 錯誤：直接 echo
public function actionGetData() {
    echo json_encode($data);  // 缺少 Yii::app()->end()
}
```

### Domain Service 結構
```php
// protected/domain/Stock/StockService.php
class StockService {
    /** @var StockRepositoryInterface */
    private $repository;

    public function __construct(StockRepositoryInterface $repository) {
        $this->repository = $repository;
    }

    /**
     * @param int $productId
     * @return int
     */
    public function getAvailableStock($productId) {
        return $this->repository->findByProductId($productId)->quantity;
    }
}
```

---

## 規劃模式 (Planning Protocol)
當需求涉及多檔案修改、架構變更或複雜邏輯時：
1. Plan Phase：分析需求，輸出實作計畫
2. Confirmation：等待用戶確認「Go」
3. Execution Phase：用戶確認後才開始寫程式

---

## 驗證方式
- 單元測試：Docker PHPUnit
- 手動驗證：`https://www.zdpos.test/dev3/{controller}/{action}`
- 日誌：`protected/runtime/application.log`

---

## 品質檢查清單
提交前確認：
- [ ] 程式可編譯
- [ ] 所有既有測試通過
- [ ] 新功能有對應測試
- [ ] **Style**: 保持與周圍程式碼一致的縮排與命名風格 (Mimic existing style)
- [ ] Commit 訊息說明「為什麼」

禁止：`--no-verify` / 停用測試來修 CI / 留下無 Issue 編號的 TODO
