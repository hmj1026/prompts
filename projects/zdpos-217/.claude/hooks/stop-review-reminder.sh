#!/usr/bin/env bash
# stop-review-reminder.sh — Stop hook
# Scans all configured sentinels (see _lib/payload.sh SENTINEL_NAMES); if any
# exists, the matching review agent has not run this turn — print a reminder.
# Each sentinel is cleared by clear-sentinel.sh.
set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PROFILE="$(get_hook_profile)"

# minimal profile suppresses reminders to reduce noise
[[ "$PROFILE" == "minimal" ]] && exit 0

SESS="$ROOT/.claude/artifacts/sessions"
FOUND=0

# NOTE: writes outer FOUND — must NOT be called inside a subshell
check_one() {
    local name="$1"
    local agent="$2"
    local file="$SESS/$name"
    [[ -f "$file" ]] || return 0

    local count
    count="$(wc -l < "$file" 2>/dev/null | tr -d ' ')"
    count="${count:-0}"

    local file_list
    file_list="$(head -5 "$file" 2>/dev/null | awk 'NF>=3 {print "    · " $3}')"
    local extra=""
    [[ "$count" -gt 5 ]] && extra="    ... 還有 $((count - 5)) 個檔案"

    # 寫到 stderr：Stop hook exit 2 時 Claude Code 會把 stderr 餵回 Claude 當下一輪 input，
    # 觸發 code-reviewer 自動跑；user 在 terminal 也看得到（stderr 預設顯示）。
    echo >&2 ""
    echo >&2 "-----------------------------------------------------------"
    echo >&2 "⚠  PENDING: $agent ($count 個檔案待審)"
    echo >&2 "   觸發檔案："
    echo >&2 "$file_list"
    [[ -n "$extra" ]] && echo >&2 "$extra"
    echo >&2 ""
    echo >&2 "   正常流程：請 Claude 執行 $agent"
    echo >&2 "   手動清除：bash .claude/hooks/clear-sentinel.sh $name manual"
    echo >&2 "-----------------------------------------------------------"
    FOUND=1
}

for i in "${!SENTINEL_NAMES[@]}"; do
    check_one "${SENTINEL_NAMES[$i]}" "${SENTINEL_AGENTS[$i]}"
done

# exit 2 = block stop + 餵 stderr 給 Claude（Claude Code Stop hook 慣例）。
# 用 exit 1 會被歸類為 non-blocking error，UI 顯示 `No stderr output`，且 stdout
# 內容不會傳給 Claude — reminder 對 Claude 等於 noop。
[[ "$FOUND" -eq 1 ]] && exit 2
exit 0
