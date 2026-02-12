# Project Context: zdpos_dev

> Note: 本檔為常駐規範（always-on）。長篇背景、範例與架構細節改放 `docs/prompt-reference.md`。

## Rule Priority
1. System/Platform constraints
2. User request in current turn
3. This document (`CLAUDE.md`)
4. `AGENTS.md`
5. Other docs (e.g. `GEMINI.md`)

## Execution Policy
- 預設直接執行使用者目標，不先過度規劃。
- 任務模式：
  - Small change: inspect -> patch -> targeted verification
  - Medium change: inspect -> brief plan -> patch -> tests
  - Large/ambiguous: proposal/spec first (OpenSpec)

## Planning Protocol (Conditional)
僅在下列情況，先提出計畫並等待使用者回覆 `Go`：
1. 新功能或新能力
2. Breaking change
3. 跨 2 個以上模組且含介面/契約調整
4. 高風險資料遷移、安全/權限核心邏輯變更

其餘任務直接執行，回報關鍵檢查點即可。

## Output Contract
- 回覆格式預設為：`結論` -> `變更檔案` -> `驗證` -> `風險/待確認`。
- 找不到答案或受限於環境時，必須回覆：`阻塞原因`、`已嘗試`、`下一個可行方案`。
- 不輸出內部推理；只輸出可執行的結論與依據。

## Skill Policy
當多個 skill 同時命中時，依序選擇：
1. OpenSpec 類（new/continue/apply/verify/sync/archive）
2. bug-investigation（僅調查/定位 root cause）
3. test-driven-development（功能或 bugfix 且需調整測試）
4. software-architecture（跨模組或重大設計）
5. 其他技能（最小必要集合）

原則：
- 不因「可用」而使用 skill，僅因「必要」而使用。
- 使用者要求直接實作且屬小型變更時，避免套完整流程型 skill。
- 同名 skill 若有多來源，以專案內版本為唯一生效版本。
- brainstorming 僅在需求不清或方案分歧時啟用。

## Communication Rules
- 回應語言：正體中文
- 程式註解：正體中文
- 專有名詞保留英文（Controller, Model, View, Action）
- 先給結論或建議，再補必要細節

## Core Engineering Rules
- 單一真相來源（SSOT）：延展既有邏輯，不重複造輪子。
- 先讀後寫：優先用 `rg`/`fd` 找既有模式再改。
- 簡潔優先：清楚意圖 > 炫技寫法，遵循 SRP/DRY。
- 測試策略：可驗證行為變更時採 TDD（Red -> Green -> Refactor）。
- 資料庫操作必須使用 PDO prepared statements。

## Environment Constraints
- 架構：Yii 1.1 + DDD-like 分層
- PHP：5.6.40（legacy）
- 前端：Legacy POS（Raw ES6, no build step）
- DB：`zdpos_dev_2`（MySQL 5.7.33）
- 本機網址：`https://www.posdev.test/dev3`

### PHP 5.6 Hard Limits
| 禁止 | 替代方案 / 要求 |
|------|------------------|
| `??` | `isset($var) ? $var : $default` |
| `function(int $id)` | PHPDoc `@param int $id` |
| `: void` | PHPDoc `@return void` |
| 直接存取 `$_POST` | `Yii::app()->request->getPost()` |

其他要求：
- PHP 陣列使用 `[]`，禁用 `array()`
- ActiveRecord 必須含：`public static function model($className=__CLASS__) { return parent::model($className); }`

### Frontend Hard Limits
- 禁用 `$.ajax`、`fetch`、`axios`
- 必須使用 `POS.list.ajaxPromise()` 做非同步請求
- 全域 `POS` 物件為單一真相來源

## Filesystem / Runtime Policy
- 寫入權限以「當前 runtime 實測結果」為準，不以固定磁碟路徑假設。
- 若工作目錄不可寫，改寫入 `output/` 或使用者指定可寫目錄。
- 涉及 Web Root 相對路徑時，先明確說明路徑基準再落檔。

## OpenSpec Workflow
1. Planning：在 `openspec/changes/<change-id>/` 維護 `proposal.md`、`specs/*/spec.md`、`design.md`、`tasks.md`
2. Use CLI：`openspec status --change "<change-id>" --json`
3. Use CLI：`openspec instructions <artifact-id> --change "<change-id>" --json`
4. Coding：依 artifacts 小步實作
5. Checking：由使用者驗證後再提交 `git commit`

## Anti-Loop Protocol
同一問題連續失敗 3 次，立即停止並用下列模板回報：
1. `嘗試紀錄`：做了什麼、錯誤訊息是什麼
2. `替代方案`：至少 2 個可行路徑與代價
3. `建議決策`：推薦下一步與原因

## Testing & Validation
- 單元測試：Docker PHPUnit
- 手動驗證：`https://www.posdev.test/dev3/controller/action`
- 日誌：`protected/runtime/application.log`

```bash
# Windows Git Bash 相容格式
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit [Test_Path]
```

## Reference Index
- Prompt/架構長文參考：`docs/prompt-reference.md`
- 代理入口索引：`AGENTS.md`
- 子目錄索引：`protected/AGENTS.md`、`protected/tests/AGENTS.md`
