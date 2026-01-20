<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# Repository Guidelines

## Project Structure & Module Organization
- `projects/` holds per-project context. Each subfolder should include model-specific files like `GEMINI.md`, `CLAUDE.md`, and, when needed, `AGENTS.md` (example: `projects/zdpos_dev/AGENTS.md`).
- `user/` contains global, model-level instructions (for example `user/.gemini/GEMINI.md` or `user/.claude/CLAUDE.md`).
- `workflows/` contains reusable SOPs such as `workflows/create_openspec_proposal.md`.
- `GEMINI.md` at the repo root provides a high-level overview and conventions.

## Build, Test, and Development Commands
- There is no build system or executable code in this repository; changes are direct Markdown edits.
- Useful navigation commands:
  - `rg --files` to list all documents.
  - `rg -n "AGENTS.md" projects` to locate project agent instructions.
- When adding a new project, create `projects/<project_name>/` and add the model-specific files listed above.

## Coding Style & Naming Conventions
- Use clear Markdown structure: short paragraphs, descriptive headings, and bullets for steps.
- File naming is consistent: `GEMINI.md`, `CLAUDE.md`, `AGENTS.md`. Workflow files use lower_snake_case (for example `create_openspec_proposal.md`).
- Match the language used by the target agent file (some project files may be in Traditional Chinese).

## Testing Guidelines
- No automated tests are present. Validate by reading for clarity, correctness, and broken paths.
- Optional: run `markdownlint` if it is already available in your environment.

## Commit & Pull Request Guidelines
- Commit messages in history are short, one-line summaries (Chinese or English). Keep them scoped and descriptive (for example `update`).
- Prefer one logical change per commit (single project context or workflow).
- If using PRs, include a brief summary, affected paths (for example `projects/zdpos_dev/GEMINI.md`), and any required follow-up updates for other model files.

## Security & Configuration Notes
- Do not store secrets or credentials. Reference secure locations or environment variables instead.
- For new workflows, document prerequisites and inputs at the top of the workflow file.
