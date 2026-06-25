#!/usr/bin/env bash
# reap-stale-sentinels.sh — sentinel age inspector / purger (zdpos_dev SSOT).
#
# 雙模式：
#   default (Stop hook):     掃描，>=THRESHOLD_HOURS 過期警告，**不刪**
#   --purge (SessionStart):  過期 sentinel 直接刪除（保守閾值，預設 24h；
#                            SessionStart 通常傳 14 天 = 336h 避免誤刪 in-progress review）
#
# 設計：stat / age 邏輯 SSOT；Stop hook 行為不變；SessionStart 對長期殘骸動手，
# 避免 review agent crash 後殘留 sentinel 持續擋 git push（pre-bash-guard.sh）。
#
# 觸發時機：Stop（每次 session 結束）+ SessionStart（每次 session 開始，--purge）。
# Cost：純檔案 stat，<50ms。

set -o pipefail

PURGE=0
THRESHOLD_HOURS=24

while [ "$#" -gt 0 ]; do
    case "$1" in
        --purge)
            PURGE=1
            shift
            ;;
        --threshold-hours)
            # 防呆：缺值或非正整數時保留 default（24h）而非 silent purge=0
            # caller 漏帶 value 時，避免「threshold=0 → 所有 sentinel 立刻被刪」。
            if [ -z "${2:-}" ] || ! printf '%s' "$2" | grep -qE '^[0-9]+$'; then
                echo "[reap-sentinels] --threshold-hours requires a positive integer; falling back to ${THRESHOLD_HOURS}h" >&2
                shift
            else
                THRESHOLD_HOURS="$2"
                shift 2
            fi
            ;;
        *)
            echo "[reap-sentinels] unknown arg: $1 — ignoring" >&2
            shift
            ;;
    esac
done

. "$(dirname "$0")/_lib/payload.sh"

repo_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$repo_root" || exit 0

now="$(date +%s)"
threshold=$((THRESHOLD_HOURS * 3600))
purged=0

for name in "${SENTINEL_NAMES[@]}"; do
    sentinel="$repo_root/.claude/artifacts/sessions/$name"
    [ -f "$sentinel" ] || continue
    # stat 跨平台：Linux GNU `stat -c %Y` vs macOS BSD `stat -f %m`
    if [ "$(uname)" = "Darwin" ]; then
        mtime="$(stat -f %m "$sentinel" 2>/dev/null || echo 0)"
    else
        mtime="$(stat -c %Y "$sentinel" 2>/dev/null || echo 0)"
    fi
    age=$((now - mtime))
    if [ "$age" -gt "$threshold" ]; then
        hours=$((age / 3600))
        if [ "$PURGE" -eq 1 ]; then
            rm -f "$sentinel"
            echo "[reap-sentinels] PURGED: $name (age ${hours}h, threshold ${THRESHOLD_HOURS}h)" >&2
            purged=$((purged + 1))
        else
            echo "[reap-sentinels] STALE: $name (age ${hours}h, threshold ${THRESHOLD_HOURS}h)" >&2
            echo "[reap-sentinels]   Likely cause: review agent crash or interrupted session." >&2
            echo "[reap-sentinels]   To clear manually: rm -f \"$sentinel\"" >&2
        fi
    fi
done

if [ "$PURGE" -eq 1 ] && [ "$purged" -gt 0 ]; then
    echo "[reap-sentinels] auto-purged $purged stale sentinel(s) at SessionStart (>${THRESHOLD_HOURS}h)" >&2
fi

# Stop / SessionStart 都不應 block；任何情況都 exit 0。
exit 0
