#!/bin/bash
# Check for SQL injection and direct input vulnerabilities

FILE_PATH="$1"

if [[ "$FILE_PATH" == *.php ]]; then
  # Check for common vulnerabilities (non-blocking warnings):
  # 1. Direct variable injection into SQL strings
  # 2. Direct $_GET/$_POST/$_REQUEST access
  has_issue=0

  # Check for $sql concatenation with variables
  if grep -E '\$sql\s*=.*\$[a-zA-Z_]' "$FILE_PATH" > /dev/null 2>&1; then
    has_issue=1
  fi

  # Check for direct input access (should use Yii::app()->request->...)
  if grep -E '\$_(?:GET|POST|REQUEST)' "$FILE_PATH" > /dev/null 2>&1; then
    has_issue=1
  fi

  if [[ $has_issue -eq 1 ]]; then
    echo '⚠️  WARNING: Possible SQL injection or direct input vulnerability detected'
  fi
fi
