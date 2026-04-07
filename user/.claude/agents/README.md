# Agent Templates

These are **templates**, not directly deployed to `~/.claude/agents/`.

Project-specific agents are derived from these templates with custom naming:
- `architect.md` (template) -> `architect-zdpos_dev.md` (project agent)
- `tdd-guide.md` (template) -> `tdd-guide-zdpos_dev.md` (project agent)

Project agents live in `projects/<name>/.claude/agents/` and are deployed
to `~/projects/<name>/.claude/agents/`.

## Available Templates

| Template | Purpose |
|----------|---------|
| architect | System design and architecture |
| bug-investigator | Root cause analysis |
| build-error-resolver | Build error resolution |
| code-reviewer | Code review for quality/security |
| database-reviewer | Query optimization, schema design |
| doc-updater | Documentation updates |
| e2e-runner | Playwright E2E testing |
| go-build-resolver | Go build error resolution |
| go-reviewer | Go code review |
| planner | Feature implementation planning |
| python-reviewer | Python code review |
| refactor-cleaner | Dead code cleanup |
| security-reviewer | Security vulnerability analysis |
| tdd-guide | Test-driven development |
