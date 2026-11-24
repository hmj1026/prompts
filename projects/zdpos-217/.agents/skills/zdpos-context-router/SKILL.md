---
name: zdpos-context-router
description: zdpos-217 專項文件與跨 Agent 規範索引：依任務主題找出該先讀的專案文件與規則。Use when 任務涉及 zdpos-217 的 docs 或 openspec 治理（建立、搬移、歸檔、可見性）；跨 agent skill/symlink 配置；PHP 5.6 coding style 與 Yii 1.1 架構（CODING_STANDARDS.md、ActiveRecord、CDbCriteria、View Architecture）；前端 POS 慣例與靜態檢查；執行政策、review/linter gate、implement/code-review/simplify 本地適配；tool routing（cx/GitNexus 盲區與 git grep）或模型分層與成本路由（model-routing／model-economics）；領域詞彙與 ADR；拆帳 QA 結帳案例；臨時任務追蹤（.scratch）；PHPUnit 測試分層、KNOWN-FAILURES 或 DB-backed 本地驗證移交。根目錄 AGENTS.md 已直接載明的單純語法限制或快速單元測試指令不需觸發。
---

# zdpos 專項文件索引

依任務主題讀對應的專案文件；只讀本次任務需要的檔案。若你使用的是 Codex、Antigravity 或 Cursor（不會自動載入 `.claude/rules/`），凡涉及下方標註 `.claude/rules/` 的主題時請主動讀取該檔案。

| 主題 | 對應文件 / 入口 | 跨 Agent / 使用備註 |
|---|---|---|
| **Docs／OpenSpec 治理**：`docs/` 或 `openspec/` 的建立、編輯、搬移、歸檔、可見性與 living spec 邊界 | `docs/workflow/documentation-governance.md` | 全文件目錄導覽見 `docs/README.md`（含 `guides/`、`operations/`、`knowledge/INDEX.md`） |
| **跨 Agent SSOT 與 dhpk harness**：`AGENTS.md`／`CLAUDE.md`／`GEMINI.md`、skill 目錄與 symlink 拓撲 | `docs/workflow/agent-ssot-specification.md` | — |
| **PHP 5.6 Coding Style 與架構標準**：雙執行期子集、命名、魔術值、SQL 落點、Domain Boundary、AJAX 回應契約 | `CODING_STANDARDS.md` | 所有 Agent 共用的寫扣與審查標準 |
| **PHP／Yii 1.1 實作細節**：ActiveRecord、transaction、`CDbCriteria`、View Architecture、安全與測試佈局 | `.claude/rules/php/`（`patterns.md`、`coding-style.md`、`yii-framework.md`、`security.md`、`testing.md`、`view-architecture.md`） | Claude 改 `*.php` 會自動載入；**Codex／Antigravity／Cursor 須主動讀取** |
| **前端慣例與靜態檢查**：POS global/`POS.*` state、event bus、AJAX wrapper SSOT、jQuery plugin、ESLint/typecheck | `docs/conventions/frontend.md`；規則：`.claude/rules/frontend.md`、`.claude/rules/js/static-checks.md` | 結帳收尾導覽見 `js/tests/README.md` |
| **執行政策與 Review／Linter Gate**：sentinel／reviewer 觸發矩陣、PR checklist、`scripts/lint-php.sh`、Preflight／Worktree checkpoint | `.claude/rules/execution-policy.md`；完整專案 gate：`docs/workflow/execution-policy.md` | 非 Claude Agent 須主動讀 `.claude/rules/`。6 槽觸發與 `lint-php.sh` 仍有效，但 dhpk v0.57.0+ 已移除 `.pending-*` hook 寫檔（見 `.claude/dhpk-versions.json` `0.57.x`），改由主控依 trigger table 主動平行派發 reviewer |
| **程式碼導覽與 Tool Routing**：`cx`／`GitNexus`／`claude-mem` 決策樹、`zdpos` 圖譜盲區、分支新符號、`git grep` 排除項 | `.claude/rules/tool-routing.md`；subagent 樣板：`.claude/docs/subagent-prompt-template.md` | 避免在 Yii 路由字串／`POS.*`／未提交符號上誤信圖譜或掃進 `coverage/` |
| **模型分層與成本路由**：3-Tier 跨工具模型對照、角色預設模型與成本升降階規則 | `docs/workflow/model-routing.md`（3-Tier 總覽）；角色／成本 SSOT：`.cursor/rules/model-economics.mdc`（或 `${CLAUDE_PLUGIN_ROOT}/rules/model-economics.md`） | **差異注意**：`model-routing.md` 將 Codex `fast-worker` 列於 Tier 1，但 `model-economics` 規定 `fast-worker` 預設 **`sonnet`**、純字面 `quick-worker` 才是 `haiku @ medium`、`Explore` 必帶 `haiku @ low`、`architect` 為 `fable @ medium`、`deep-reasoner` 預設 `opus`、reviewer 下限 `sonnet` |
| **領域文件與術語詞彙**：`CONTEXT.md`、`GLOSSARY.md`、`docs/adr/` 衝突檢查 | `docs/agents/domain.md`；詞彙：`CONTEXT.md`、`GLOSSARY.md` | — |
| **拆帳 QA 與結帳流程**：拆帳手動測試、結帳階段、收據驗證與名詞表 | `docs/qa/split-bill/QA-split-bill-checkout-manual.md`；分流：`docs/qa/split-bill/QA-split-bill-INDEX.md` | 名詞：`openspec/specs/split-bill-glossary/spec.md`、`docs/features/split-bill/vocabulary-drift.md` |
| **任務與 Issue 追蹤**：臨時任務放 `.scratch/` vs 生命週期 spec 放 `openspec/` | `docs/agents/issue-tracker.md` | 涵蓋 `wayfinder`／`to-tickets` 票單格式 |
| **測試規範與 Test Harness**：PHPUnit 測試分層、bootstrap、禁止反模式、已知紅燈 | `protected/tests/docs/TESTING_STANDARDS.md`；spec：`openspec/specs/test-harness/spec.md` | 已知紅燈查 `protected/tests/docs/KNOWN-FAILURES.md`（必要時 `git show dev:protected/tests/docs/KNOWN-FAILURES.md`） |
| **本地驗證與 Review 移交**：DB-backed profile 與隔離條件、`check:record`/`check:handoff`/`verify:review`、PHP 8.4 本機座標與索引 fallback | `.scratch/local-dev/docs/LOCAL_VERIFICATION.md` | 來源綁定驗證可搭配 skill `zdpos-source-bound-verification` |
| **本地 Workflow 適配**：使用 `implement`、`code-review` 或 `simplify` 前的本地設定 | `.scratch/local-dev/docs/skill-adapters.md` | — |
| **Codebase 設計與 Bug 調查技能**：deep module／seam 設計；red-loop／5 階段根因調查 | 設計：skill `codebase-design`（受 `CODING_STANDARDS.md` 約束）；調查：skill `diagnosing-bugs` 或 `bug-investigation` | — |
