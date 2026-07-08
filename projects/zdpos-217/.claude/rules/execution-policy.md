# Execution Policy

> **Canonical**: `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` (dhpk v0.4.0+) — read that first for task modes, the sentinel **triage + parallel-dispatch** rule (reviewers run concurrently after triage drops false positives; not a serial chain), agent dispatch table, AI-judgment back-stop semantics.

## zdpos overrides

- **Sentinel chain（槽數 SSOT — 全專案唯一定義出處，他處勿重述）**：dhpk upstream schema 共定義 **7 個 sentinel slot** = dhpk 預設 5（`.pending-{review, db-review, security-review, frontend-review, doc-review}`）+ **polyfill**（`.pending-polyfill-review`）+ **migration**（`.pending-migration-review` → `dhpk:migration-reviewer`，zdpos 經 settings `review_trigger_extra_paths: ["mig:protected/migrations/"]` + yii-1.1 module triggers opt-in）。**polyfill 槽在 zdpos 為 N/A**：僅當 library-author module 啟用時才會寫入該槽，zdpos 未啟用此 module，故 zdpos **實際可達 6 槽**（5 預設 + migration；polyfill 不計入）。本地 `_lib/payload.sh` 僅為 statusline / 殘留本地 hook 的 **mirror**（順序鏡像 plugin，不再是 fork）。
- **Repository hot tables** (for `dhpk:performance-analyzer` back-stop): `records`, `orders`, `stock`, `inventory`, `pay_actions`. Repository methods touching these tables → AI-judgment-trigger the performance-analyzer back-stop.
- **View-layer script back-stop**: `protected/views/**/*.php` `<script>` block edits → `dhpk:frontend-reviewer` (AI judgment; hook does not detect view-layer script edits).
- **OpenSpec workflow**: zdpos uses OpenSpec extensively. `/opsx:*` invocations take precedence over generic skill priorities when explicitly typed by user.
- **Sentinel directory**: zdpos sentinels live in `.claude/artifacts/sessions/.pending-*` (project-local path). Sentinels are written by the dhpk plugin's `post-edit-remind.sh`（經 `post-edit-dispatch.sh`）and cleared by `${CLAUDE_PLUGIN_ROOT}/scripts/hooks/clear-sentinel.sh` invoked from each reviewer agent's Closing hook.
- **Git pipeline (zdpos branch flow)**: `feat|fix|docs|refactor/*` → `develop` → `master`。no-auto-commit 規範以 canonical `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` §Git pipeline 為準（invoke `/dhpk:smart-commit` / `/dhpk:precommit`）。
- **Anti-rationalization**: see `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md`; load on-demand when tempted to skip a reviewer / TDD / sentinel mandated step.

## Cross-references

- `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` — canonical task modes + triage / parallel-dispatch rule
- `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` — cx / gitnexus / claude-mem decision tree
- `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md` — self-rebuttal table
- `.claude/rules/php/{coding-style,patterns,security,testing,yii-framework}.md` — zdpos PHP / Yii 1.1 specifics (kept local; not in dhpk)
- `.claude/rules/js/static-checks.md` — zdpos JS / TS static-check tier (kept local)
- `.claude/rules/frontend.md` — POS.* global, AJAX wrapper SSOT (kept local)
