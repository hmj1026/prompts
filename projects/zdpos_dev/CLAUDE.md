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
| Agent roster (11 agents) | `.claude/agents/INDEX.md` |
| PHP / Yii / DDD patterns | `.claude/rules/php/{yii-framework,patterns,coding-style,testing,security}.md` |
| Frontend (AJAX, JS) | `.claude/rules/frontend.md` |
| 5 deploy environments / SSH / cron / MySQL | skill `zdpos-environment` (load on demand) |
| EILogger / docs writing | `.claude/docs/{eilogger,docs-writing}.md` |
| Layer governance | `protected/CLAUDE.md`, `domain/CLAUDE.md`, `infrastructure/CLAUDE.md` |
| Page Service pattern | `docs/page-service-pattern.md` |
| Wanpo offline report SOP | `docs/operations/playbooks/wanpo-offline-report.md` (on demand) |
| Artifact contract (agent file spec) | `docs/contracts/artifact-contract.md` (on demand) |

## Settings split

- `.claude/settings.json` — team-shared, committed.
- `.claude/settings.local.json` — personal SSH / curl / cx perms, gitignored.

<!-- gitnexus:start -->
## GitNexus — code intelligence (skills load on demand)

zdpos_dev is indexed by GitNexus (91k symbols, 207k relationships).

**Hard rules** (also enforced in `.claude/rules/tool-routing.md`):

- Edit existing symbol → `gitnexus_impact({target, direction:"upstream"})` first. **Append-only exemption**: pure additions not touching existing symbol body/signature/PHPDoc may skip impact; state "append-only — gitnexus_impact skipped" in plan/commit.
- Before commit → `gitnexus_detect_changes()`.
- Rename → `gitnexus_rename` (find-and-replace forbidden).
- HIGH / CRITICAL risk → halt + warn user.

Detail per task type:

| Task | Skill |
|---|---|
| Architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Bug tracing / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, schema, resources reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index / status / clean / wiki CLI | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

Stale index → run `npx gitnexus analyze` in terminal.
<!-- gitnexus:end -->
