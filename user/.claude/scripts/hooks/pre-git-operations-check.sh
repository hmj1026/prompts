#!/bin/bash
# Pre-git operations safety check

GIT_CMD="${1:-$command}"

if echo "$GIT_CMD" | grep -qE '^git (push|commit|rebase|reset|clean)'; then
  echo '🔔 Git 操作安全檢查'
  echo "指令: $GIT_CMD"
  echo '確認操作無誤再繼續'
fi
