# User-Level CLAUDE.md

User-level configs apply globally across all projects.

---

@CX.md

## Core Workflow

1. **Agent-First**: Delegate complex work to specialized agents (Task tool)
2. **Parallel Execution**: Launch independent agents concurrently
3. **Plan Before Execute**: Use Plan Mode for multi-file changes
4. **TDD**: Write tests first, 80%+ coverage (see `testing.md`)

---

## Modular Rules

Detailed guidelines in `~/.claude/rules/`:

| File | Contents |
|------|----------|
| coding-style.md | Immutability, file organization |
| git-workflow.md | Conventional commits, PR workflow |
| testing.md | TDD workflow, 80% coverage |
| security.md | Security response protocol, rate limiting |
| agents.md | Agent roster, parallel execution |
| patterns.md | Repository pattern, API responses |
| performance.md | Model selection |

> Language-specific rules live in each project's `.claude/rules/` (not global).

---

## Personal Preferences

- No emojis in code, comments, or documentation
- Prefer immutability -- never mutate objects or arrays
- Many small files: 200-400 lines typical, 800 max
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- Always redact logs; never paste secrets
