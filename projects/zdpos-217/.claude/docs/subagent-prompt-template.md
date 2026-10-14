# Sub-agent Prompt Boilerplate

Referenced from `rules/tool-routing.md`. Sub-agents do NOT inherit project rules — paste the relevant block into the agent prompt.

## Source-reading agents (Explore, tdd-guide, architect, bug-investigation, etc.)

> "Use `cx overview <file>` before any Read on files >200 lines. Use `cx definition --name X` to read specific functions."

## DB / data-access tasks (any agent that queries, inserts, or updates a table)

> "Before planning any new DB query, check `infrastructure/Repositories/` for an existing Repository that handles the target table. First grep: `grep -rl '<target_table>' infrastructure/Repositories/`; if nothing matches, enumerate via `cx overview infrastructure/Repositories/`. If a Repository is found, new queries go there via `queryBuilder()` — not in the Controller. Existing `createCommand()` in a Controller is legacy debt; presence does NOT permit new violations."

## Extended anti-pattern reference

- `Read --offset/--limit` as a substitute for `cx overview` on files >200 lines — first tool call MUST be `cx overview`. Exception: current session already ran `cx overview` / `cx definition` for the file and needed content is within the listed range.
- Running `gitnexus_impact` for append-only changes — pure method additions (not touching existing symbol body/signature/PHPDoc) have no caller blast radius; skip impact and state "append-only — gitnexus_impact skipped" in the plan/commit. Exemption void once existing method behavior is modified.
- Spawning Explore without cx instructions — sub-agent prompts must include the boilerplate above.
- Entering Edit/Write on an existing symbol without prior `gitnexus_impact` — violates CLAUDE.md hard rule; "local / private / single-caller" is not an excuse.

## 共用派工規範（所有子代理必讀）

### 語言與風格
- 回報與程式註解使用正體中文，技術名詞保留英文。
- 不使用 emoji。
- PHP 5.6：禁用 `??`、純量型別宣告、`fn() =>`；陣列用 `[]`。
- 新增物件或方法時，依 zdpos anchor 規則加註解（`2026/MM/DD paul [vN] <feature>`）。

### 讀碼順序（省 token）
1. 找符號用 `cx symbols` 或 `rg -l`；不整檔 Read，除非完整內容必要。
2. 改既有符號前跑 GitNexus impact（見上方 anti-pattern 第 2、4 點的例外規則）。HIGH/CRITICAL 必須在回報中標示。
3. 分支新增或未提交的符號，impact 結果不可信，改用 `cx references --name X` 找呼叫者。

### 權限與 Git 邊界
- 禁止 commit、push、checkout、stash、reset、rebase。
- 只修改任務指定的檔案；寫入型任務只在指定 worktree 內進行。
- 新增行為或修 bug：先寫失敗測試（RED），再做最小實作（GREEN）。

### 驗證（只跑與改動相關的最小集合）
- 語法：`php -l <file>`
- PHP：`bash protected/tests/scripts/run-tests.sh`
- JS：`npm run test:js`；型別與 lint：`npm run typecheck`、`npm run lint`
- 未跑的驗證必須明說，不可宣稱通過。

### 停止條件
- 規格有歧義：停止，回報 BLOCKED 與具體問題，不自行猜測。
- 同一驗證連續失敗 3 次：停止，回報 BLOCKED。

### 回報格式（協調者只讀這一段）
```
STATUS: DONE | BLOCKED | PARTIAL
結論: <1-3 行>
變更檔: <path 清單；無則 none>
證據: <path:line 逐條>
驗證: <指令> → <PASS/FAIL>，附關鍵輸出最多 5 行
未驗證與風險: <條列；無則 none>
```
回報總長不超過 25 行，不貼整段程式碼。
