# AGENTS.md

Legacy POS web application on PHP 5.6 + Yii 1.1 with DDD layered architecture (`domain/`, `infrastructure/`, `protected/`).

## Critical Constraints (Zero Tolerance)

- **PHP 5.6 Compatibility**: Production runs PHP 5.6.40. Modern syntax causes fatal errors.
  - Null coalescing: Use `isset($a) ? $a : $b` (never `??`).
  - Type declarations: Use PHPDoc `@param` / `@return` (never scalar/return type hints).
  - Arrays: Short syntax `[]` works on 5.6. For new or touched code, always use `[]` (style rule; scope per `CODING_STANDARDS.md` §1).
  - Anonymous functions: Closures allowed; arrow functions `fn() =>` forbidden.
- **Frontend POS State**: Global `POS` object is SSOT. New features use the existing AJAX wrappers, preferably `POS.list.ajaxPromise()` (never `fetch`, `axios`, `$.ajax`, `$.post`, `$.get`; core files that define the wrappers are exempt).
- **Communication**: Reply and write code comments in **Traditional Chinese (正體中文)**; preserve technical and domain terms in English.
- **Git Discipline**: Never auto-commit or auto-push. Use `/dhpk:smart-commit` or wait for human instructions.

## Quick Toolchain (Verified)

- **PHP Test (All)**: `vendor/bin/phpunit -c protected/tests/phpunit.xml`
- **PHP Test (Fast Pure Unit)**: `vendor/bin/phpunit -c protected/tests/phpunit-fast.xml`
- **PHP Syntax Check**: `php -l <file>`
- **Frontend Lint & Types**: `npm run lint` · `npm run typecheck`
- **Frontend Unit Test (Jest)**: `npm run test:js`
- **Frontend E2E Test (Playwright)**: `npm run test:e2e`

## Model & Tool Routing

- **Haiku**: Code search, grep, file reading, diff review.
- **Sonnet**: Default for all iterative implementation and bug fixes.
- **Opus**: High-level architecture decisions only.
- **Read-before-Write**:
  - Symbol definition/overview: `cx`
  - Blast radius & call graph: `gitnexus_impact` before modifying any symbol.
  - Execution trace: `gitnexus_query` for cross-file flows.

## Context Pointers (Verified Paths)

Front-loaded triggers for specialized documentation (read on demand):

- **Docs / OpenSpec governance** (`docs/` or `openspec/` create, edit, move, archive, visibility): [`docs/workflow/documentation-governance.md`](docs/workflow/documentation-governance.md)
- **Cross-Agent SSOT & dhpk harness** (skills, instructions, symlink topology): [`docs/workflow/agent-ssot-specification.md`](docs/workflow/agent-ssot-specification.md)
- **Split Bill QA & flow** (split-bill test, checkout stages, receipt verification): [`docs/qa/split-bill/QA-split-bill-checkout-manual.md`](docs/qa/split-bill/QA-split-bill-checkout-manual.md) · terms: [`docs/features/split-bill/vocabulary-drift.md`](docs/features/split-bill/vocabulary-drift.md)
- **PHP 5.6 Coding Style & Standards**: [`CODING_STANDARDS.md`](CODING_STANDARDS.md)
- **PHP & Yii architectural details** (ActiveRecord, transactions, CDbCriteria, error handling): [`.claude/rules/php/`](.claude/rules/php/)
- **Frontend conventions** (POS event bus, jQuery plugins, blade escape): [`docs/conventions/frontend.md`](docs/conventions/frontend.md)
- **Execution policy & review gates** (PR checklist, verification standards): [`.claude/rules/execution-policy.md`](.claude/rules/execution-policy.md)
- **Tasks & issue tracking**: Temporary tasks in `.scratch/` ([`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md)); lifecycle specs in `openspec/`.
- **Testing standards & test harness** (test layers, bootstrap, antipatterns): [`protected/tests/docs/TESTING_STANDARDS.md`](protected/tests/docs/TESTING_STANDARDS.md) · spec: [`openspec/specs/test-harness/spec.md`](openspec/specs/test-harness/spec.md)
- **Codebase design & architecture** (deep modules, seams): global skill `codebase-design` constrained by [`CODING_STANDARDS.md`](CODING_STANDARDS.md)
- **Bug investigation & diagnosis** (quick red-loop: skill `diagnosing-bugs`; deep 5-phase root cause: skill `bug-investigation`)

## Subdirectory Scopes (Hierarchical SSOT)

Each directory contains its own canonical `AGENTS.md`:

- [`domain/AGENTS.md`](domain/AGENTS.md): Domain models, DTOs, business rules, service boundaries.
- [`infrastructure/AGENTS.md`](infrastructure/AGENTS.md): Repositories, database connections, external APIs.
- [`protected/controllers/AGENTS.md`](protected/controllers/AGENTS.md): Controller actions, HTTP requests, responses.
- [`protected/models/AGENTS.md`](protected/models/AGENTS.md): ActiveRecord models, relations, scopes, validation.
- [`protected/views/AGENTS.md`](protected/views/AGENTS.md): View templates, rendering, layout, XSS escaping.
- [`protected/migrations/AGENTS.md`](protected/migrations/AGENTS.md): Database migrations, schema versioning, rollbacks.
- [`protected/tests/AGENTS.md`](protected/tests/AGENTS.md): PHPUnit tests, integration fixtures, assertions.
- [`js/AGENTS.md`](js/AGENTS.md): POS frontend legacy scripts, checkout state machine.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **zdpos-217** (72682 symbols, 181180 relationships, 606 execution flows).

> Index stale? Run `node .gitnexus/run.cjs analyze --index-only` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? Bootstrap with `npx`, `bunx`, or `pnpm dlx` — e.g. `bunx gitnexus@latest analyze` (npm 11 npx crash; #1939).

## Always Do

- **MUST run impact before editing.** Use `impact({target: "symbolName", direction: "upstream"})` or `node .gitnexus/run.cjs impact "symbolName" --direction upstream --repo .`; report callers, processes, and risk. Never substitute grep for graph analysis.
- **MUST analyze graph changes before committing.** Use `detect_changes({scope: "all"})` (MCP) or `node .gitnexus/run.cjs detect-changes --scope all --repo .` (CLI fallback). `partial: true` or `truncated: true` is not a clean check — a zero means unseen, not unaffected; re-run it. For regression review: `detect_changes({scope: "compare", base_ref: "master"})` or `node .gitnexus/run.cjs detect-changes --scope compare --base-ref "master" --repo .`.
- MUST warn on HIGH/CRITICAL `risk` pre-edit; never use `riskSharedAxes` to waive a HIGH/CRITICAL `risk` warning. Compare File/symbol: MCP File omits axes; Graph-RAG expands File.
- **MUST treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set is not evidence the symbol is unused — it can also mean the callers are not resolvable by the index (plain-object property access, dynamic dispatch, cross-language calls). `impact` pairs `UNKNOWN` with a `riskNote` saying so. Confirm with a text search before treating the symbol as safe to change or delete; do not proceed on the strength of a zero.
- **MUST use `query({search_query: "concept"})` for concepts/flows, `context({name: "symbolName"})` for a named symbol, or `impact` for blast radius, on read-only callers, dependencies, imports, or execution flow.** Graph first; text search only for empty/`UNKNOWN`/literals.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method before MCP/CLI impact analysis.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis, and never read `UNKNOWN` as an all-clear — it means the walk could not answer, which is the one verdict that requires confirming by other means.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit before MCP/CLI graph change analysis.

## Resources

| Resource | Use for |
| --- | --- |
| `gitnexus://repo/zdpos-217/context` | Codebase overview, check index freshness |
| `gitnexus://repo/zdpos-217/clusters` | All functional areas |
| `gitnexus://repo/zdpos-217/processes` | All execution flows |
| `gitnexus://repo/zdpos-217/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
| --- | --- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
