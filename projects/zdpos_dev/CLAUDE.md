# zdpos_dev — Project Context

PHP 5.6 + Yii 1.1 legacy POS. Always-on rules for all AI.

## Dependencies

- **dhpk plugin v0.4.0+** (required) — provides ~70 commands + 16 role agents + 17 modules of stack guidance + `rules/` resource layer. Install: `claude plugin marketplace add hmj1026/dhpk && claude plugin install dhpk@dhpk@v0.4.0`. Recommended modules for zdpos: `php-5.6, yii-1.1, phpunit-5.7, js`. Most generic dev workflows are now `/dhpk:<command>`; project-local commands documented in `.claude/commands/INDEX.md`. Note on `${CLAUDE_PLUGIN_ROOT}` paths below: Claude Code resolves this at runtime to `~/.claude/plugins/cache/dhpk/dhpk/<version>/` (the on-disk install path); to navigate manually from a terminal, substitute that path or run `ls ~/.claude/plugins/cache/dhpk/dhpk/` to confirm the active version.
- **OpenSpec plugin** (required) — provides `/opsx:*` commands. Install separately per OpenSpec docs.

## Rule priority

1. System / platform constraints
2. Current user request
3. This file (CLAUDE.md)
4. `.claude/rules/*.md` (auto-loaded — local overrides) + `${CLAUDE_PLUGIN_ROOT}/rules/*.md` (dhpk canonical)
5. Other docs (load on demand)

## Communication

- Reply in **Traditional Chinese**; code comments in Traditional Chinese.
- Keep domain terms in English (Controller, Model, View, Action).
- Lead with conclusion; details after.

## Core rules

- **SSOT** — extend existing logic, never duplicate.
- **Read-before-write** — `cx overview` / `cx definition` / `gitnexus_impact` before coding. Hierarchy: `cx > gitnexus > Read`. Full routing → `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` (dhpk canonical) + `.claude/rules/tool-routing.md` (zdpos overrides).
- **No auto-commit** — invoke `/dhpk:smart-commit` or `/dhpk:precommit`; never auto `git add/commit/push/stash`. See `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` "Git pipeline".
- PHP 5.6 syntax limits → `.claude/rules/php/coding-style.md`.

## Key references

| Topic | File |
|---|---|
| Execution strategy + sentinel chain | `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` (canonical) + `.claude/rules/execution-policy.md` (zdpos overrides: 6th sentinel slot, hot tables) |
| Tool routing (cx / gitnexus / claude-mem) | `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` + `.claude/rules/tool-routing.md` (zdpos additions) |
| Anti-rationalization patterns | `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md` + `.claude/rules/anti-rationalization.md` |
| Sub-agent prompt boilerplate (cx + DB) | `.claude/docs/subagent-prompt-template.md` |
| Agent roster | `${CLAUDE_PLUGIN_ROOT}/agents/INDEX.md` (canonical 16 dhpk agents) + `.claude/agents/INDEX.md` (zdpos chain mapping incl. 6th-slot migration-reviewer) |
| Commands catalog | `${CLAUDE_PLUGIN_ROOT}/commands/INDEX.md` (canonical ~70 dhpk commands under `dhpk:` namespace) + `.claude/commands/INDEX.md` (zdpos locals: `/create-dev`, `/update-codemaps`) |
| MCP server inventory (gitnexus / context7 / codex / claude-mem / chrome-devtools) | `.claude/docs/mcp-servers.md` |
| PHP / Yii / DDD patterns | `.claude/rules/php/{yii-framework,patterns,coding-style,testing,security}.md` |
| Frontend (AJAX, JS) | `.claude/rules/frontend.md` |
| 5 deploy environments / SSH / cron / MySQL | skill `zdpos-environment` (load on demand) |
| EILogger / docs writing | `.claude/docs/{eilogger,docs-writing}.md` |
| Layer governance | `protected/CLAUDE.md`, `domain/CLAUDE.md`, `infrastructure/CLAUDE.md` |
| Page Service pattern | `docs/guides/page-service-pattern.md` |
| Wanpo offline report SOP | `docs/operations/playbooks/wanpo-offline-report.md` (on demand) |
| Artifact contract (agent file spec) | `docs/contracts/artifact-contract.md` (on demand) |

## Settings split

- `.claude/settings.json` — team-shared, committed.
- `.claude/settings.local.json` — personal SSH / curl / cx perms, gitignored.
- `.claude/.harness-profile` — optional one-line profile (`minimal` / `standard` / `strict`), gitignored. Env `$ZDPOS_HOOK_PROFILE` overrides; falls back to `standard`. `minimal` suppresses Stop-hook reminders.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

Indexed as **zdpos_dev** (97k symbols, 216k relationships, 300 execution flows). If a tool warns the index is stale → `npx gitnexus analyze` first.

**Hard rules**:
- MUST `gitnexus_impact({target, direction:"upstream"})` before editing any symbol; report blast radius; warn on HIGH/CRITICAL.
- MUST `gitnexus_detect_changes()` before committing.
- NEVER rename via find-and-replace; use `gitnexus_rename`.

For unfamiliar code: `gitnexus_query({query})`. For full symbol context: `gitnexus_context({name})`.

| Task | Skill file |
|------|------------|
| Architecture / "how does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / impact | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools / schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

Resources: `gitnexus://repo/zdpos_dev/{context,clusters,processes,process/<name>}`.

<!-- gitnexus:end -->
