#!/bin/bash
# Check Docker PHP container (pos_php) status

GIT_CMD="${1:-$command}"

if echo "$GIT_CMD" | grep -qE '(docker|mysql)'; then
  if ! docker ps | grep -q 'pos_php'; then
    echo '⚠️  WARNING: Docker PHP 容器 (pos_php) 未運行'
  fi
fi || true
