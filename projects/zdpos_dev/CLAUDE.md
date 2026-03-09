# Project Context: zdpos_dev

> 本檔為常駐規範（always-on），供所有 AI 使用。Claude Code 專屬執行策略見 `.claude/rules/`。

## Rule Priority
1. System/Platform constraints
2. User request in current turn
3. This document (`CLAUDE.md`)
4. `AGENTS.md`
5. Other docs (e.g. `GEMINI.md`)

## Available Agents

**專案專屬**（Claude Code: `.claude/agents/` / Codex CLI: `.codex/agents/`）：

| Agent | 檔案 | Purpose |
|-------|------|---------|
| bug-investigator | `bug-investigator.md` | Root cause analysis and data flow tracing |
| code-reviewer | `code-reviewer.md` | Code review（品質、安全、回歸風險）|
| tdd-guide-zdpos_dev | `tdd-guide-zdpos_dev.md` | TDD for PHP 5.6 + PHPUnit 5.7（含 strcasecmp、assertInternalType 等陷阱）|
| database-reviewer-mysql | `database-reviewer-mysql.md` | MySQL 5.7 query review |
| security-reviewer-zdpos_dev | `security-reviewer-zdpos_dev.md` | PHP/Yii security analysis |
| architect-zdpos_dev | `architect-zdpos_dev.md` | zdpos DDD system design |
| refactor-cleaner-zdpos_dev | `refactor-cleaner-zdpos_dev.md` | Dead code cleanup |

**通用備援**（Claude Code: `~/.claude/agents/` / Codex CLI: `~/.codex/agents/`）

---

## Planning Protocol (Conditional)
僅在下列情況，先提出計畫並等待使用者回覆 `Go`：
1. 新功能或新能力（含：新增事件監聽、新 API 端點、新物件/方法、新頁面行為）
2. Breaking change
3. 跨 2 個以上模組且含介面/契約調整
4. 高風險資料遷移、安全/權限核心邏輯變更

其餘任務直接執行，回報關鍵檢查點即可。

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

## Reference Index

- Prompt/架構長文參考：`docs/prompt-reference.md`
- 代理入口索引：`AGENTS.md`
- 子目錄索引：`protected/AGENTS.md`、`protected/tests/AGENTS.md`
- Claude Code 執行策略：`.claude/rules/`（Claude Code 自動載入）
