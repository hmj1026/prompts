#!/bin/bash
# 偵測 EILogger::slog() 呼叫缺少 __METHOD__
# 規則來源：~/.claude/rules/php/logging-standards.md
# 觸發：PostToolUse Write/Edit (async)

FILE_PATH="$1"

# 僅檢查 PHP 檔案
case "$FILE_PATH" in
    *.php) ;;
    *) exit 0 ;;
esac

# 排除 vendor / extensions / EILogger 自身
if [[ "$FILE_PATH" == */vendors/* ]] || \
   [[ "$FILE_PATH" == */vendor/* ]] || \
   [[ "$FILE_PATH" == */extensions/* ]] || \
   [[ "$FILE_PATH" == */EILogger.php ]] || \
   [[ "$FILE_PATH" == */EI.php ]]; then
    exit 0
fi

[ ! -f "$FILE_PATH" ] && exit 0

# 偵測 slog([ 但不含 __METHOD__ 或 __FUNCTION__
MATCHES=$(grep -Pn 'slog\s*\(\s*\[' "$FILE_PATH" 2>/dev/null | grep -v '__METHOD__\|__FUNCTION__\|__CLASS__')

if [ -n "$MATCHES" ]; then
    echo "WARNING: $FILE_PATH 的 slog() 呼叫缺少 __METHOD__："
    echo "$MATCHES"
    echo "建議：在 slog array 中加入 'method' => __METHOD__"
fi
