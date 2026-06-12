#!/usr/bin/env bash
# post-edit-skill-index.sh — PostToolUse Write|Edit hook：
# 偵測 `.claude/skills/*/SKILL.md` 寫入後自動重生 `.claude/skills/INDEX.md`
# 的 AUTO-GENERATED 區段。
#
# Advisory only：失敗 echo + exit 0，不影響原 Edit / Write 操作。
# 設計來源：vexjoy-agent hooks/posttooluse-sync-skill-index.py（zdpos 改為
# bash + python3，與 zdpos 既有 hook 風格一致）。
#
# Wire：settings.json PostToolUse Write|Edit；async（與 post-write-crlf-fix.sh
# 等同列）。設 async 是因為 regenerate 約 <500ms，不應阻擋 model 後續工具呼叫。
#
# 觸發路徑：
#   *.claude/skills/*/SKILL.md（不論 absolute / relative）
# 不觸發：
#   .claude/skills/INDEX.md（避免遞迴 — 但本 script 不寫 SKILL.md 所以也不會）
#   非 .claude/skills 下的檔案

set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

PAYLOAD="$(cat 2>/dev/null || true)"
FILE_PATH="$(extract_tool_input file_path "$PAYLOAD")"
[ -z "$FILE_PATH" ] && exit 0

# 只處理 .claude/skills/*/SKILL.md（含 absolute / relative 兩種寫法）
case "$FILE_PATH" in
    */.claude/skills/*/SKILL.md|.claude/skills/*/SKILL.md)
        ;;
    *)
        exit 0
        ;;
esac

GEN="$ROOT/.claude/scripts/regenerate-skill-index.py"
[ -f "$GEN" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

# 跑 regenerator；advisory；成功訊息給 model，失敗訊息給 stderr
if out="$(CLAUDE_PROJECT_DIR="$ROOT" python3 "$GEN" 2>&1)"; then
    echo "$out"
else
    rc=$?
    echo "[post-edit-skill-index] regenerator exit=$rc:" >&2
    echo "$out" >&2
fi
exit 0
