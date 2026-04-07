#!/bin/bash
# Scan for hardcoded secrets (API keys, passwords, tokens)
# Supports: .php, .py, .js, .ts, .tsx, .env
# Trigger: dispatch-write.sh / dispatch-edit.sh

FILE_PATH="$1"
[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

EXT="${FILE_PATH##*.}"
BASENAME=$(basename "$FILE_PATH")

# Skip test files (secrets in test fixtures are acceptable)
case "$FILE_PATH" in
    *test*|*spec*|*fixture*|*mock*) exit 0 ;;
esac

# Define pattern per language
PATTERN=""
case "$EXT" in
    php)
        PATTERN="(password|token|api_?key|secret)\s*=\s*['\"][^'\"]{8,}['\"]"
        ;;
    py)
        PATTERN="(password|token|api_?key|secret|credentials)\s*=\s*['\"][^'\"]{8,}['\"]"
        ;;
    js|ts|tsx)
        PATTERN="(password|token|api_?key|secret|credentials)\s*[:=]\s*['\"\`][^'\"\`]{8,}['\"\`]"
        ;;
    *)
        ;;
esac

# Also check .env files regardless of extension
if [[ "$BASENAME" == ".env" || "$BASENAME" == ".env."* ]]; then
    PATTERN="(PASSWORD|TOKEN|API_KEY|SECRET|CREDENTIALS)=.{8,}"
fi

[[ -z "$PATTERN" ]] && exit 0

FOUND=$(grep -inE "$PATTERN" "$FILE_PATH" 2>/dev/null | head -5)
if [[ -n "$FOUND" ]]; then
    echo "[secret-scan] WARNING: Possible hardcoded secret in $FILE_PATH:"
    echo "$FOUND"
fi

exit 0
