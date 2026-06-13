# Execution Policy

> **Canonical**: `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` (dhpk v0.4.0+) — read that first for task modes, sentinel chain rule, agent dispatch table, AI-judgment back-stop semantics.

## zdpos overrides

- **Migration sentinel slot**: `.pending-migration-review` → `dhpk:migration-reviewer`. Since dhpk v0.10.0 this is the **official slot 6**（7 槽：code/db/sec/fe/doc/polyfill/migration），由 plugin `post-edit-remind.sh` 寫入；zdpos 透過 settings.local.json `review_trigger_extra_paths: ["mig:protected/migrations/"]`（+ yii-1.1 module triggers）opt-in。本地 `_lib/payload.sh` 僅為 statusline / 殘留本地 hook 的 **mirror**（順序鏡像 plugin，不再是 fork）。
- **Repository hot tables** (for `dhpk:performance-analyzer` back-stop): `records`, `orders`, `stock`, `inventory`, `pay_actions`. Repository methods touching these tables → AI-judgment-trigger the performance-analyzer back-stop.
- **View-layer script back-stop**: `protected/views/**/*.php` `<script>` block edits → `dhpk:frontend-reviewer` (AI judgment; hook does not detect view-layer script edits).
- **OpenSpec workflow**: zdpos uses OpenSpec extensively. `/opsx:*` invocations take precedence over generic skill priorities when explicitly typed by user.
- **Sentinel directory**: zdpos sentinels live in `.claude/artifacts/sessions/.pending-*` (project-local path). Sentinels are written by the dhpk plugin's `post-edit-remind.sh`（經 `post-edit-dispatch.sh`）and cleared by `${CLAUDE_PLUGIN_ROOT}/scripts/hooks/clear-sentinel.sh` invoked from each reviewer agent's Closing hook.
- **Git pipeline**: `feat|fix|docs|refactor/*` → `develop` → `master`. **No auto-commit** — invoke `/dhpk:smart-commit` or `/dhpk:precommit`.
- **Anti-rationalization**: see `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md`; load on-demand when tempted to skip a reviewer / TDD / sentinel mandated step.

## Cross-references

- `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` — canonical task modes + chain rule
- `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` — cx / gitnexus / claude-mem decision tree
- `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md` — self-rebuttal table
- `.claude/rules/php/{coding-style,patterns,security,testing,yii-framework}.md` — zdpos PHP / Yii 1.1 specifics (kept local; not in dhpk)
- `.claude/rules/js/static-checks.md` — zdpos JS / TS static-check tier (kept local)
- `.claude/rules/frontend.md` — POS.* global, AJAX wrapper SSOT (kept local)
