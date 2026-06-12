#!/usr/bin/env bash
# post-edit-php-syntax.sh — PostToolUse (Edit/Write/MultiEdit) async hook.
#
# 目的：PHP edit 完當下 surface parse error，不要 commit / PHPUnit 跑完才爆。
# 與 post-edit-js-lint.sh 互補（後者 ESLint；本 hook php -l）。
#
# 設計原則：
#   - async: true（settings.json wiring）— 不卡 edit pipeline
#   - 不 blocking：永遠 exit 0，僅以 stderr 提示
#   - silent skip：php 不在 PATH / 檔案不存在 → 不報錯，安靜退出
#   - 範圍：只對 *.php 觸發；非 .php silent skip
#   - host php 即可（catch 通用 parse error）；PHP 5.6 vs 7+ 語法漂移
#     由 code-reviewer + PHPUnit 抓，本 hook 只防低級 syntax error
#   - timeout：5s（避免大型 view 卡 session）
set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

PAYLOAD="$(cat 2>/dev/null || true)"
[ -z "$PAYLOAD" ] && exit 0

FILE_PATH="$(extract_tool_input file_path "$PAYLOAD")"
[ -z "$FILE_PATH" ] && {
    FILE_PATH="$(extract_tool_input filePath "$PAYLOAD")"
}
[ -z "$FILE_PATH" ] && exit 0

REL="${FILE_PATH#$ROOT/}"
BASENAME="${REL##*/}"

# 只對 *.php 觸發；其他副檔名 silent skip
case "$BASENAME" in
    *.php) ;;
    *) exit 0 ;;
esac

# 跳過自身 artifacts（avoid loops on review reports etc.）
case "$REL" in
    .claude/artifacts/*) exit 0 ;;
esac

# 檔案存在性（race condition guard）
[ -f "$FILE_PATH" ] || exit 0

# 環境檢查：host php 不在 PATH 就 silent skip
command -v php >/dev/null 2>&1 || exit 0

# 跑 php -l（timeout 5s）
# php -l exit code 是 authoritative 判定：0=clean, 非 0=parse error。
# 不靠 grep "No syntax errors detected" — host PHP 若帶 deprecation notice 會干擾字串比對。
if command -v timeout >/dev/null 2>&1; then
    OUTPUT="$(timeout 5 php -l "$FILE_PATH" 2>&1)"
    RC=$?
else
    OUTPUT="$(php -l "$FILE_PATH" 2>&1)"
    RC=$?
fi

# RC=0 → clean，silent pass
# RC=124 → timeout（非 parse error，不通報）
# 其他非 0 → 真實 parse error
[ "$RC" -eq 0 ] && exit 0
[ "$RC" -eq 124 ] && exit 0

FIRST_LINE="$(echo "$OUTPUT" | grep -E 'Parse error|syntax error|Fatal error' | head -1)"
[ -z "$FIRST_LINE" ] && FIRST_LINE="(php -l exit=$RC; 完整輸出未含標準 error 字串)"
echo "[php-syntax] ⚠ Parse error in $REL" >&2
echo "  $FIRST_LINE" >&2
echo "  (commit 前請修；本 hook 為 async 提示，不擋 edit)" >&2

exit 0
