# Execution Policy

> **Canonical**: `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` (dhpk v0.4.0+) — read that first for task modes, sentinel chain rule, agent dispatch table, AI-judgment back-stop semantics.

## zdpos overrides

- **Sentinel chain（槽數 SSOT — 全專案唯一定義出處，他處勿重述）**：共 **7 個 sentinel** = dhpk 預設 5（`.pending-{review, db-review, security-review, frontend-review, doc-review}`）+ **polyfill**（`.pending-polyfill-review`，library-author / php module hook 貢獻）+ **migration**（`.pending-migration-review` → `dhpk:migration-reviewer`，zdpos 經 settings `review_trigger_extra_paths: ["mig:protected/migrations/"]` + yii-1.1 module triggers opt-in）。全 7 槽由 plugin `post-edit-remind.sh`（經 `post-edit-dispatch.sh`）寫入。⚠️ **序數標籤勿信**：dhpk 上游 `execution-policy.md` 稱 migration 為「6th slot」、polyfill module hook 又自稱「sixth slot」——兩者皆自稱第 6，故一律以上述 enumeration 計數，不用序數。本地 `_lib/payload.sh` 僅為 statusline / 殘留本地 hook 的 **mirror**（順序鏡像 plugin，不再是 fork）。
- **Repository hot tables** (for `dhpk:performance-analyzer` back-stop): `records`, `orders`, `stock`, `inventory`, `pay_actions`. Repository methods touching these tables → AI-judgment-trigger the performance-analyzer back-stop.
- **View-layer script back-stop**: `protected/views/**/*.php` `<script>` block edits → `dhpk:frontend-reviewer` (AI judgment; hook does not detect view-layer script edits).
- **OpenSpec workflow**: zdpos uses OpenSpec extensively. `/opsx:*` invocations take precedence over generic skill priorities when explicitly typed by user.
- **Sentinel directory**: zdpos sentinels live in `.claude/artifacts/sessions/.pending-*` (project-local path). Sentinels are written by the dhpk plugin's `post-edit-remind.sh`（經 `post-edit-dispatch.sh`）and cleared by `${CLAUDE_PLUGIN_ROOT}/scripts/hooks/clear-sentinel.sh` invoked from each reviewer agent's Closing hook.
- **Git pipeline (zdpos branch flow)**: `feat|fix|docs|refactor/*` → `develop` → `master`。no-auto-commit 規範以 canonical `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` §Git pipeline 為準（invoke `/dhpk:smart-commit` / `/dhpk:precommit`）。
- **Anti-rationalization**: see `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md`; load on-demand when tempted to skip a reviewer / TDD / sentinel mandated step.

## Cross-references

- `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` — canonical task modes + chain rule
- `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` — cx / gitnexus / claude-mem decision tree
- `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md` — self-rebuttal table
- `.claude/rules/php/{coding-style,patterns,security,testing,yii-framework}.md` — zdpos PHP / Yii 1.1 specifics (kept local; not in dhpk)
- `.claude/rules/js/static-checks.md` — zdpos JS / TS static-check tier (kept local)
- `.claude/rules/frontend.md` — POS.* global, AJAX wrapper SSOT (kept local)
