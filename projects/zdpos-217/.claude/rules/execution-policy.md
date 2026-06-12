# Execution Policy

> **Canonical**: `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` (dhpk v0.4.0+) — read that first for task modes, sentinel chain rule, agent dispatch table, AI-judgment back-stop semantics.

## zdpos overrides

- **6th sentinel slot enabled**: `.pending-migration-review` → `dhpk:migration-reviewer`. Wired locally in `.claude/hooks/post-edit-remind.sh` and `.claude/hooks/_lib/payload.sh` (SENTINEL_NAMES / SENTINEL_AGENTS arrays). dhpk's `userConfig.review_agents` default is 5 slots; the 6th is project-extension.
- **Repository hot tables** (for `dhpk:performance-analyzer` back-stop): `records`, `orders`, `stock`, `inventory`, `pay_actions`. Repository methods touching these tables → AI-judgment-trigger the performance-analyzer back-stop.
- **View-layer script back-stop**: `protected/views/**/*.php` `<script>` block edits → `dhpk:frontend-reviewer` (AI judgment; hook does not detect view-layer script edits).
- **OpenSpec workflow**: zdpos uses OpenSpec extensively. `/opsx:*` invocations take precedence over generic skill priorities when explicitly typed by user.
- **Sentinel directory**: zdpos sentinels live in `.claude/artifacts/sessions/.pending-*` (project-local path). Sentinels are written by `.claude/hooks/post-edit-remind.sh` and cleared by `${CLAUDE_PLUGIN_ROOT}/scripts/hooks/clear-sentinel.sh` invoked from each reviewer agent's Closing hook.
- **Git pipeline**: `feat|fix|docs|refactor/*` → `develop` → `master`. **No auto-commit** — invoke `/dhpk:smart-commit` or `/dhpk:precommit`.
- **Anti-rationalization**: see `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md`; load on-demand when tempted to skip a reviewer / TDD / sentinel mandated step.

## Cross-references

- `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` — canonical task modes + chain rule
- `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` — cx / gitnexus / claude-mem decision tree
- `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md` — self-rebuttal table
- `.claude/rules/php/{coding-style,patterns,security,testing,yii-framework}.md` — zdpos PHP / Yii 1.1 specifics (kept local; not in dhpk)
- `.claude/rules/js/static-checks.md` — zdpos JS / TS static-check tier (kept local)
- `.claude/rules/frontend.md` — POS.* global, AJAX wrapper SSOT (kept local)
