#!/bin/bash
# Check for SQL injection and direct input vulnerabilities

FILE_PATH="$1"

if [[ "$FILE_PATH" == *.php ]]; then
  if grep -E '\$sql\s*=.*\$[a-zA-Z_]|".*\$[a-zA-Z_].*".*SELECT|\$_(?:GET|POST|REQUEST)\[' "$FILE_PATH"; then
    echo '⚠️  WARNING: Possible SQL injection or direct input vulnerability detected'
  fi || true
fi
