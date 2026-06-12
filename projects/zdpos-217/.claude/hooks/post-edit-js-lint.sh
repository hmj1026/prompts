#!/usr/bin/env bash
# post-edit-js-lint.sh — PostToolUse (Edit/Write/MultiEdit) async hook.
#
# 目的：JS/TS edit 完當下 surface ESLint 警告，不要 commit 時才爆。
# 與 pre-commit-js-validation.sh 互補（後者在 git commit fire；本 hook 在每次 edit fire）。
#
# 設計原則：
#   - async: true（settings.json wiring）— 不卡 edit pipeline；exit code 不被檢視
#   - 不 blocking：永遠 exit 0，僅以 stderr 提示
#   - silent skip：npx / eslint / eslint.config.js 任何一個不存在 → 不報錯，安靜退出
#   - 範圍：只對 js/**/*.{js,ts} 觸發；vendor / non-js silent skip
#   - 路徑判定 SSOT：_lib/js-tier-detect.sh（與 post-edit-remind.sh 共用）
#   - timeout：10s（避免超大 leaf 卡 session；timeout 後 silent skip）

set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"
. "$(dirname "$0")/_lib/js-tier-detect.sh"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Read payload；提不到 file_path 就 silent exit（async hook 不該擾人）
PAYLOAD="$(cat 2>/dev/null || true)"
[ -z "$PAYLOAD" ] && exit 0

FILE_PATH="$(extract_tool_input file_path "$PAYLOAD")"
[ -z "$FILE_PATH" ] && {
    FILE_PATH="$(extract_tool_input filePath "$PAYLOAD")"
}
[ -z "$FILE_PATH" ] && exit 0

REL="${FILE_PATH#$ROOT/}"

# Tier 判定：只對 frontend tier 跑 lint（vendor + non-js silent skip）
detect_js_tier "$REL"
[ "$JS_TIER" = "frontend" ] || exit 0

# 檔案存在性（race condition：edit 完到 hook fire 之間檔可能被搬走）
[ -f "$FILE_PATH" ] || exit 0

# 環境檢查：npx + eslint.config.js 任一缺 → silent skip
command -v npx >/dev/null 2>&1 || exit 0
[ -f "$ROOT/eslint.config.js" ] || exit 0

# 跑 ESLint（timeout 10s）
# --no-eslintrc 不必要：eslint 9 flat config 預設不讀 .eslintrc
# --no-install 避免 npx 偷裝套件
# 2>&1 合併 stderr 進 stdout，方便 grep；最後我們再決定要不要印到 stderr
cd "$ROOT" || exit 0
OUTPUT=""
if command -v timeout >/dev/null 2>&1; then
    OUTPUT="$(timeout 10 npx --no-install eslint "$REL" 2>&1 || true)"
else
    # macOS 沒有 GNU timeout（除非 brew install coreutils）；fallback 直接跑
    OUTPUT="$(npx --no-install eslint "$REL" 2>&1 || true)"
fi

# 判讀：ESLint 有 finding 時 stdout 含 "problem" 或 "error" 行（exit code 非 0 不可靠）
if echo "$OUTPUT" | grep -qE '^\s*[0-9]+\s+problems?\s*\(|✖ [0-9]+\s+problems?'; then
    COUNT="$(echo "$OUTPUT" | grep -oE '[0-9]+ problems?' | head -1)"
    echo "[js-lint] ⚠ ESLint ${COUNT:-issues} in $REL (commit 前請修)" >&2
    # 印頭 5 行 finding 給 user 參考（不印全部，避免 spam）
    echo "$OUTPUT" | grep -E '^\s+[0-9]+:[0-9]+\s+(error|warning)' | head -5 | sed 's/^/  /' >&2
elif echo "$OUTPUT" | grep -q 'Parsing error\|Cannot find module'; then
    # ESLint 自身設定 / parser 異常 — 不擋 user，僅 stderr 提示
    echo "[js-lint] WARN: eslint 無法解析 $REL（parser/config 異常，已 silent skip）" >&2
fi

exit 0
