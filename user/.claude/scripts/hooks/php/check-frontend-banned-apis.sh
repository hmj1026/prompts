#!/bin/bash
# PostToolUse hook: 檢查新功能程式碼是否直接使用原生 HTTP API
# 意圖：新寫的程式碼應使用專案既有 AJAX 封裝，不重造輪子
# 適用：.js 檔案 + views/ 下的 .php 檔案（含 inline JS）
# 排除：核心 JS（封裝定義處）、第三方目錄

FILE_PATH="$1"
BASENAME=$(basename "$FILE_PATH")

# 僅檢查 .js 或 views/ 下的 .php
if [[ "$FILE_PATH" != *.js && ! ("$FILE_PATH" == *"views/"*.php) ]]; then
  exit 0
fi

# 排除核心 JS 檔案（這些是封裝的實作處，本身需要使用 $.ajax）
if [[ "$BASENAME" == "zpos.js" || "$BASENAME" == "mpos.js" || "$BASENAME" == "pos_core.js" || "$BASENAME" == "main.js" ]]; then
  exit 0
fi

# 排除第三方目錄
if [[ "$FILE_PATH" == *"vendors/"* || "$FILE_PATH" == *"extensions/"* || "$FILE_PATH" == *"node_modules/"* || "$FILE_PATH" == *"vendor/"* ]]; then
  exit 0
fi

# 檢查原生 HTTP API
FOUND=0
if grep -E '\$\.ajax|\$\.post|\$\.get|\$\.getJSON|axios\.' "$FILE_PATH" > /dev/null 2>&1; then
  FOUND=1
fi
if grep -P '(?<![.a-zA-Z])fetch\s*\(' "$FILE_PATH" > /dev/null 2>&1; then
  FOUND=1
fi

if [[ "$FOUND" -eq 1 ]]; then
  echo "WARNING: 偵測到直接使用原生 HTTP API。請優先使用專案既有封裝："
  echo "  - POS.list.ajaxPromise(name, data, fn)  [Promise]"
  echo "  - POS.list.ajaxQuery(name, data, fn)     [Callback]"
  echo "  - POS.postData(name, data, fn)           [Callback]"
fi
