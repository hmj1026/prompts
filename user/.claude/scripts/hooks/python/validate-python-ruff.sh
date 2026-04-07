#!/bin/bash
# Validate Python files with ruff (lint check)
# Trigger: PostToolUse Write + Edit (async, non-blocking)

FILE_PATH="$1"

# Only check .py files
if [[ "$FILE_PATH" != *.py ]]; then
    exit 0
fi

# Skip if file doesn't exist (deleted)
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Find nearest pyproject.toml to determine project root
DIR="$(dirname "$FILE_PATH")"
PROJECT_ROOT=""
while [[ "$DIR" != "/" ]]; do
    if [[ -f "$DIR/pyproject.toml" ]]; then
        PROJECT_ROOT="$DIR"
        break
    fi
    DIR="$(dirname "$DIR")"
done

# No pyproject.toml found -- skip
if [[ -z "$PROJECT_ROOT" ]]; then
    exit 0
fi

# Try uv run ruff (preferred), fall back to direct .venv/bin/ruff
if command -v uv &>/dev/null && [[ -f "$PROJECT_ROOT/uv.lock" ]]; then
    output=$(cd "$PROJECT_ROOT" && uv run ruff check "$FILE_PATH" 2>&1)
    rc=$?
elif [[ -x "$PROJECT_ROOT/.venv/bin/ruff" ]]; then
    output=$("$PROJECT_ROOT/.venv/bin/ruff" check --config "$PROJECT_ROOT/pyproject.toml" "$FILE_PATH" 2>&1)
    rc=$?
else
    # ruff not available -- skip silently
    exit 0
fi

if [[ $rc -ne 0 && -n "$output" ]]; then
    echo "ruff lint errors:"
    echo "$output"
fi

# Format check (same tool resolution as above)
if command -v uv &>/dev/null && [[ -f "$PROJECT_ROOT/uv.lock" ]]; then
    fmt_output=$(cd "$PROJECT_ROOT" && uv run ruff format --check "$FILE_PATH" 2>&1)
    fmt_rc=$?
elif [[ -x "$PROJECT_ROOT/.venv/bin/ruff" ]]; then
    fmt_output=$("$PROJECT_ROOT/.venv/bin/ruff" format --check --config "$PROJECT_ROOT/pyproject.toml" "$FILE_PATH" 2>&1)
    fmt_rc=$?
else
    fmt_rc=0
fi

if [[ ${fmt_rc:-0} -ne 0 ]]; then
    echo "ruff format: file needs reformatting: $FILE_PATH"
fi

exit 0
