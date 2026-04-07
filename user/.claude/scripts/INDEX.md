# Claude Code Scripts Index

> Centralized management for all hooks, utilities, and documentation

## Directory Structure

```
~/.claude/scripts/
├── hooks/
│   ├── _lib/                <- Shared libraries
│   │   └── detect-project.sh   (dynamic project attribute detection)
│   ├── common/              <- Language-agnostic hooks
│   │   ├── scan-hardcoded-secrets.sh  (multi-language secret scan)
│   │   └── file-size-warning.sh       (multi-language size + function length)
│   ├── php/                 <- PHP/Yii-specific hooks (11)
│   ├── python/              <- Python-specific hooks (1)
│   │   └── validate-python-ruff.sh
│   ├── dispatch-write.sh    <- PostToolUse Write dispatcher
│   ├── dispatch-edit.sh     <- PostToolUse Edit dispatcher
│   ├── dispatch-bash-pre.sh <- PreToolUse Bash dispatcher
│   ├── pre-git-operations-check.sh    (git safety)
│   ├── session-retrospective-reminder.sh
│   ├── git-status-summary.sh
│   ├── pre-commit-validation.sh
│   └── compact-reminder.sh
├── utils/              <- 5 utility scripts (PHP-focused)
├── docs/               <- Documentation
└── INDEX.md            <- This file
```

---

## Architecture: Dispatcher Pattern

Previously: 30+ individual hook entries in `settings.json`, all fired on every Write/Edit regardless of project type.

Now: 3 dispatchers route to language-specific hooks based on dynamic detection:

```
settings.json
  └── dispatch-write.sh / dispatch-edit.sh / dispatch-bash-pre.sh
        └── source _lib/detect-project.sh
              ├── HAS_PYTHON=true  → python/*.sh + common/*.sh
              ├── HAS_PHP=true     → php/*.sh + common/*.sh
              └── HAS_NODE=true    → (frontend checks)
```

**Benefits**:
- 1 process fork instead of 12+ per Write/Edit
- PHP hooks never run on Python projects (and vice versa)
- New language: add `hooks/<lang>/` + if-block in dispatchers
- Cross-platform: all paths via `git rev-parse --show-toplevel`

---

## Hook Routing

### PreToolUse
| Dispatcher | Scope | Hooks Inside |
|-----------|-------|-------------|
| `pre-git-operations-check.sh` | All projects | Git safety (direct, not dispatched) |
| `dispatch-bash-pre.sh` | Dynamic | Docker container check (project-aware), docker exec -i (PHP+WSL only) |

### PostToolUse (Write)
| Dispatcher | Always | Python | PHP |
|-----------|--------|--------|-----|
| `dispatch-write.sh` | secret scan, file size | ruff | syntax, php56, security, yii, legacy, slog, TDD red |

### PostToolUse (Edit)
| Dispatcher | Always | Python | PHP |
|-----------|--------|--------|-----|
| `dispatch-edit.sh` | secret scan, file size | ruff | syntax (blocking), php56, security, yii, legacy, slog, suggest-test |

### Stop
| Hook | Purpose |
|------|---------|
| `session-retrospective-reminder.sh` | Checklist + agent suggestions |
| `git-status-summary.sh` | Staged/unstaged/untracked summary |
| `pre-commit-validation.sh` | Pre-commit validation |
| `compact-reminder.sh` | Context handoff reminder |

---

## Project Detection (`_lib/detect-project.sh`)

Detects by marker files (no hardcoded paths):

| Variable | Detection Method |
|----------|-----------------|
| `HAS_PYTHON` | `pyproject.toml` / `setup.py` (root or subdirectory) |
| `HAS_PHP` | `composer.json` / `protected/` directory |
| `HAS_NODE` | `package.json` (root or subdirectory) |
| `HAS_YII` | `protected/config/` directory |
| `HAS_FASTAPI` | `fastapi` in pyproject.toml |
| `DOCKER_CONTAINER` | `container_name:` in docker-compose.yaml |
| `PYTHON_BACKEND_DIR` | Root or `backend/` subdirectory pyproject.toml |

---

## Configuration

Hook wiring: `~/.claude/settings.json` > `hooks` key
Project overrides: `<project>/.claude/settings.local.json` > `hooks` key
Design philosophy: `~/.claude/rules/common/hooks.md`

```bash
# Validate settings.json
python3 -m json.tool ~/.claude/settings.json > /dev/null && echo "OK"
```

---

**Last updated**: 2026-04-07
**Version**: 4.0 (dispatcher pattern refactor)
