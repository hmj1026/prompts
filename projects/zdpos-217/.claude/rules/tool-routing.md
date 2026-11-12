# Tool Routing

> **Canonical**: `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` (dhpk v0.4.0+) — read that for the cx / gitnexus / claude-mem / Read / Grep decision tree, tie-breakers, and `gitnexus_impact` timing rules.

## zdpos additions

- **claude-mem**: zdpos runs claude-mem MCP. The session-start hook auto-matches context; for explicit lookups: `claude-mem smart_search "<module or symbol>"` before spawning Explore agents.
- **gitnexus index name**: `zdpos-217`. Resources reachable at `gitnexus://repo/zdpos-217/{context,clusters,processes,process/<name>}`. If a tool warns the index is stale → `node .gitnexus/run.cjs analyze`（設定由 repo 根 `.gitnexusrc` 提供：`maxFileSize` 2048 KB、`indexOnly`；勿用 `npx`，會繞過 `~/.local/bin/gitnexus` 的 OOM shim）。改 `.gitnexusrc`／`.gitnexusignore` 後第一次重建加 `--force --no-parse-cache`。（2026-06-26 修正：舊名 `zdpos_dev` 索引已 remove，以 root `CLAUDE.md` GitNexus 區塊為準。2026-11-12：預設 512 KB 曾使 PosController／ReportController／StockController／Device.php／zpos.js／zpos/list.js 整檔未入索引。）
- **zdpos 圖譜不涵蓋清單（直接走 `git grep`，不必先跑 impact）**：Yii `actionXxx` 的上游（路由字串）、`$this->app()->svc->m()`（Service 與 Repository 同名時兩者都查）、`POS.*`／`self.x = function` 的 legacy JS 方法、POS ajax 名稱字串（`ajaxPromise('xxx')` ↔ `PosController::doAjax` 的 `case "xxx":`）。範例：`git grep -n -E "(->|::)X\(" -- protected domain infrastructure ':!protected/tests/coverage'`；`git grep -n -E "['\"]customerPoint['\"]" -- js protected/controllers protected/models protected/extensions/zpos protected/views ':!protected/tests/coverage'`。`js/zpos.js` 與 `js/zpos/*.js` 為重複實作，兩邊都要看。
- **zdpos `git grep` 固定排除**：`':!protected/tests/coverage'`（coverage HTML 有進版控，會灌爆結果）、`':!*.min.js'`。
- **detect_changes 用 CLI**：`node .gitnexus/run.cjs detect-changes --scope compare --base-ref master --repo .`；MCP 版在本 repo 輸出常超過上限。
- **gitnexus impact / detect_changes 對「分支新增 / 未提交」符號不可信**：index 以已提交碼基為基準。branch 新增的類別 / 方法（如未 merge feature branch 的 `MenuAccessPolicy::decide`）→ `gitnexus_impact` 回 "not found"；未提交 hunk 的行號偏移會讓 `detect_changes` 誤映到鄰近舊符號（曾把 `Controller::checkPermission` 改動誤報為 `getStation` / purchase flow、給假 risk 評級）。對 branch-new / uncommitted 符號改用 `cx references --name X` 求 caller，勿信 impact / detect_changes 的 blast radius 與 risk。
- **Sub-agent prompt template**: zdpos has a local copy at `.claude/docs/subagent-prompt-template.md` with project-specific source-reading boilerplate (DDD layer paths, Yii framework path, MySQL container) — paste the relevant block into every Explore / specialist agent prompt.

## Cross-references

- `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` — canonical decision tree
- `dhpk:tool-routing` skill — longer prose version with examples
- `.claude/docs/subagent-prompt-template.md` — zdpos sub-agent prompt boilerplate
