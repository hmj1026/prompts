#!/bin/bash
# Validate Yii Controller file structure

FILE_PATH="$1"

if [[ "$FILE_PATH" == *"Controller.php" ]]; then
  if ! grep -qE 'extends .+Controller' "$FILE_PATH"; then
    echo '⚠️  WARNING: Controller file should extend Controller class'
  fi
fi || true
