#!/bin/bash
# Check for PHP 7+ syntax incompatible with PHP 5.6

FILE_PATH="$1"

if [[ "$FILE_PATH" == *.php ]]; then
  if grep -E '(\?\?|->|: ?(void|int|string|bool|float|array)|function.*\(.*:)' "$FILE_PATH"; then
    echo '⚠️  WARNING: Found potential PHP 7+ syntax incompatible with PHP 5.6'
  fi || true
fi
