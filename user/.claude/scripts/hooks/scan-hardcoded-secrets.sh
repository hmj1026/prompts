#!/bin/bash
# Scan for hardcoded secrets (API keys, passwords, tokens)

FILE_PATH="$1"

if [[ "$FILE_PATH" == *.php ]]; then
  if grep -iE "(password|token|api_?key|secret)\s*[=']|['\"]([A-Za-z0-9]{32,})['\"]" "$FILE_PATH"; then
    echo '⚠️  WARNING: Possible hardcoded secret detected'
  fi || true
fi
