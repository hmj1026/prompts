#!/bin/bash
# Validate PHP syntax for .php files (Write operations)

FILE_PATH="$1"

if [[ "$FILE_PATH" == *.php ]]; then
  php -l "$FILE_PATH" 2>&1 || true
fi
