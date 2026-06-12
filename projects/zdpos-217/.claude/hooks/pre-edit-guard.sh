#!/usr/bin/env bash
# PreToolUse hook: Guard against editing sensitive files
# Exit code 2 = reject the tool call
#
# Protected paths (always):
# - .env files (secrets)
# - .git/ directory (git internals)
#
# Custom protected paths (optional):
# Set GUARD_EXTRA_PATTERNS to add project-specific patterns (pipe-separated regex)
# Example: GUARD_EXTRA_PATTERNS="src/locales/.*\.json$|generated/.*"
# WARNING: This env var is used as a grep regex. Only set by trusted project admin.

set -euo pipefail

. "$(dirname "$0")/_lib/payload.sh"

stdin_data=$(cat)
file_path="$(extract_tool_input file_path "$stdin_data")"

if [[ -z "$file_path" ]]; then
  exit 0
fi

# Security: Reject paths with shell metacharacters that could enable injection
# Block: ; & | ` $()
# Note: $ alone is NOT blocked as it's valid in some filenames
# Note: Null bytes cannot be reliably detected in bash (variables truncate at \0)
if [[ "$file_path" =~ [\;\&\|\`] ]] || [[ "$file_path" =~ \$\( ]]; then
  echo "[Edit Guard] Rejected suspicious file path: contains shell metacharacters" >&2
  exit 2
fi

# Block sensitive paths (universal, always safe to block)
if echo "$file_path" | grep -Eq '(\.env|\.git/)'; then
  echo "[Edit Guard] Blocked sensitive file: $file_path" >&2
  exit 2
fi

# Block custom paths (project-specific, opt-in via env var)
# 驗證 regex pattern 必須 hard-fail，不能 silent skip — malformed pattern 等同 guard
# 被繞過，安全意圖被默默吞掉。
if [[ -n "${GUARD_EXTRA_PATTERNS:-}" ]]; then
  # grep 正規 exit code：0 命中 / 1 未命中 / 2 regex 語法錯。用空字串測試只允許 0|1。
  # 注意：set -e + grep rc=1 會在 `rc=$?` 之前 abort，必須用 if/else 包覆才能安全捕獲 rc。
  if printf '' | grep -E "$GUARD_EXTRA_PATTERNS" >/dev/null 2>&1; then
    rc=0
  else
    rc=$?
  fi
  if [[ $rc -gt 1 ]]; then
    echo "[Edit Guard] Invalid GUARD_EXTRA_PATTERNS regex (grep rc=$rc); refusing to apply guard" >&2
    exit 2
  fi
  if echo "$file_path" | grep -Eq "$GUARD_EXTRA_PATTERNS"; then
    echo "[Edit Guard] Blocked by custom pattern: $file_path" >&2
    exit 2
  fi
fi

exit 0
