#!/usr/bin/env bash
# post-edit-composer-guard.sh — PostToolUse (Edit/Write/MultiEdit) async hook.
#
# 目的：composer.json / package.json 被 edit 時，stderr 提醒 lock 檔需要 sync。
# 不存 sentinel（這不是 review，是 operational 提醒），不擋 edit。
#
# 為何不掛 review sentinel：
#   review sentinel SSOT (_lib/payload.sh) 對應 reviewer agent；composer / npm
#   lock sync 是 manual ops，不該污染 reviewer 陣列。Stop hook 也不重複提醒：
#   edit 當下就 stderr，user 即時可見即可。
#
# 偵測對象：repo root 的 composer.json / package.json（套件 manifest）。
# 不報 lock 檔本身（那是 sync 結果，不需要提醒）。
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

case "$REL" in
    composer.json)
        echo "[composer-guard] ⚠ composer.json 已修改 — commit 前請執行：" >&2
        echo "    docker exec -i -w /var/www/www.posdev/zdpos-217 pos_php composer update --lock" >&2
        echo "  （或 composer install --no-dev 確認 lock 已同步）" >&2
        ;;
    package.json)
        echo "[composer-guard] ⚠ package.json 已修改 — commit 前請執行：" >&2
        echo "    npm install" >&2
        echo "  （確保 package-lock.json 同步；CI 會以 lock 為準）" >&2
        ;;
esac

exit 0
