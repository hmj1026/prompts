#!/bin/bash
# Display Docker environment status

echo ''
echo '📊 Docker 環境狀態'
docker ps --filter 'name=pos_php' --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null || echo '⚠️  Docker 檢查失敗'
