#!/usr/bin/env bash
# stop-completion-evidence.sh — Stop hook (advisory only)
#
# 偵測 Claude 在本 session 宣稱「完成 / 已修 / done」但工作目錄沒有對應 test
# 變更時，印一行 stderr 警告。advisory only（exit 0），不阻塞 stop；目的是補
# 「宣稱完成」與「實際完成」之間的落差，**不**取代 reviewer chain rule 或
# verify skill。
#
# 設計：
# - 從 stdin payload 取 transcript_path → 讀最後 N 條 assistant message
# - 偵測 completion claim 關鍵字（中英對照）
# - 對照 active sentinels（如還有任一 sentinel → 已由 stop-review-reminder.sh
#   接手，不重複警告）
# - 對照 `git diff --name-only HEAD`：若有 PHP/JS 業務碼變更但無對應 test
#   檔變更 → 印警告
# - 純 .md / .claude/ / docs/ / openspec/ 變更跳過警告（不需 test）
#
# 觸發：Stop event（settings.json wire 在 reap-stale-sentinels.sh 之後）
# Cost：transcript JSONL tail + 1 次 git diff，<200ms

set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SESS="$ROOT/.claude/artifacts/sessions"
PROFILE="$(get_hook_profile)"

# minimal profile suppress 所有 advisory 提醒
[[ "$PROFILE" == "minimal" ]] && exit 0

PAYLOAD="$(cat 2>/dev/null || true)"

# 從 payload 取 transcript_path（多種 schema fallback）
extract_transcript_path() {
    local payload="$1" out=""
    [ -z "$payload" ] && return 0
    if command -v jq >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | jq -r '
            .transcript_path // .transcript // empty
        ' 2>/dev/null || true)"
    fi
    if [ -z "$out" ] && command -v python3 >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("transcript_path") or d.get("transcript") or "")
except Exception:
    pass
' 2>/dev/null || true)"
    fi
    # Fallback：env var（部分 wrapper 會傳）
    [ -z "$out" ] && out="${CLAUDE_TRANSCRIPT_PATH:-}"
    printf '%s' "$out"
}

TRANSCRIPT="$(extract_transcript_path "$PAYLOAD")"

# 無 transcript path 或檔不存在 → 無法判斷，silent exit 0
[ -z "$TRANSCRIPT" ] && exit 0
[ -f "$TRANSCRIPT" ] || exit 0

# Active sentinels 存在時 stop-review-reminder.sh 已接手 → 不重複警告
for name in "${SENTINEL_NAMES[@]}"; do
    if [ -f "$SESS/$name" ]; then
        exit 0
    fi
done

# 抓 transcript 最後 N 條 assistant message text
# JSONL 格式：每行 {"role":"assistant"|"user","content":[...]} 或 textual streaming
TAIL_LINES=80
recent_assistant_text=""
if command -v jq >/dev/null 2>&1; then
    recent_assistant_text="$(tail -n "$TAIL_LINES" "$TRANSCRIPT" 2>/dev/null | jq -r '
        select(.role == "assistant" or .type == "assistant")
        | (.content // .message.content // [])
        | if type == "array"
          then map(if type == "object" and .type == "text" then .text else (. | tostring) end) | join("\n")
          else (. | tostring)
          end
    ' 2>/dev/null | tr '\n' ' ' | tr -s ' ' || true)"
fi
# fallback：純 grep（jq 缺席或解析失敗）
if [ -z "$recent_assistant_text" ]; then
    recent_assistant_text="$(tail -n "$TAIL_LINES" "$TRANSCRIPT" 2>/dev/null | tr '\n' ' ' || true)"
fi

# 偵測 completion claim 關鍵字（中英對照）
# 用「。」「.」「!」「空白」邊界避免 false positive（如「完成度」「donate」「shipping」）
# 注意：grep -E 用 BRE/ERE，中文逗號需精準匹配
# 'done' 單詞需後接空白/句點/結尾才算（避免 donate / donor 觸發）
claim_pattern='(已完成|已修[復正完]|完成了|完成。|completed[[:space:]\.]|implemented[[:space:]\.]|all done|task done|done[[:space:]\.]|step.*complete|fix(ed)?[[:space:]\.]|shipped[[:space:]\.])'
if ! printf '%s' "$recent_assistant_text" | grep -qiE "$claim_pattern"; then
    # 無 completion claim → silent exit 0
    exit 0
fi

# 對照 git diff（HEAD vs working tree，含 staged + unstaged）
# 失敗時 silent exit 0（不在 git repo / git 不存在）
diff_files="$(cd "$ROOT" && git diff --name-only HEAD 2>/dev/null || true)"
[ -z "$diff_files" ] && exit 0

# 分類：code vs test vs doc-only
# code_files exclude regex 要把 (^|/)tests?/ 包進獨立 group，否則 ^ 與 / 會跟前面
# 的 Test\.php$ / \.test\.X$ 平行 alternation，導致根目錄 *Test.php 穿透 exclude。
code_files="$(printf '%s\n' "$diff_files" | grep -E '\.(php|js|ts|jsx|tsx)$' | grep -vE '(Test\.php$|\.test\.(js|ts|jsx|tsx)$|(^|/)tests?/|/__tests__/)' || true)"
test_files="$(printf '%s\n' "$diff_files" | grep -E '(Test\.php$|\.test\.(js|ts|jsx|tsx)$|(^|/)tests?/|/__tests__/)' || true)"

# 無 code 變更（純 doc / .claude/ / openspec/）→ 不需 test 證據，silent exit 0
[ -z "$code_files" ] && exit 0

# 有 code 變更但有 test 變更 → 證據成立，silent exit 0
[ -n "$test_files" ] && exit 0

# 有 code 變更 + completion claim + 零 test 變更 → 警告
# 用 `grep -c .` 計非空行數，避免 wc -l 在末尾多空行時溢出
code_count="$(printf '%s' "$code_files" | grep -c . 2>/dev/null || echo 0)"
sample="$(printf '%s\n' "$code_files" | head -3 | sed 's/^/    · /')"
extra=""
[ "$code_count" -gt 3 ] && extra="    ... 還有 $((code_count - 3)) 個檔案"

echo >&2 ""
echo >&2 "-----------------------------------------------------------"
echo >&2 "⚠  COMPLETION CLAIM 但無對應 test 變更"
echo >&2 "   偵測到 assistant 宣稱完成，但 git diff 顯示 $code_count 個 code 檔案變更而無 test："
echo >&2 "$sample"
[ -n "$extra" ] && echo >&2 "$extra"
echo >&2 ""
echo >&2 "   如果是 refactor / dead code removal / doc-only path → 此為預期，請忽略"
echo >&2 "   否則建議：補 tdd-guide RED test 或執行 /verify"
echo >&2 "-----------------------------------------------------------"

# Advisory only — 不阻塞 stop
exit 0
