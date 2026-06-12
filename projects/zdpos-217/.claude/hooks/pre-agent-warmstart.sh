#!/usr/bin/env bash
# pre-agent-warmstart.sh — PreToolUse Agent hook：注入 parent session context
# 到 subagent prompt（透過 Claude Code 標準 `hookSpecificOutput.additionalContext`
# JSON）。
#
# 注入內容（zdpos-specific，與 `.claude/docs/subagent-prompt-template.md` 對齊）：
#   - 當前分支 + sentinel state（哪些 .pending-* 仍 active）
#   - OpsX active change（若 openspec/changes/ 內有目錄，列最近 1 個 + tasks 進度）
#   - Project layer paths（zdpos DDD 三層 + Yii framework + Docker container）
#   - 6-slot review chain order（避免 subagent 用錯順序）
#
# 設計取捨：
# - 控制 token 預算 ≤ 2000 chars（~500 token）— OpsX active change 用 head -n 限制；
#   sentinel 只列名稱不列內容；layer paths 為固定字串。
# - bash + python3 構造 JSON（避免手動 escape）；失敗時印空 object 確保 Claude
#   Code parser 不 break。
# - matcher = "Agent"（settings.json wire），確保只在 Task/Agent 工具觸發。
#
# Exit code：永遠 0（advisory；失敗 fallback 為 empty JSON）。
# 設計來源：vexjoy-agent hooks/pretool-subagent-warmstart.py（zdpos 簡化版）。

set -o pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
. "$(dirname "$0")/_lib/payload.sh"

PROFILE="$(get_hook_profile)"
# minimal profile 跳過注入（保持 subagent prompt 精簡）
if [[ "$PROFILE" == "minimal" ]]; then
    printf '{}'
    exit 0
fi

PAYLOAD="$(cat 2>/dev/null || true)"

# python3 收集 context + 構造 hookSpecificOutput JSON
# 失敗時 fallback printf '{}'
out="$(
    CLAUDE_PROJECT_DIR="$ROOT" \
    PAYLOAD="$PAYLOAD" \
    SENTINEL_NAMES="${SENTINEL_NAMES[*]}" \
    python3 <<'PY' 2>/dev/null || printf '{}'
import json, os, sys
from pathlib import Path

ROOT = Path(os.environ["CLAUDE_PROJECT_DIR"]).resolve()
sentinels = os.environ.get("SENTINEL_NAMES", "").split()

def read_text_safe(p, max_chars=400):
    try:
        t = p.read_text(encoding="utf-8", errors="replace")
        return t if len(t) <= max_chars else t[: max_chars - 3] + "..."
    except OSError:
        return ""

lines = []

# === Section 1: Active sentinels ===
sess_dir = ROOT / ".claude" / "artifacts" / "sessions"
active = []
if sess_dir.is_dir():
    for s in sentinels:
        if (sess_dir / s).is_file():
            active.append(s)
if active:
    lines.append("Active review sentinels: " + ", ".join(active))
    lines.append(
        "Chain order: db → migration → security → frontend → code → doc "
        "(SSOT: .claude/hooks/_lib/payload.sh)"
    )

# === Section 2: OpsX active change（若有未 archive 的） ===
opsx_changes = ROOT / "openspec" / "changes"
if opsx_changes.is_dir():
    # 列出非 archive 的 change（typically each is a dir）。先 filter is_dir + 非 hidden
    # 再 sort，避免 broken symlink 在 sort key 觸發 OSError 把整個 hook 拖崩。
    candidates = []
    for entry in opsx_changes.iterdir():
        if entry.name.startswith("."):
            continue
        try:
            if entry.is_dir():
                candidates.append(entry)
        except OSError:
            continue
    candidates.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    if candidates:
        active_change = candidates[0]
        lines.append(f"OpsX active change: {active_change.relative_to(ROOT)}")
        # tasks.md 第一段
        tasks_md = active_change / "tasks.md"
        if tasks_md.is_file():
            preview = read_text_safe(tasks_md, max_chars=300)
            # 抓第一個 - [ ] / - [x] 行做摘要
            todo = []
            for ln in preview.splitlines():
                ln_s = ln.strip()
                if ln_s.startswith("- [") and len(todo) < 3:
                    todo.append(ln_s)
            if todo:
                lines.append("Tasks (first 3): " + " | ".join(todo))

# === Section 3: Layer paths + docker（zdpos-specific 固定） ===
lines.append(
    "DDD layers: protected/ (Yii Controller/Model/View) | "
    "domain/ (Service/Repository contracts) | "
    "infrastructure/ (DB / cache / external API)"
)
lines.append(
    "Yii 1.1 framework: ~/projects/yii_framework/ | "
    "Docker: pos_php (PHP 5.6 + Yii) / pos_mysql (MySQL 5.7)"
)
lines.append(
    "PHPUnit cmd: docker exec -i -w /var/www/www.posdev/zdpos-217 pos_php "
    "phpunit -c protected/tests/phpunit.xml [--testsuite unit|integration]"
)

# === Section 4: Tool routing 提醒（cx > gitnexus > Read） ===
lines.append(
    "Tool routing: cx overview/definition/references > gitnexus_impact/context > Read "
    "(see ${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md + .claude/rules/tool-routing.md)"
)

# Cap 2000 chars
body = "\n".join(lines)
if len(body) > 2000:
    body = body[:1997] + "..."

ctx_block = (
    "<parent-session-context>\n"
    "[warmstart] zdpos_dev — parent session state for subagent:\n"
    + body
    + "\n</parent-session-context>"
)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": ctx_block,
    }
}))
PY
)"

# 確保有 output（避免 fallback 失效時 hook 印 nothing 讓 parser 困惑）
if [ -z "$out" ]; then
    printf '{}'
else
    printf '%s' "$out"
fi

exit 0
