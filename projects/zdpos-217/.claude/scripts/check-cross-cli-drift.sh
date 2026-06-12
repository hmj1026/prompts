#!/usr/bin/env bash
# check-cross-cli-drift.sh — 偵測 `.claude/` 是否較 `.codex/` / `.gemini/` 新。
#
# Use case：zdpos 同時維護 Claude / Codex / Gemini 三套 harness（見
# `.claude/manifests/triple-platform.json` 的 `triple` profile），但同步動作
# 由人工 `/multi-ai-sync` 觸發。若 `.claude/skills`、`.claude/commands` 等
# 有新增 / 修改而 `.codex` / `.gemini` 未跟上，model 切換 CLI 時會看到陳舊
# 內容。本 script 在 SessionStart 時做時間戳比對，drift 逾 1 小時即 advisory
# 提醒執行 `/multi-ai-sync`。
#
# 設計取捨：
# - 比對「目錄內任一檔案最新 mtime」而非個別檔案逐一比對 — 1 個 find 呼叫，
#   < 50ms；夠快可以在 SessionStart 同步跑（不 async）。
# - DRIFT_THRESHOLD=3600（1 小時）避免「剛跑完 sync 又被 advisory」的雜訊；
#   也代表「source 改了沒立刻 sync」是 acceptable，跨 1 小時才需提醒。
# - profile 過濾由呼叫端（session-start.sh `if [[ "$PROFILE" != "minimal" ]]`）負責；
#   本 script 不自帶 profile check，可獨立手動執行做 dry-run。
#
# 呼叫端：`.claude/hooks/session-start.sh`（已 wire；無 standalone hook event）。
# Exit code：永遠 0（advisory only）。

set -o pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CLAUDE_DIR="$ROOT/.claude"
DRIFT_THRESHOLD="${ZDPOS_CROSS_CLI_DRIFT_THRESHOLD:-3600}"

[ -d "$CLAUDE_DIR" ] || exit 0

# 取 dir 內 skills / commands / agents / hooks / rules 子目錄裡任一檔案的最新 mtime（epoch 秒）。
# 採用 -printf '%T@\n'（GNU find）。WSL 與 zdpos Docker pos_php 內 find 都是 GNU 版，
# macOS BSD find 不支援 -printf — zdpos 無 macOS 部署需求，可省 fallback。
newest_mtime() {
    local dir="$1"
    [ -d "$dir" ] || { echo 0; return; }
    local subdirs=()
    for sub in skills commands agents hooks rules; do
        [ -d "$dir/$sub" ] && subdirs+=("$dir/$sub")
    done
    [ ${#subdirs[@]} -eq 0 ] && { echo 0; return; }
    find "${subdirs[@]}" \
        -type f \
        \( -name '*.md' -o -name '*.sh' -o -name '*.py' -o -name '*.json' -o -name '*.toml' -o -name '*.js' \) \
        -printf '%T@\n' 2>/dev/null \
        | sort -nr | head -1 | awk '{print int($1)}'
}

claude_t="$(newest_mtime "$CLAUDE_DIR")"
[ -z "$claude_t" ] || [ "$claude_t" = "0" ] && exit 0

drift_targets=()
for target_name in codex gemini; do
    target_dir="$ROOT/.$target_name"
    [ -d "$target_dir" ] || continue
    target_t="$(newest_mtime "$target_dir")"
    { [ -z "$target_t" ] || [ "$target_t" = "0" ]; } && continue
    delta=$((claude_t - target_t))
    if [ "$delta" -gt "$DRIFT_THRESHOLD" ]; then
        hours=$((delta / 3600))
        if [ "$hours" -lt 1 ]; then
            mins=$((delta / 60))
            drift_targets+=(".$target_name(+${mins}m)")
        elif [ "$hours" -lt 48 ]; then
            drift_targets+=(".$target_name(+${hours}h)")
        else
            days=$((hours / 24))
            drift_targets+=(".$target_name(+${days}d)")
        fi
    fi
done

if [ ${#drift_targets[@]} -gt 0 ]; then
    echo "[session-start] cross-cli drift: .claude/ newer than ${drift_targets[*]} — consider \`/multi-ai-sync\`"
fi

exit 0
