#!/usr/bin/env bash
# clear-sentinel.sh — parametric sentinel cleaner.
# Usage: clear-sentinel.sh <sentinel-name> [agent-label]
# Called by a review-agent's Closing hook to dismiss the matching stop-review-reminder entry.
#
# 2026-05-16: fail-fast on unknown sentinel name. Two retrospective entries (Stage D
# verification + verify-zpos-modular-refactor) both撞 silent-pass: caller passed wrong
# NAME (e.g. "review" or "code-reviewer"), got "sentinel already clean" → false
# success → commit blocked again later when real sentinel still present.
set -o pipefail

NAME="${1:?usage: clear-sentinel.sh <sentinel-name|--all> [agent-label]}"
LABEL="${2:-agent}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Known sentinel whitelist — keep aligned with _lib/payload.sh SENTINEL_NAMES.
readonly KNOWN_SENTINELS=(
    ".pending-review"
    ".pending-db-review"
    ".pending-security-review"
    ".pending-frontend-review"
    ".pending-doc-review"
    ".pending-migration-review"
)

# --all: clear every sentinel at once (use when review is intentionally skipped)
if [[ "$NAME" == "--all" ]]; then
    cleared=0
    for s in "${KNOWN_SENTINELS[@]}"; do
        f="$ROOT/.claude/artifacts/sessions/$s"
        if [[ -f "$f" ]]; then
            rm -f "$f"
            echo "[$LABEL] sentinel cleared ($s)"
            (( cleared++ )) || true
        fi
    done
    [[ "$cleared" -eq 0 ]] && echo "[$LABEL] no sentinels to clear"
    exit 0
fi

is_known=false
for s in "${KNOWN_SENTINELS[@]}"; do
    if [[ "$NAME" == "$s" ]]; then
        is_known=true
        break
    fi
done

if [[ "$is_known" != true ]]; then
    echo "[$LABEL] ERROR: unknown sentinel name '$NAME'" >&2
    echo "[$LABEL] known sentinels: ${KNOWN_SENTINELS[*]}" >&2
    echo "[$LABEL] hint: agent's Closing hook should pass the exact sentinel file basename" >&2
    exit 2
fi

SENTINEL="$ROOT/.claude/artifacts/sessions/$NAME"

if [[ -f "$SENTINEL" ]]; then
    rm -f "$SENTINEL"
    echo "[$LABEL] sentinel cleared ($NAME)"
else
    echo "[$LABEL] sentinel already clean ($NAME)"
fi

exit 0
