#!/bin/bash
# 檔案大小 + 函式長度警告 hook
# 檔案：超過 800 行 warning，超過 1200 行 critical
# 函式：超過 50 行 warning（僅 PHP）
# 觸發：PostToolUse Write/Edit (async)

FILE_PATH="$1"

# 僅檢查程式碼檔案
case "$FILE_PATH" in
    *.php|*.py|*.js|*.ts|*.tsx|*.css|*.json) ;;
    *) exit 0 ;;
esac

# 排除 vendor / extensions / 產生檔案
if [[ "$FILE_PATH" == */vendors/* ]] || \
   [[ "$FILE_PATH" == */vendor/* ]] || \
   [[ "$FILE_PATH" == */extensions/* ]] || \
   [[ "$FILE_PATH" == */node_modules/* ]] || \
   [[ "$FILE_PATH" == */runtime/* ]] || \
   [[ "$FILE_PATH" == */assets/* ]]; then
    exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# --- 檔案行數檢查 ---
LINE_COUNT=$(wc -l < "$FILE_PATH")
WARNING_THRESHOLD=800
CRITICAL_THRESHOLD=1200

if [ "$LINE_COUNT" -gt "$CRITICAL_THRESHOLD" ]; then
    echo "CRITICAL: $FILE_PATH 有 ${LINE_COUNT} 行（超過 ${CRITICAL_THRESHOLD} 行硬限）。強烈建議拆分檔案。"
elif [ "$LINE_COUNT" -gt "$WARNING_THRESHOLD" ]; then
    echo "WARNING: $FILE_PATH 有 ${LINE_COUNT} 行（超過 ${WARNING_THRESHOLD} 行上限）。考慮拆分或提取子模組。"
fi

# --- 函式長度檢查 ---
case "$FILE_PATH" in
    *.py)
        FUNC_THRESHOLD=50
        LONG_FUNCS=$(awk '
        /^[[:space:]]*(async[[:space:]]+)?def[[:space:]]+/ {
            fname = $0
            sub(/.*def[[:space:]]+/, "", fname)
            sub(/\(.*/, "", fname)
            start = NR
        }
        start > 0 && NR > start && /^[[:space:]]*(async[[:space:]]+)?def[[:space:]]+/ {
            len = NR - start
            if (len > '"$FUNC_THRESHOLD"') {
                printf "  Line %d: def %s (%d lines)\n", start, prev_fname, len
            }
            fname = $0
            sub(/.*def[[:space:]]+/, "", fname)
            sub(/\(.*/, "", fname)
            start = NR
        }
        start > 0 { prev_fname = fname }
        END {
            if (start > 0) {
                len = NR - start + 1
                if (len > '"$FUNC_THRESHOLD"') {
                    printf "  Line %d: def %s (%d lines)\n", start, prev_fname, len
                }
            }
        }
        ' "$FILE_PATH" 2>/dev/null)

        if [ -n "$LONG_FUNCS" ]; then
            echo "WARNING: $FILE_PATH contains functions exceeding ${FUNC_THRESHOLD} lines:"
            echo "$LONG_FUNCS"
        fi
        ;;
    *.php)
        FUNC_THRESHOLD=50
        LONG_FUNCS=$(awk '
        /^[[:space:]]*(public|protected|private|static)?[[:space:]]*(public|protected|private|static)?[[:space:]]*function[[:space:]]+/ {
            fname = $0
            sub(/.*function[[:space:]]+/, "", fname)
            sub(/\(.*/, "", fname)
            start = NR
            depth = 0
            found_brace = 0
        }
        start > 0 && /{/ {
            if (!found_brace) found_brace = 1
            depth++
        }
        start > 0 && /}/ {
            depth--
            if (found_brace && depth <= 0) {
                len = NR - start + 1
                if (len > '"$FUNC_THRESHOLD"') {
                    printf "  Line %d: function %s (%d lines)\n", start, fname, len
                }
                start = 0
                found_brace = 0
            }
        }
        ' "$FILE_PATH" 2>/dev/null)

        if [ -n "$LONG_FUNCS" ]; then
            echo "WARNING: $FILE_PATH 含有超過 ${FUNC_THRESHOLD} 行的函式："
            echo "$LONG_FUNCS"
        fi
        ;;
esac
