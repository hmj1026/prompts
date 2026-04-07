#!/bin/bash
# Suggest corresponding test file when editing a PHP source file
# Uses dynamic project root detection instead of hardcoded paths

FILE_PATH="$1"

# Only process protected/ PHP source files (not tests themselves)
if [[ "$FILE_PATH" != *"protected/"* ]] || [[ "$FILE_PATH" == *"/tests/"* ]] || [[ "$FILE_PATH" != *.php ]]; then
  exit 0
fi

PROJECT_ROOT=$(git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null)
[[ -z "$PROJECT_ROOT" ]] && exit 0

BASENAME=$(basename "$FILE_PATH" .php)

# Search for matching test file
TEST_FILE=$(find "$PROJECT_ROOT/protected/tests" -name "${BASENAME}Test.php" 2>/dev/null | head -1)

if [ -n "$TEST_FILE" ]; then
  RELATIVE_TEST="${TEST_FILE#$PROJECT_ROOT/}"
  echo "Corresponding test: $RELATIVE_TEST"
fi
