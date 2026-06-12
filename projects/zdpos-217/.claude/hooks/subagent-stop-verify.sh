#!/usr/bin/env bash
# subagent-stop-verify.sh — SubagentStop hook (advisory only)
#
# 補 reviewer chain rule 漏洞：當 reviewer agent 結束但對應 sentinel 仍存在
# 時，warning（agent 可能漏呼 clear-sentinel.sh）；exit code 非 0 時記錄到
# .claude/artifacts/agent-failures.log 供下次 SessionStart / 人工檢視。
#
# 設計：
# - Source _lib/payload.sh SSOT（SENTINEL_NAMES / SENTINEL_AGENTS 共 6 槽）
# - 從 stdin JSON 嘗試取 subagent name；失敗 → silent exit 0（避免假警報）
# - 永遠 exit 0：advisory only，**不**影響 reviewer chain rule 下一棒。
#
# 觸發：SubagentStop event（settings.json wire 一次即生效）
# Cost：純檔案 stat + 一次 jq/python3 parse，<50ms

set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SESS="$ROOT/.claude/artifacts/sessions"
LOG="$ROOT/.claude/artifacts/agent-failures.log"

# 讀 stdin payload（JSON envelope by Claude Code SubagentStop event）
PAYLOAD="$(cat 2>/dev/null || true)"

# 嘗試多個 field name 取 subagent type（Claude Code envelope schema 隨版本演進，
# 兼容 subagent_type / subagent / tool_input.subagent_type 三種位置）
extract_subagent_name() {
    local payload="$1" out=""
    [ -z "$payload" ] && return 0
    if command -v jq >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | jq -r '
            .subagent_type // .subagent // .tool_input.subagent_type // empty
        ' 2>/dev/null || true)"
    fi
    if [ -z "$out" ] && command -v python3 >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(
        d.get("subagent_type")
        or d.get("subagent")
        or d.get("tool_input", {}).get("subagent_type")
        or ""
    )
except Exception:
    pass
' 2>/dev/null || true)"
    fi
    printf '%s' "$out"
}

# 嘗試取 exit status / status field
# Maintenance note: 若 Claude Code 日後 SubagentStop payload 新增其他失敗欄位
# 名稱（例如 `failed`, `error`, `outcome.status`），請同步擴充下方 candidate 清單。
# 三個 candidate 任一缺失時退回 "0"（視為成功）— 是有意保守設計，避免假警報。
extract_exit_status() {
    local payload="$1" out=""
    [ -z "$payload" ] && { printf '0'; return 0; }
    if command -v jq >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | jq -r '
            .exit_status // .status // .exit_code // empty
        ' 2>/dev/null || true)"
    fi
    if [ -z "$out" ] && command -v python3 >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    v = d.get("exit_status")
    if v is None:
        v = d.get("status")
    if v is None:
        v = d.get("exit_code")
    print("" if v is None else v)
except Exception:
    pass
' 2>/dev/null || true)"
    fi
    # 空值視為成功（payload 沒有 exit_status 是常態）
    [ -z "$out" ] && out="0"
    printf '%s' "$out"
}

SUBAGENT="$(extract_subagent_name "$PAYLOAD")"
EXIT_STATUS="$(extract_exit_status "$PAYLOAD")"

# 反查 SENTINEL_AGENTS array：找 subagent name 對應的 slot index → 推導 sentinel name
SLOT=-1
if [ -n "$SUBAGENT" ]; then
    for i in "${!SENTINEL_AGENTS[@]}"; do
        if [ "${SENTINEL_AGENTS[$i]}" = "$SUBAGENT" ]; then
            SLOT="$i"
            break
        fi
    done
fi

# Slot 找不到 → 非 reviewer agent（或 schema 不含 subagent name）→ silent exit 0
if [ "$SLOT" -lt 0 ]; then
    exit 0
fi

SENTINEL_NAME="${SENTINEL_NAMES[$SLOT]}"
SENTINEL_FILE="$SESS/$SENTINEL_NAME"
TIMESTAMP="$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)"

# 確保 log 目錄存在
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

# 兩種異常情境分類處理
if [ "$EXIT_STATUS" != "0" ]; then
    # 情境 A：subagent 失敗
    SENTINEL_STATE="none"
    [ -f "$SENTINEL_FILE" ] && SENTINEL_STATE="$SENTINEL_NAME"
    echo "$TIMESTAMP $SUBAGENT exit=$EXIT_STATUS sentinel=$SENTINEL_STATE" >> "$LOG" || true
    echo >&2 ""
    echo >&2 "-----------------------------------------------------------"
    echo >&2 "[WARN] SUBAGENT FAILURE: $SUBAGENT (exit=$EXIT_STATUS)"
    if [ -f "$SENTINEL_FILE" ]; then
        echo >&2 "   對應 sentinel 仍存在：$SENTINEL_NAME"
        echo >&2 "   reviewer chain rule 後續 agent 可能不會被觸發"
    fi
    echo >&2 "   已記錄到：.claude/artifacts/agent-failures.log"
    echo >&2 "-----------------------------------------------------------"
elif [ -f "$SENTINEL_FILE" ]; then
    # 情境 B：subagent 成功但 sentinel 仍在 → 漏呼 clear-sentinel.sh
    echo "$TIMESTAMP $SUBAGENT exit=0 sentinel=$SENTINEL_NAME (uncleared)" >> "$LOG" || true
    echo >&2 ""
    echo >&2 "-----------------------------------------------------------"
    echo >&2 "[WARN] SENTINEL UNCLEARED: $SUBAGENT 完成但 $SENTINEL_NAME 未清除"
    echo >&2 "   可能原因：agent Closing hook 未呼叫 clear-sentinel.sh"
    echo >&2 "   手動清除：bash .claude/hooks/clear-sentinel.sh $SENTINEL_NAME manual"
    echo >&2 "   已記錄到：.claude/artifacts/agent-failures.log"
    echo >&2 "-----------------------------------------------------------"
fi

# Advisory only — 永遠不阻塞 chain rule 下一棒
exit 0
