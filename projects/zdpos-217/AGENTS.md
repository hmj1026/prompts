# AGENTS.md

Legacy POS web application on PHP 5.6 + Yii 1.1 with DDD layered architecture (`domain/`, `infrastructure/`, `protected/`).

## Critical Constraints (Zero Tolerance)

- **PHP 5.6 Compatibility**: Production runs PHP 5.6.40. Modern syntax causes fatal errors.
  - Null coalescing: Use `isset($a) ? $a : $b` (never `??`).
  - Type declarations: Use PHPDoc `@param` / `@return` (never scalar/return type hints).
  - Arrays: Short syntax `[]` is supported and preferred.
  - Anonymous functions: Closures allowed; arrow functions `fn() =>` forbidden.
- **Frontend POS State**: Global `POS` object is SSOT. Use `POS.list.ajaxPromise()` for async calls (never `fetch`, `axios`, or raw `$.ajax`).
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

This project is indexed by GitNexus as **zdpos-217**. Use GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Operating Rules

- **Impact Analysis**: Run `gitnexus_impact({target: "symbolName", direction: "upstream"})` before modifying any symbol. Report blast radius and risk level.
- **Change Verification**: Run `gitnexus_detect_changes()` before concluding tasks to confirm changes match expected symbols.
- **Safe Refactoring**: Use `gitnexus_rename` for symbol renames across the call graph.
- **Concept Discovery**: Use `gitnexus_query({query: "concept"})` to locate execution flows grouped by process.
- **Symbol Inspection**: Use `gitnexus_context({name: "symbolName"})` for callers, callees, and process participation.

## Resources & Workflows

| Resource | Purpose |
|----------|---------|
| `gitnexus://repo/zdpos-217/context` | Overview and index freshness |
| `gitnexus://repo/zdpos-217/processes` | Execution flows |
| `gitnexus://repo/zdpos-217/process/{name}` | Step-by-step flow trace |
| `.agents/skills/gitnexus/` | Skills for exploring, impact analysis, debugging, and refactoring |
<!-- gitnexus:end -->
