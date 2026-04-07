# Hooks Philosophy

## Hook Types

| Type | When | Use For |
|------|------|---------|
| **PreToolUse** | Before tool executes | Safety gates (block dangerous operations) |
| **PostToolUse** | After tool completes | Validation, linting, suggestions |
| **Stop** | Session ends | Cleanup, reminders, status summary |

## Design Principles

1. **Minimal blocking**: Only PreToolUse hooks should block. PostToolUse hooks
   should be `async: true` (non-blocking) unless the check is critical enough
   to halt further edits (e.g., PHP syntax errors).

2. **Fast execution**: Hooks run on every tool call. Keep them under 5 seconds.
   Use 10-60 second timeouts only for test execution hooks.

3. **Dispatcher pattern**: Global hooks use dispatchers (`dispatch-write.sh`,
   `dispatch-edit.sh`, `dispatch-bash-pre.sh`) that source `_lib/detect-project.sh`
   to detect project language/framework, then call only relevant hooks.
   Individual hooks still self-filter by file extension as a safety net.

4. **Idempotent**: Hooks must be safe to run multiple times on the same file.

5. **No side effects**: Hooks report findings but do not modify files.
   Modifications are the agent's responsibility based on hook output.

## Matcher Parity

Write and Edit matchers should run equivalent checks. A new file (Write) is
arguably higher risk than a partial change (Edit), so Write should never have
fewer checks than Edit.

## Configuration

```
~/.claude/scripts/hooks/
├── _lib/detect-project.sh    # Project attribute detection
├── common/                   # Language-agnostic hooks
├── php/                      # PHP/Yii hooks
├── python/                   # Python hooks
├── dispatch-write.sh         # PostToolUse Write dispatcher
├── dispatch-edit.sh          # PostToolUse Edit dispatcher
└── dispatch-bash-pre.sh      # PreToolUse Bash dispatcher
```

Hook wiring: `~/.claude/settings.json` under `hooks` key.
Project overrides: `<project>/.claude/settings.local.json`.
Full index: `~/.claude/scripts/INDEX.md`.
