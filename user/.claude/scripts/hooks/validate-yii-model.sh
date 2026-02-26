#!/bin/bash
# Validate Yii Model file structure

FILE_PATH="$1"

if [[ "$FILE_PATH" == *"Model.php" ]]; then
  if ! grep -q 'extends CActiveRecord' "$FILE_PATH"; then
    echo '⚠️  WARNING: Model file should extend CActiveRecord'
  fi
  if ! grep -q 'public static function model'; then
    echo '⚠️  WARNING: Model missing public static function model()'
  fi
fi || true
