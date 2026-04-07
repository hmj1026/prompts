#!/bin/bash
# Validate PHP syntax for .php files on Edit (blocking)

FILE_PATH="$1"

if [[ "$FILE_PATH" == *.php ]]; then
  output=$(php -l "$FILE_PATH" 2>&1)
  if [ $? -eq 0 ]; then
    echo 'PHP syntax valid'
  else
    echo "PHP Syntax Error detected:"
    echo "$output"
    exit 1
  fi
fi
