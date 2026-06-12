#!/usr/bin/env bash
# payload.sh — shared helpers for Claude Code hooks. SSOT for sentinel ↔ agent ↔
# short-label triple. Agent names use dhpk: prefix (dhpk plugin v0.4.0+). The 6th
# slot (migration-reviewer) is a zdpos-local extension wired via this hook —
# dhpk's userConfig.review_agents default is 5 slots; v0.5.x may add slot 6 to the
# plugin schema, at which point this override becomes redundant.
# Source-only — do not execute directly.
# Sourced by pre-bash-guard.sh / pre-edit-guard.sh / post-edit-remind.sh /
# stop-review-reminder.sh / statusline.sh. Constants-only export + one
# extractor — safe to source from any hook (no side effects).

# 從 PreToolUse/PostToolUse JSON payload 取出 tool_input.<field>。
# 優先 jq；缺 jq 時改用 python3，確保無 jq 環境下 hook 仍可運作。
# Usage: value="$(extract_tool_input <field> "$payload")"
extract_tool_input() {
    local field="$1" payload="$2" out=""
    [ -z "$payload" ] && return 0
    # 先試 jq；失敗（含被 mock 成 exit 127）時自動掉到 python3 fallback。
    # 結尾的 `|| true` 必須保留：sourcing 端可能使用 set -euo pipefail，
    # 否則 jq/python3 任何非零會直接 abort 整個 hook。
    if command -v jq >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | jq -r ".tool_input.${field} // empty" 2>/dev/null || true)"
    fi
    if [ -z "$out" ] && command -v python3 >/dev/null 2>&1; then
        # env-prefix 必須掛在 python3 上（非 printf），否則 FIELD 不會傳進 python3 process。
        out="$(printf '%s' "$payload" | FIELD="$field" python3 -c '
import sys, os, json
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get(os.environ.get("FIELD", ""), ""))
except Exception:
    pass
' 2>/dev/null || true)"
    fi
    printf '%s' "$out"
    return 0
}

# Review sentinel SSOT — name + clearing agent + statusline short label。
# 對應 execution-policy.md「Mandatory post-steps」表格順序：
#   code(0) → db(1) → sec(2) → frontend(3) → doc(4) → migration(5)
# 執行順序（chain rule）：db → migration → security → frontend → code → doc
# （陣列順序 ≠ 執行順序；slot 索引只用於 NEEDS array，chain order 由 execution-policy.md 規範）
# 新增 reviewer 時，同步擴充三個陣列即可，所有 hook / statusline 自動跟進。
SENTINEL_NAMES=(
    ".pending-review"
    ".pending-db-review"
    ".pending-security-review"
    ".pending-frontend-review"
    ".pending-doc-review"
    ".pending-migration-review"
)
SENTINEL_AGENTS=(
    "dhpk:code-reviewer"
    "dhpk:database-reviewer"
    "dhpk:security-reviewer"
    "dhpk:frontend-reviewer"
    "dhpk:doc-reviewer"
    "dhpk:migration-reviewer"
)
# statusline.sh 顯示用 short label（保持與 SENTINEL_NAMES 索引 1:1 對齊）
SENTINEL_SHORT_NAMES=(
    "code"  # .pending-review
    "db"    # .pending-db-review
    "sec"   # .pending-security-review
    "fe"    # .pending-frontend-review
    "doc"   # .pending-doc-review
    "mig"   # .pending-migration-review
)

# Runtime guard: 三陣列長度必須一致；不一致代表 SSOT 被改錯 — sourcing 端 abort 才能避免
# silent sentinel drop（header comment 警告的歷史 trap）。
if [ "${#SENTINEL_NAMES[@]}" -ne "${#SENTINEL_AGENTS[@]}" ] \
   || [ "${#SENTINEL_NAMES[@]}" -ne "${#SENTINEL_SHORT_NAMES[@]}" ]; then
    echo "[payload.sh] sentinel array drift: NAMES=${#SENTINEL_NAMES[@]} AGENTS=${#SENTINEL_AGENTS[@]} SHORT=${#SENTINEL_SHORT_NAMES[@]}" >&2
    exit 1
fi

# Hook profile resolver — minimal / standard / strict。
# 優先序：env $ZDPOS_HOOK_PROFILE > 檔案 .claude/.harness-profile > "standard"。
# 檔案讓 profile 可探索（不必動 shell rc）；env 仍保留給 CI 一次性 override。
# Usage: profile="$(get_hook_profile)"
get_hook_profile() {
    if [ -n "${ZDPOS_HOOK_PROFILE:-}" ]; then
        echo "$ZDPOS_HOOK_PROFILE"
        return 0
    fi
    local root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
    local file="$root/.claude/.harness-profile"
    if [ -f "$file" ]; then
        local val
        val="$(head -1 "$file" 2>/dev/null | tr -d '[:space:]')"
        if [ -n "$val" ]; then
            echo "$val"
            return 0
        fi
    fi
    echo "standard"
}
