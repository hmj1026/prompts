# Agent Orchestration

## Available Agent Roles

Use via Task tool `subagent_type`. These are **generic role names** — project-level
`execution-policy.md` defines the actual agent names (SSOT). When a project
provides specific agent names (e.g. `tdd-guide-zdpos_dev`), always use those
instead of the generic names below.

| Role | Purpose | When to Use |
|------|---------|-------------|
| architect | System design | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code review | After writing code |
| security-reviewer | Security analysis | Before commits |
| database-reviewer | Query optimization, schema design | SQL queries, migrations |
| refactor-cleaner | Dead code removal, deduplication | Cleanup tasks |

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth module
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utilities

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```
