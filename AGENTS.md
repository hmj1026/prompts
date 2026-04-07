# Repository Guidelines

## Project Structure & Module Organization
- `user/` contains global, model-level instructions (for example `user/.claude/CLAUDE.md` or `user/.gemini/GEMINI.md`).
- `lib/` contains shared resources reused across projects: skills (`lib/skills/`), commands (`lib/commands/`), and language rule templates (`lib/rules/`).
- `projects/` holds per-project context. Each subfolder should include model-specific files like `CLAUDE.md`, `GEMINI.md`, and, when needed, `AGENTS.md` (example: `projects/zdpos_dev/AGENTS.md`).
- `deploy/` contains deployment tooling (`deploy.sh`, `manifest.yaml`) for symlink-based deployment.

## Build, Test, and Development Commands
- There is no build system or executable code in this repository; changes are direct Markdown edits.
- Deploy configs via `./deploy/deploy.sh user` (global) or `./deploy/deploy.sh project <name>` (project-level).
- Check sync status: `./deploy/deploy.sh --check all`.
- Useful navigation commands:
  - `rg --files` to list all documents.
  - `rg -n "AGENTS.md" projects` to locate project agent instructions.
- When adding a new project, create `projects/<project_name>/` and add the model-specific files listed above.

## Coding Style & Naming Conventions
- Use clear Markdown structure: short paragraphs, descriptive headings, and bullets for steps.
- File naming is consistent: `GEMINI.md`, `CLAUDE.md`, `AGENTS.md`. Workflow files use lower_snake_case (for example `deploy_project.sh`).
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
