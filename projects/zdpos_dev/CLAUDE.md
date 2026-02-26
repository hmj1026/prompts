# Project Context: zdpos_dev

> Note: 本檔為常駐規範（always-on）。長篇背景、範例與架構細節改放 `docs/prompt-reference.md`。

## Rule Priority
1. System/Platform constraints
2. User request in current turn
3. This document (`CLAUDE.md`)
4. `AGENTS.md`
5. Other docs (e.g. `GEMINI.md`)

## Available Agents

**專案專屬** (`.claude/agents/`)：

| Agent | 檔案 | Purpose |
|-------|------|---------|
| tdd-guide-zdpos_dev | `tdd-guide-zdpos_dev.md` | TDD for PHP 5.6 + PHPUnit 5.7（含 strcasecmp、assertInternalType 等陷阱）|
| database-reviewer-mysql | `database-reviewer-mysql.md` | MySQL 5.7 query review |
| security-reviewer-zdpos_dev | `security-reviewer-zdpos_dev.md` | PHP/Yii security analysis |
| architect-zdpos_dev | `architect-zdpos_dev.md` | zdpos DDD system design |
| refactor-cleaner-zdpos_dev | `refactor-cleaner-zdpos_dev.md` | Dead code cleanup |

**通用備援** (`~/.claude/agents/`)：

| Agent | Purpose |
|-------|---------|
| code-reviewer | Code review（最穩定，PHP 專案也適用）|
| bug-investigator | root cause analysis and data flow tracing |

---

## Execution Policy
- 預設直接執行使用者目標，不先過度規劃。
- 任務模式：
  - Small change: inspect -> patch -> code-reviewer -> targeted verification
  - Medium change: inspect -> brief plan -> tdd-guide -> patch -> code-reviewer
  - Bug fix（觸發 bug-investigation）: bug-investigation -> **OpenSpec** -> tdd-guide -> patch -> code-reviewer
  - Large/ambiguous: OpenSpec (proposal → specs → design → tasks) -> tdd-guide -> patch -> code-reviewer

> **鐵律：** 凡觸發 bug-investigation skill，調查完成後必須接 OpenSpec（`/opsx:new`），不得直接跳到實作。

## Planning Protocol (Conditional)
僅在下列情況，先提出計畫並等待使用者回覆 `Go`：
1. 新功能或新能力（含：新增事件監聽、新 API 端點、新物件/方法、新頁面行為）
2. Breaking change
3. 跨 2 個以上模組且含介面/契約調整
4. 高風險資料遷移、安全/權限核心邏輯變更

其餘任務直接執行，回報關鍵檢查點即可。

## Output Contract
- 回覆格式預設為：`結論` -> `變更檔案` -> `驗證` -> `風險/待確認`。
- 找不到答案或受限於環境時，必須回覆：`阻塞原因`、`已嘗試`、`下一個可行方案`。

## Skill Policy
當多個 skill 同時命中時，依序選擇：
1. OpenSpec 類（new/continue/apply/verify/sync/archive）
2. bug-investigation — 觸發詞：「調查」「trace」「為什麼」「排查」「找原因」「root cause」
3. test-driven-development（功能或 bugfix 且需調整測試）
4. software-architecture（跨模組或重大設計）
5. 其他技能（最小必要集合）

原則：
- 不因「可用」而使用 skill，僅因「必要」而使用。
- 使用者要求直接實作且屬小型變更時，避免套完整流程型 skill。
- 同名 skill 若有多來源，以專案內版本為唯一生效版本。
- brainstorming 僅在需求不清或方案分歧時啟用。
- **code-reviewer 與 tdd-guide 為強制後置步驟，不受「避免過用」原則限制：**
  - 任何 Edit/Write 後 → 必須啟動 code-reviewer agent
  - Bug fix 或新功能實作後 → 必須啟動 tdd-guide agent

## Communication Rules
- 回應語言：正體中文
- 程式註解：正體中文
- 專有名詞保留英文（Controller, Model, View, Action）
- 先給結論或建議，再補必要細節

## Core Engineering Rules
- 單一真相來源（SSOT）：延展既有邏輯，不重複造輪子。
- 先讀後寫：優先用 `rg`/`fd` 找既有模式再改。
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

### Yii 1.1 Framework Reference
**Framework 位置:** `/mnt/e/projects/yii_framework/`

**重要行為文檔：**

| 方法 | 位置 | 返回值 | 用途 |
|------|------|--------|------|
| `CDbCommand::queryRow()` | `/db/CDbCommand.php:412` | `false` (非 `null`) 當無結果 | 查詢單一列 |
| `CDbCommand::queryAll()` | `/db/CDbCommand.php:397` | `[]` (空陣列) 當無結果 | 查詢多列 |
| `CDbCommand::queryScalar()` | `/db/CDbCommand.php:430` | `false` 當無結果 | 查詢單一值 |

**關鍵注意：**
- `queryRow()` 返回 `false` (不是 `null`)，檢查應用 `if (!$result)` 或 `if ($result === false)`
- `is_null($queryRow())` **永遠不會** 為 true
- 所有查詢方法使用參數綁定（`:param` 風格），防止 SQL Injection

**DDD 層次與常用常數：**
- DDD 呼叫路徑：`Controller → $this->app()->{service}->fetchXxx() → Repository->forXxx()`
- `$this->app()` 定義於 `protected/controllers/traits/DomainApplicable.php`
- `PayTypeGroup` 常數位於 `domain/Models/PayTypeGroup.php`（禁用魔法字串）：
  - `PayTypeGroup::THIRD_PARTY` = `'3rdParty'`
  - `PayTypeGroup::MULTI_PAY`   = `'multiPay'`
  - `PayTypeGroup::TOTAL_PAY`   = `'TotalPay'`
  - `PayTypeGroup::TICKET`      = `'ticket'`

**MySQL collation 與測試排序驗證：**
- DB 使用 `utf8_unicode_ci`（大小寫不敏感）排序
- PHP 測試驗證 ORDER BY 結果時，**必須用 `strcasecmp()`，禁用 `strcmp()`**
- 原因：`strcmp('ipass', 'ND')` 返回 27（ASCII 差值），但 MySQL 認為 i < N

## Filesystem / Runtime Policy
- 寫入權限以「當前 runtime 實測結果」為準，不以固定磁碟路徑假設。
- 若工作目錄不可寫，改寫入 `output/` 或使用者指定可寫目錄。
- 涉及 Web Root 相對路徑時，先明確說明路徑基準再落檔。

## OpenSpec Workflow
artifacts 目錄：`openspec/changes/<change-id>/`（proposal → specs → design → tasks）

> **IMPORTANT：tasks.md 必須先建立才能開始實作；禁止先寫程式再補文件。**

## Anti-Loop Protocol
同一問題連續失敗 3 次，立即停止並用下列模板回報：
1. `嘗試紀錄`：做了什麼、錯誤訊息是什麼
2. `替代方案`：至少 2 個可行路徑與代價
3. `建議決策`：推薦下一步與原因

## Testing & Validation
> **IMPORTANT：實作完成後必須主動執行相關測試，以驗證變更正確性。**

- 單元測試：Docker PHPUnit
- 手動驗證：`https://www.posdev.test/dev3/controller/action`
- 日誌：`protected/runtime/application.log`

```bash
# Windows Git Bash 相容格式
docker exec -i -w //var/www/www.posdev/zdpos_dev pos_php phpunit [Test_Path]
```

## Reference Index
- Prompt/架構長文參考：`docs/prompt-reference.md`
- 代理入口索引：`AGENTS.md`
- 子目錄索引：`protected/AGENTS.md`、`protected/tests/AGENTS.md`
