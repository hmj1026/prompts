# zdpos_dev — Project Context

PHP 5.6 + Yii 1.1 legacy POS. Always-on rules for all AI.

## Rule priority

1. System / platform constraints
2. Current user request
3. This file (CLAUDE.md)
4. `.claude/rules/*.md` (auto-loaded)
5. Other docs (load on demand)

## Communication

- Reply in **Traditional Chinese**; code comments in Traditional Chinese.
- Keep domain terms in English (Controller, Model, View, Action).
- Lead with conclusion; details after.

## Core rules

- **SSOT** — extend existing logic, never duplicate.
- **Read-before-write** — `cx overview` / `cx definition` / `gitnexus_impact` before coding. Hierarchy: `cx > gitnexus > Read`. Full routing → `.claude/rules/tool-routing.md`.
- **No auto-commit** — invoke `/smart-commit` or `/precommit`; never auto `git add/commit/push/stash`. See `execution-policy.md` "Git pipeline".
- PHP 5.6 syntax limits → `.claude/rules/php/coding-style.md`.

## Key references

| Topic | File |
|---|---|
| Execution strategy + sentinel review gates | `.claude/rules/execution-policy.md` |
| Tool routing (cx / gitnexus / claude-mem) | `.claude/rules/tool-routing.md` |
| Sub-agent prompt boilerplate (cx + DB) | `.claude/docs/subagent-prompt-template.md` |
| Agent roster (14 agents) | `.claude/agents/INDEX.md` |
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
