# zdpos-217 — Project Context

Legacy POS web application built on PHP 5.6 + Yii 1.1 framework with DDD layered architecture (`domain/`, `infrastructure/`, `protected/`).

## Rule priority

1. System / platform constraints
2. Current user request
3. This file (CLAUDE.md)
4. `.claude/rules/*.md` (local overrides) + `${CLAUDE_PLUGIN_ROOT}/rules/*.md` (dhpk canonical)
5. Modular docs (load on demand)

## Communication

- Reply in **Traditional Chinese**; write code comments in Traditional Chinese.
- Keep domain and technical terms in English (Controller, Model, View, Action, Service).

## Core rules

- **SSOT** — extend existing logic, never duplicate.
- **Read-before-write** — `cx` for definition/overview; `gitnexus_impact` before editing; `gitnexus_query` for execution flows. Full decision tree → [`docs/workflow/tool-routing.md`](docs/workflow/tool-routing.md).
- **No auto-commit** — invoke `/dhpk:smart-commit` or `/dhpk:precommit`; never auto `git add/commit/push/stash`. See [`docs/workflow/execution-policy.md`](docs/workflow/execution-policy.md).
- **PHP 5.6 syntax constraints** → [`docs/conventions/php-yii.md`](docs/conventions/php-yii.md).

## 3-Tier Model Routing

- **Haiku**: Locate code, grep, understand, diff review
- **Sonnet**: Default for everything iterative
- **Opus**: Architecture decisions only

> **NEVER use Opus for:**
> - Code lookup or file reading
> - Single-function questions
> - Diff review

## Task & Issue Tracking

- **Temporary / Scratch Tasks**: Tracked under `.scratch/`. See `docs/agents/issue-tracker.md`.
- **Structured Changes & Specs**: Managed via `openspec/` and lifecycle requests.
- **Domain Context**: See `docs/agents/domain.md`.

## Key Modular References

- **PHP 5.6 & Yii Conventions**: [`docs/conventions/php-yii.md`](docs/conventions/php-yii.md)
- **Frontend & JS Conventions**: [`docs/conventions/frontend.md`](docs/conventions/frontend.md)
- **Execution Policy & Gates**: [`docs/workflow/execution-policy.md`](docs/workflow/execution-policy.md)
- **Tool Routing**: [`docs/workflow/tool-routing.md`](docs/workflow/tool-routing.md)
- **Model Routing Details**: [`docs/workflow/model-routing.md`](docs/workflow/model-routing.md)

## Subdirectory Indices

- [`protected/AGENTS.md`](protected/AGENTS.md): Yii MVC core, controllers, models, views, tests.
- [`domain/AGENTS.md`](domain/AGENTS.md): Domain layer boundaries, models, services.
- [`infrastructure/AGENTS.md`](infrastructure/AGENTS.md): Repositories, external integrations, data access.
- [`js/AGENTS.md`](js/AGENTS.md): Legacy frontend POS scripts and state management.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **zdpos-217** (87068 symbols, 212413 relationships, 300 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

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
| `gitnexus://repo/zdpos-217/context` | Codebase overview, check index freshness |
| `gitnexus://repo/zdpos-217/clusters` | All functional areas |
| `gitnexus://repo/zdpos-217/processes` | All execution flows |
| `gitnexus://repo/zdpos-217/process/{name}` | Step-by-step execution trace |

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
