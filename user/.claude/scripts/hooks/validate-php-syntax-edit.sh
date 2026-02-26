#!/bin/bash
# Validate PHP syntax for .php files on Edit (blocking)

FILE_PATH="$1"

if [[ "$FILE_PATH" == *.php ]]; then
  if ! php -l "$FILE_PATH" 2>&1 | grep -q 'Parse error'; then
    echo '✅ PHP syntax valid'
  else
    echo '❌ PHP Syntax Error detected'
    exit 1
  fi
fi
