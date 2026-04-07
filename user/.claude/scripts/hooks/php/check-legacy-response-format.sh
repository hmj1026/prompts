#!/bin/bash
# 偵測 legacy API response 格式（禁止在新程式碼中使用）
# 規則來源：~/.claude/rules/php/error-handling-patterns.md
# 觸發：PostToolUse Write/Edit (async)

FILE_PATH="$1"

# 僅檢查 PHP 檔案
case "$FILE_PATH" in
    *.php) ;;
    *) exit 0 ;;
esac

# 排除 vendor / extensions
if [[ "$FILE_PATH" == */vendors/* ]] || \
   [[ "$FILE_PATH" == */vendor/* ]] || \
   [[ "$FILE_PATH" == */extensions/* ]]; then
    exit 0
fi

[ ! -f "$FILE_PATH" ] && exit 0

ISSUES=""

# 偵測 echo "success" / "fail" / "error" 字串回應
ECHO_MATCHES=$(grep -Pn 'echo\s+["\x27](success|fail|error)["\x27]' "$FILE_PATH" 2>/dev/null)
if [ -n "$ECHO_MATCHES" ]; then
    ISSUES="${ISSUES}\n  echo 字串回應（應改用 \$this->json()）:\n${ECHO_MATCHES}"
fi

# 偵測非標準 json_encode 回應（不含 'success' key）
JSON_MATCHES=$(grep -Pn 'echo\s+json_encode\s*\(' "$FILE_PATH" 2>/dev/null | grep -v "'success'")
if [ -n "$JSON_MATCHES" ]; then
    ISSUES="${ISSUES}\n  非標準 json_encode（應改用 Response trait）:\n${JSON_MATCHES}"
fi

# 偵測 die()/exit() 在非 bootstrap/config 檔案中
if [[ "$FILE_PATH" != *config* ]] && [[ "$FILE_PATH" != *bootstrap* ]] && [[ "$FILE_PATH" != *index.php ]]; then
    DIE_MATCHES=$(grep -Pn '\b(die|exit)\s*\(' "$FILE_PATH" 2>/dev/null)
    if [ -n "$DIE_MATCHES" ]; then
        ISSUES="${ISSUES}\n  die()/exit()（應拋出例外）:\n${DIE_MATCHES}"
    fi
fi

if [ -n "$ISSUES" ]; then
    echo -e "WARNING: $FILE_PATH 含有 legacy response 格式：${ISSUES}"
    echo "建議：新增 AJAX action 使用 Response trait（\$this->json() / \$this->error()）"
fi
