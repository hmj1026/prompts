#!/bin/bash
# dispatch-edit.sh -- PostToolUse Edit dispatcher
# Detects project attributes and runs only relevant hooks.
# Called from ~/.claude/settings.json with: bash ~/.claude/scripts/hooks/dispatch-edit.sh "$filePath"
set -o pipefail

FILE="$1"
[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HOOKS_DIR/_lib/detect-project.sh"

# Skip if project defines its own hooks (avoid double execution with additive merge)
if [[ -d "$PROJECT_ROOT/.claude/hooks" ]] && ls "$PROJECT_ROOT/.claude/hooks"/*.sh &>/dev/null; then
    exit 0
fi

EXT="${FILE##*.}"

# -- Common checks (all projects) --
bash "$HOOKS_DIR/common/scan-hardcoded-secrets.sh" "$FILE"
bash "$HOOKS_DIR/common/file-size-warning.sh" "$FILE"

# -- Python --
if $HAS_PYTHON && [[ "$EXT" == "py" ]]; then
    bash "$HOOKS_DIR/python/validate-python-ruff.sh" "$FILE"
fi

# -- PHP --
if $HAS_PHP && [[ "$EXT" == "php" ]]; then
    # Blocking syntax check for Edit (catches parse errors immediately)
    bash "$HOOKS_DIR/php/validate-php-syntax-edit.sh" "$FILE"
    bash "$HOOKS_DIR/php/check-php56-compatibility.sh" "$FILE"
    bash "$HOOKS_DIR/php/check-security-vulnerabilities.sh" "$FILE"
    bash "$HOOKS_DIR/php/validate-yii-controller.sh" "$FILE"
    bash "$HOOKS_DIR/php/validate-yii-model.sh" "$FILE"
    bash "$HOOKS_DIR/php/check-legacy-response-format.sh" "$FILE"
    bash "$HOOKS_DIR/php/check-slog-method.sh" "$FILE"
    bash "$HOOKS_DIR/php/suggest-test-file.sh" "$FILE"
fi

# -- Frontend (JS/TS in PHP projects with custom AJAX wrappers) --
if $HAS_PHP && [[ "$EXT" == "js" || "$EXT" == "ts" || "$EXT" == "tsx" ]]; then
    bash "$HOOKS_DIR/php/check-frontend-banned-apis.sh" "$FILE"
fi

exit 0
