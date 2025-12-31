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
| 目錄 | 用途 | 規範 |
| :--- | :--- | :--- |
| `protected/models/` | Yii ActiveRecords | `class Post extends CActiveRecord` |
| `protected/controllers/` | MVC Controllers | `class SiteController extends Controller` |
| `protected/helpers/` | Helpers | `class CommonHelper` |
| `domain/Services/` | Business Logic | Namespace `Domain\Services` (DDD preferred) |
| `infrastructure/Repositories/` | Data Access | Namespace `Infrastructure\Repositories` |
| `js/` | Frontend Scripts | Use `zpos.js` as entry point |

## 規劃模式 (Planning Protocol)
當需求涉及多檔案修改、架構變更或複雜邏輯時：
1. Plan Phase：分析需求，輸出實作計畫
2. Confirmation：等待用戶確認「Go」
3. Execution Phase：用戶確認後才開始寫程式

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
