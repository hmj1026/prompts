#!/usr/bin/env bash
# post-write-crlf-fix.sh — PostToolUse (Write/Edit/MultiEdit) hook
# Auto-fix CRLF line endings in .sh files when written from WSL host.
# Reason: bash refuses CRLF scripts ($'\r': command not found).
# Cross-platform: delegates to _lib/portable-sed.sh (GNU vs BSD sed).
set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"
. "$(dirname "$0")/_lib/portable-sed.sh"

# Read tool input from stdin (Claude Code passes JSON payload)
PAYLOAD="$(cat 2>/dev/null || true)"

# 1) 標準 jq path：file_path → path → filePath（後者為部分 tool 變體鍵名）。
# 2) 若兩鍵皆失敗或 jq 缺席 → fallback 用 extract_tool_input（內含 python3 兜底）。
# 3) 仍空 → stderr 紀錄但 exit 0（async hook exit code 不被檢視；用 stderr 暴露異常即可）。
FILE=""
if [ -n "$PAYLOAD" ] && command -v jq >/dev/null 2>&1; then
  FILE="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // .tool_input.path // .tool_input.filePath // empty' 2>/dev/null)"
fi
if [ -z "$FILE" ] && [ -n "$PAYLOAD" ]; then
  FILE="$(extract_tool_input file_path "$PAYLOAD")"
  [ -z "$FILE" ] && FILE="$(extract_tool_input filePath "$PAYLOAD")"
fi

if [ -z "$FILE" ]; then
  # 沒 payload 時 silent exit；有 payload 但提不到 file_path 才屬於異常。
  # async hook 的 exit code 不會被檢視，但 stderr 仍會出現在 log；exit 0 即可（不擋後續 hook）。
  if [ -n "$PAYLOAD" ]; then
    echo "[crlf-fix] WARN: failed to extract file path from payload" >&2
  fi
  exit 0
fi

# Only act on .sh files
case "$FILE" in
  *.sh) ;;
  *) exit 0 ;;
esac

[ -f "$FILE" ] || exit 0

# Skip if no CR present
if ! grep -q $'\r' "$FILE" 2>/dev/null; then
  exit 0
fi

sed_inplace 's/\r$//' "$FILE" || { echo "[crlf-fix] WARN: sed failed for $FILE" >&2; exit 0; }

echo "[crlf-fix] normalized line endings: $FILE"
exit 0
