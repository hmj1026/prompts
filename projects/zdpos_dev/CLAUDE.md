# zdpos_dev — Project Context

PHP 5.6 + Yii 1.1 legacy POS. Always-on rules for all AI.

## Rule Priority
1. System/Platform constraints
2. Current user request
3. This file (CLAUDE.md)
4. AGENTS.md
5. Other docs

## Communication
- Reply in Traditional Chinese; code comments in Traditional Chinese
- Keep domain terms in English (Controller, Model, View, Action)
- Lead with conclusion, add details after

## Core Rules
- **SSOT**: Extend existing logic, never duplicate
- **Read-before-write**: `rg`/`fd` before coding
- PHP syntax: `.claude/rules/php/coding-style.md`

## Code Exploration & Memory Tools
- **GitNexus hard rules**: `gitnexus_impact` before editing a symbol / `gitnexus_detect_changes` before commit / `gitnexus_rename` for renaming (no find-and-replace); flag HIGH/CRITICAL risk
- **Full routing** (cx / gitnexus / claude-mem / Read / Grep decision tree + costs) → `.claude/rules/tool-routing.md`

## Key References
| Topic | File |
|-------|------|
| Execution strategy + agents | `.claude/rules/execution-policy.md` |
| Tool routing (cx/gitnexus/claude-mem) | `.claude/rules/tool-routing.md` |
| PHP/Yii DDD patterns | `.claude/rules/php/yii-framework.md` |
| 5 deploy environments / SSH / cron / MySQL / log paths | skill `zdpos-environment` (load on demand: cron, SSH, deploy, Cloud SQL, application.log, env differences) |
| Frontend (AJAX, JS) | `.claude/rules/frontend.md` |
| EILogger | `.claude/docs/eilogger.md` |
| Docs writing rules | `.claude/docs/docs-writing.md` |
| Layer governance | `protected/CLAUDE.md`, `domain/CLAUDE.md`, `infrastructure/CLAUDE.md` |
| Page Service pattern | `docs/page-service-pattern.md` |
| Wanpo offline report SOP | `docs/operations/playbooks/wanpo-offline-report.md` (load on-demand: "wanpo offline report" / "salesConsolidate chunk") |
| Artifact contract (agent file spec) | `docs/contracts/artifact-contract.md` (load on demand; agent prompts embed condensed rules) |

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **zdpos_dev** (124391 symbols, 236840 relationships, 300 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/zdpos_dev/context` | Codebase overview, check index freshness |
| `gitnexus://repo/zdpos_dev/clusters` | All functional areas |
| `gitnexus://repo/zdpos_dev/processes` | All execution flows |
| `gitnexus://repo/zdpos_dev/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
