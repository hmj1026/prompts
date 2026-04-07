#!/bin/bash
# compact-reminder.sh
# Stop hook: 提醒用戶在 session 結束前建立 compact 交接備忘
# 若 compact-notes/ 目錄有最新備忘，顯示其路徑；否則提示執行 /compact-save

COMPACT_DIR="./compact-notes"

if [ -d "$COMPACT_DIR" ]; then
  LATEST=$(ls -t "$COMPACT_DIR"/*.json 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    echo "[compact] 最新交接備忘：$LATEST"
  else
    echo "[compact] 提示：compact-notes/ 目錄存在但無備忘檔。若任務未完成，建議執行 /compact-save"
  fi
else
  echo "[compact] 提示：尚無交接備忘。若任務未完成，建議執行 /compact-save 建立交接檔"
fi
