---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python Hooks

> This file extends [common/hooks.md](../common/hooks.md) with Python specific content.

## Enabled Python Hooks

| Script | Trigger | Blocking | Description |
|--------|---------|----------|-------------|
| `validate-python-ruff.sh` | Write + Edit | No (async) | ruff lint + format check |

The hook self-filters by `.py` extension, finds the nearest `pyproject.toml` for project root,
and runs `uv run ruff check` + `uv run ruff format --check` (preferred) or `.venv/bin/ruff` (fallback).

## Not Yet Enabled (manual only)

- **pyright**: Run type checking via `uv run pyright` (slower, run manually or in CI)

## Warnings

- Warn about `print()` statements in edited files (use `logging` module instead)
