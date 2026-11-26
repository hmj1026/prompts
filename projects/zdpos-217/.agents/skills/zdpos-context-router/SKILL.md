---
name: zdpos-context-router
description: zdpos-217 文件與跨 Agent 規範路由。Use when 查找 zdpos-217 專項規則或入口：docs/openspec 治理、跨 agent SSOT/symlink、PHP 5.6/Yii 1.1 標準、前端慣例與靜態檢查、執行政策/review gate/本地 workflow 適配、tool routing（cx/GitNexus）、模型與成本路由、領域詞彙/ADR、拆帳 QA、.scratch 任務追蹤、PHPUnit 測試規範或本地驗證移交。
---

# zdpos 專項文件索引

## 路由規則

- 依任務命中的所有主題逐一讀取對應入口後再動手；只載入命中主題的檔案。
- **跨 Agent 主動讀取**：Codex、Antigravity 與 Cursor 不會自動載入 `.claude/rules/`；命中含 `.claude/rules/` 的主題時須主動讀取該規則檔（僅 Claude 依 path 自動載入）。

## 主題索引

| 主題 | 對應文件 / 入口 | 跨 Agent / 使用備註 |
|---|---|---|
| **Docs／OpenSpec 治理**：`docs/` 或 `openspec/` 的建立、編輯、搬移、歸檔、可見性與 living spec 邊界 | `docs/workflow/documentation-governance.md` | 全文件目錄導覽見 `docs/README.md`（含 `guides/`、`operations/`、`knowledge/INDEX.md`） |
| **跨 Agent SSOT 與 dhpk harness**：`AGENTS.md`／`CLAUDE.md`／`GEMINI.md`、skill 目錄與 symlink 拓撲 | `docs/workflow/agent-ssot-specification.md` | — |
| **PHP 5.6 Coding Style 與架構標準**：雙執行期子集、命名、魔術值、SQL 落點、Domain Boundary、AJAX 回應契約 | `CODING_STANDARDS.md` | 所有 Agent 共用的寫扣與審查標準 |
| **PHP／Yii 1.1 實作細節**：ActiveRecord、transaction、`CDbCriteria`、View Architecture、安全與測試佈局 | `.claude/rules/php/`（`patterns.md`、`coding-style.md`、`yii-framework.md`、`security.md`、`testing.md`、`view-architecture.md`） | Claude 改 `*.php` 自動載入；**Codex／Antigravity／Cursor 須主動讀取**。catch 例外記錄與 IN/NOT IN 查詢微慣例見 skill `zdpos-php-patterns` |
| **前端慣例與靜態檢查**：POS global/`POS.*` state、event bus、AJAX wrapper SSOT、jQuery plugin、ESLint/typecheck | `docs/conventions/frontend.md`；規則：`.claude/rules/frontend.md`、`.claude/rules/js/static-checks.md` | 結帳收尾導覽見 `js/tests/README.md`；ESLint tier、`@ts-check` cleanup 與 legacy 巨檔抽出見 skill `zdpos-js-modernization` |
| **執行政策與 Review／Linter Gate**：sentinel／reviewer 觸發矩陣、PR checklist、`scripts/lint-php.sh`、Preflight／Worktree checkpoint | `.claude/rules/execution-policy.md`；完整專案 gate：`docs/workflow/execution-policy.md` | 非 Claude Agent 須主動讀 `.claude/rules/`。6 槽觸發與 `lint-php.sh` 仍有效；dhpk v0.57.0+ 已移除 `.pending-*` hook 寫檔（見 `.claude/dhpk-versions.json` `0.57.x`），由主控依 trigger table 主動平行派發 reviewer |
| **程式碼導覽與 Tool Routing**：`cx`／`GitNexus`／`claude-mem` 決策樹、`zdpos` 圖譜盲區、分支新符號、`git grep` 排除項 | `.claude/rules/tool-routing.md`；subagent 樣板：`.claude/docs/subagent-prompt-template.md` | Yii 路由字串、`POS.*` 與未提交符號屬圖譜盲區，一律以 `git grep`（排除 `coverage/`）交叉驗證 |
| **模型分層與成本路由**：3-Tier 跨工具模型對照、角色預設模型與成本升降階規則 | `docs/workflow/model-routing.md`（3-Tier 總覽）；角色／成本 SSOT：`.cursor/rules/model-economics.mdc`（或 `${CLAUDE_PLUGIN_ROOT}/rules/model-economics.md`） | **差異以 `model-economics` 為準**：`model-routing.md` 將 Codex `fast-worker` 列於 Tier 1，實際角色配置依 `model-economics`：`fast-worker` 預設 **`sonnet`**、純字面 `quick-worker` 為 `haiku @ medium`、`Explore` 必帶 `haiku @ low`、`architect` 為 `fable @ medium`、`deep-reasoner` 預設 `opus`、reviewer 下限 `sonnet` |
| **領域文件與術語詞彙**：`CONTEXT.md`、`GLOSSARY.md`、`docs/adr/` 衝突檢查 | `docs/agents/domain.md`；詞彙：`CONTEXT.md`、`GLOSSARY.md` | — |
| **拆帳 QA 與結帳流程**：拆帳手動測試、結帳階段、收據驗證與名詞表 | `docs/qa/split-bill/QA-split-bill-checkout-manual.md`；分流：`docs/qa/split-bill/QA-split-bill-INDEX.md` | 名詞：`openspec/specs/split-bill-glossary/spec.md`、`docs/features/split-bill/vocabulary-drift.md` |
| **任務與 Issue 追蹤**：臨時任務放 `.scratch/` vs 生命週期 spec 放 `openspec/` | `docs/agents/issue-tracker.md` | 涵蓋 `wayfinder`／`to-tickets` 票單格式 |
| **測試規範與 Test Harness**：PHPUnit 測試分層、bootstrap、禁止反模式、已知紅燈 | `protected/tests/docs/TESTING_STANDARDS.md`；spec：`openspec/specs/test-harness/spec.md` | 已知紅燈查 `protected/tests/docs/KNOWN-FAILURES.md`（必要時 `git show dev:protected/tests/docs/KNOWN-FAILURES.md`） |
| **本地驗證與 Review 移交**：DB-backed profile 與隔離條件、`check:record`/`check:handoff`/`verify:review`、PHP 8.4 本機座標與索引 fallback | `.scratch/local-dev/docs/LOCAL_VERIFICATION.md` | 來源綁定驗證搭配 skill `zdpos-source-bound-verification` |
| **本地 Workflow 適配**：使用 `implement`、`code-review` 或 `simplify` 前的本地設定 | `.scratch/local-dev/docs/skill-adapters.md` | — |
| **Codebase 設計與 Bug 調查技能**：deep module／seam 設計；red-loop／5 階段根因調查 | 設計：skill `codebase-design`（受 `CODING_STANDARDS.md` 約束）；調查：skill `diagnosing-bugs` 或 `bug-investigation` | — |

## 完成條件

任務涵蓋的每個主題皆已讀取對應入口（含非 Claude Agent 應讀的 `.claude/rules/` 檔），才進入實作或審查。
