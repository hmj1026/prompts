#!/bin/bash
# statusline.sh — Claude Code 狀態列（zdpos_dev 專用）
# 版面：[branch] +staged ~modified | docker | profile | <全域豐富版輸出>
# Claude Code 會把此腳本的 stdout 第一行當作 statusline 內容
set -o pipefail

. "$(dirname "$0")/hooks/_lib/payload.sh"

input=$(cat)

# 1. 取得全域豐富狀態列輸出（傳入相同 JSON）
#    全域腳本含 model/tokens/effort/5h/7d rate limit 等專案本地沒有的資訊
#    del(.cwd)：移除 cwd 讓全域腳本跳過 git 區段，避免與本機 prefix 的 branch 資訊重複
base_line=""
if [ -x "$HOME/.claude/statusline.sh" ]; then
    if command -v jq >/dev/null 2>&1; then
        base_line=$(printf "%s" "$input" | jq -c 'del(.cwd)' 2>/dev/null | bash "$HOME/.claude/statusline.sh" 2>/dev/null)
    else
        base_line=$(printf "%s" "$input" | bash "$HOME/.claude/statusline.sh" 2>/dev/null)
    fi
fi

# 2. 專案特有資訊
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PROFILE="${ZDPOS_HOOK_PROFILE:-standard}"

BRANCH="$(git -C "$ROOT" branch --show-current 2>/dev/null)"
[[ -z "$BRANCH" ]] && BRANCH="(detached)"

STAGED="$(git -C "$ROOT" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')"
MODIFIED="$(git -C "$ROOT" diff --name-only 2>/dev/null | wc -l | tr -d ' ')"

DOCKER="docker?"
if command -v docker >/dev/null 2>&1; then
    PHP_OK=0; MYSQL_OK=0
    NAMES="$(docker ps --format '{{.Names}}' 2>/dev/null)"
    echo "$NAMES" | grep -q '^pos_php$' && PHP_OK=1
    echo "$NAMES" | grep -q '^pos_mysql$' && MYSQL_OK=1
    if [[ $PHP_OK -eq 1 && $MYSQL_OK -eq 1 ]]; then
        DOCKER="docker:ok"
    elif [[ $PHP_OK -eq 0 && $MYSQL_OK -eq 0 ]]; then
        DOCKER="docker:down"
    else
        DOCKER="docker:partial"
    fi
fi

# Pending review sentinels — show which reviewer types are outstanding (code|db|sec|fe|doc|mig)
# SENTINEL_SHORT_NAMES 已從 _lib/payload.sh source 進來（與 SENTINEL_NAMES 索引 1:1 對齊）
SENTINEL_BADGE=""
SESS="$ROOT/.claude/artifacts/sessions"
if [[ -d "$SESS" ]]; then
    PENDING_LABELS=()
    if [[ ${#SENTINEL_SHORT_NAMES[@]} -ne ${#SENTINEL_NAMES[@]} ]]; then
        SENTINEL_BADGE=" | ⚠ sentinel-sync-error"
    else
        for i in "${!SENTINEL_NAMES[@]}"; do
            [[ -f "$SESS/${SENTINEL_NAMES[$i]}" ]] && PENDING_LABELS+=("${SENTINEL_SHORT_NAMES[$i]}")
        done
        if [[ ${#PENDING_LABELS[@]} -gt 0 ]]; then
            LABEL_STR=$(IFS='|'; echo "${PENDING_LABELS[*]}")
            SENTINEL_BADGE=" | ⚠ ${LABEL_STR}"
        fi
    fi
fi

# 3. 組合輸出：專案資訊在第一行，全域豐富資訊在第二行（避免單行過長截斷）
prefix="[$BRANCH] +$STAGED ~$MODIFIED | $DOCKER | profile=$PROFILE${SENTINEL_BADGE}"
if [ -n "$base_line" ]; then
    printf "%s\n%s" "$prefix" "$base_line"
else
    printf "%s" "$prefix"
fi
