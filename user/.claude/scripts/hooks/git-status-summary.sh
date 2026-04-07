#!/bin/bash
# Output git status summary

echo '📋 Session End Summary'
echo ''
echo '檢查工作目錄狀態...'
git -C "$PWD" status --short 2>/dev/null | head -20 || true
