#!/bin/bash
# Output git status summary

echo '📋 Session End Summary'
echo ''
echo '檢查工作目錄狀態...'
cd /mnt/e/projects/zdpos_dev && git status --short | head -20 || true
