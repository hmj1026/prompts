# AGENTS.md

Legacy POS web application built on PHP 5.6 + Yii 1.1 framework with DDD layered architecture (`domain/`, `infrastructure/`, `protected/`).

## Package Manager & Toolchain

- **PHP (Backend)**: Composer (`vendor/bin/phpunit -c phpunit.xml`, `php -l <file>`)
- **JS (Frontend)**: npm (`npm run lint`, `npm run typecheck` — no build step)

## Core Working Principles

- **Language**: Reply and write code comments in **Traditional Chinese (正體中文)**; preserve technical terms in English.
- **Safety & Read-before-Write**:
  - Symbol definition/overview $\rightarrow$ `cx`
  - Blast radius & execution flow $\rightarrow$ `GitNexus` (impact analysis required before editing)
  - Code changes $\rightarrow$ Extend existing single source of truth (SSOT), never duplicate.
- **Git Discipline**: No automatic commits (`/dhpk:smart-commit` or `/dhpk:precommit` required).

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

## Modular References

- **Documentation／OpenSpec governance**: When creating, moving, archiving, deleting, generating, or changing Git visibility for anything under `docs/` or `openspec/`, or when producing evidence／receipts／runtime artifacts, read [`docs/workflow/documentation-governance.md`](docs/workflow/documentation-governance.md) first. Classify the content before choosing its path; preserve untracked／ignored unique content until an owner explicitly decides its destination.
- **Review & evidence rules**: When reviewing or changing code, tests, OpenSpec evidence, Golden assets, or harnesses, read [`CODING_STANDARDS.md`](CODING_STANDARDS.md) (見 feature 分支或本機端規範).
- **Split Bill QA**：安排或執行拆帳驗收時，依 [`docs/qa/QA-split-bill-checkout-manual.md`](docs/qa/QA-split-bill-checkout-manual.md) 的三階段順序與完成條件；查找規格、維運或技術驗證時，從 [`docs/features/split-bill/README.md`](docs/features/split-bill/README.md) 分流。歷史 receipt 的結果只適用原測試版本與環境。
- **PHP 5.6 & Yii Architecture**: [`.claude/rules/php/`](.claude/rules/php/)（或 feature 分支 [`docs/conventions/php-yii.md`](docs/conventions/php-yii.md)）
- **Frontend & JS Conventions**: [`docs/conventions/frontend.md`](docs/conventions/frontend.md)
- **Execution Policy & Review Gates**: [`.claude/rules/execution-policy.md`](.claude/rules/execution-policy.md)（或 feature 分支 [`docs/workflow/execution-policy.md`](docs/workflow/execution-policy.md)）
- **Tool Routing Decision Tree**: [`.claude/rules/tool-routing.md`](.claude/rules/tool-routing.md)
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
