#!/usr/bin/env bash
# stop-failure-log.sh — StopFailure hook (advisory only)
#
# Session 異常終止時記錄 active sentinels；供 next session SessionStart 或人工
# 檢視，了解上一個 session「卡在哪一棒沒清完」。
#
# 設計：
# - 列出 .claude/artifacts/sessions/.pending-* 全部 sentinel 檔
# - Append 一行到 .claude/artifacts/stop-failures.log（CSV-like, 易解析）
# - 同步輸出一行 stderr 摘要，使用者在 terminal 可立即看到「上次 session 崩潰
#   時還卡哪幾棒」，不需主動去查 log。語意比 SubagentStop 更嚴重故設計成可見。
# - 永遠 exit 0：advisory only；不會引入新的 stop 阻塞。
#
# 觸發：StopFailure event（settings.json wire 一次即生效）
# Cost：純檔案 stat，<20ms

set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SESS="$ROOT/.claude/artifacts/sessions"
LOG="$ROOT/.claude/artifacts/stop-failures.log"
TIMESTAMP="$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)"

# 收集當前 active sentinels（用 SENTINEL_NAMES SSOT，避免漏掃 / 誤掃）
active=()
for name in "${SENTINEL_NAMES[@]}"; do
    [ -f "$SESS/$name" ] && active+=("$name")
done

# 組 CSV（空時印 "none" 而非空字串，方便 grep）
if [ "${#active[@]}" -eq 0 ]; then
    csv="none"
else
    csv="$(IFS=,; printf '%s' "${active[*]}")"
fi

# 嘗試從 stdin payload 讀補充欄位（reason / message / hook_event_name）
PAYLOAD="$(cat 2>/dev/null || true)"
extra=""
if [ -n "$PAYLOAD" ]; then
    if command -v jq >/dev/null 2>&1; then
        extra="$(printf '%s' "$PAYLOAD" | jq -r '
            (.reason // .message // .hook_event_name // "") | tostring
        ' 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//' || true)"
    elif command -v python3 >/dev/null 2>&1; then
        extra="$(printf '%s' "$PAYLOAD" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("reason") or d.get("message") or d.get("hook_event_name") or "")
except Exception:
    pass
' 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//' || true)"
    fi
fi

# 確保 log 目錄存在
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

# Append 一行（格式：timestamp active_sentinels=<csv> [reason=<text>]）
if [ -n "$extra" ]; then
    echo "$TIMESTAMP active_sentinels=$csv reason=$extra" >> "$LOG" || true
else
    echo "$TIMESTAMP active_sentinels=$csv" >> "$LOG" || true
fi

# 給使用者一行 stderr 摘要（StopFailure 比 SubagentStop 嚴重，值得明顯提示）
echo >&2 "[stop-failure-log] session abnormal stop — active_sentinels=$csv (logged to .claude/artifacts/stop-failures.log)"

# Advisory only — 不阻塞
exit 0
