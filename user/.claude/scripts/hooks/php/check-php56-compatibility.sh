#!/bin/bash
# PHP 5.6 相容性檢查（強化版）
# 偵測 PHP 7.0+ 語法，防止不相容程式碼進入 PHP 5.6 專案
# 觸發：PostToolUse Write/Edit (async)

FILE_PATH="$1"

# 僅檢查 .php 檔案
if [[ "$FILE_PATH" != *.php ]]; then
    exit 0
fi

# 排除 vendor / extensions 目錄
if [[ "$FILE_PATH" == */vendors/* ]] || [[ "$FILE_PATH" == */vendor/* ]] || [[ "$FILE_PATH" == */extensions/* ]]; then
    exit 0
fi

ISSUES=""

# --------------------------------------------------
# PHP 7.0 語法
# --------------------------------------------------

# 1. Null coalescing operator: ??
if grep -Pn '\?\?' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - ?? (null coalescing operator) [PHP 7.0] -> 改用 isset(\$x) ? \$x : default"
fi

# 2. Return type declarations: ): void, ): string, ): int, etc.
if grep -Pn '\)\s*:\s*(void|int|string|bool|float|array|self|callable|iterable)\b' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - Return type declaration [PHP 7.0] -> 改用 @return PHPDoc"
fi

# 3. Scalar type hints in parameters: function foo(int $x, string $y)
if grep -Pn 'function\s+\w+\s*\([^)]*\b(int|string|bool|float)\s+\$' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - Scalar type hints [PHP 7.0] -> 改用 @param PHPDoc"
fi

# 4. Spaceship operator: <=>
if grep -Pn '<=>' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - <=> (spaceship operator) [PHP 7.0] -> 改用 strcmp() 或手動比較"
fi

# 5. Anonymous classes: new class
if grep -Pn '\bnew\s+class\b' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - Anonymous class [PHP 7.0] -> 改用具名 class"
fi

# 6. Group use declarations: use Foo\{Bar, Baz}
if grep -Pn 'use\s+[A-Za-z\\]+\\{' "$FILE_PATH" 2>/dev/null | grep -q .; then
    ISSUES="${ISSUES}\n  - Group use declarations [PHP 7.0] -> 分開寫多行 use"
fi

# 7. define() with arrays: define('X', [...])
if grep -Pn 'define\s*\([^,]+,\s*\[' "$FILE_PATH" 2>/dev/null | grep -q .; then
    ISSUES="${ISSUES}\n  - define() with array [PHP 7.0] -> 改用 class const 或全域變數"
fi

# --------------------------------------------------
# PHP 7.1 語法
# --------------------------------------------------

# 8. Nullable type hints: ?string, ?int
if grep -Pn '\?\s*(string|int|float|bool|array)\s+\$' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - Nullable type hint (?type) [PHP 7.1] -> 改用 @param type|null PHPDoc"
fi

# 9. Multi-catch: catch (A | B $e)
if grep -Pn 'catch\s*\([^)]*\|[^)]*\$' "$FILE_PATH" 2>/dev/null | grep -q .; then
    ISSUES="${ISSUES}\n  - Multi-catch (A | B) [PHP 7.1] -> 分開寫多個 catch"
fi

# 10. Iterable type hint
if grep -Pn '(\biterable\b\s+\$|:\s*iterable\b)' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - iterable type hint [PHP 7.1] -> 改用 @param array PHPDoc"
fi

# 11. Void return type
if grep -Pn '\)\s*:\s*void\b' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - void return type [PHP 7.1] -> 改用 @return void PHPDoc"
fi

# 12. list() symmetric destructuring: [$a, $b] = ...
if grep -Pn '^\s*\[.*\]\s*=' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -v '\$\w+\[' | grep -q .; then
    ISSUES="${ISSUES}\n  - Short list() syntax [\$a, \$b] = [PHP 7.1] -> 改用 list(\$a, \$b) ="
fi

# 13. Class constant visibility: public const, private const, protected const
if grep -Pn '\b(public|private|protected)\s+const\b' "$FILE_PATH" 2>/dev/null | grep -q .; then
    ISSUES="${ISSUES}\n  - Class constant visibility [PHP 7.1] -> 移除 visibility 修飾詞"
fi

# --------------------------------------------------
# PHP 7.2+ 語法
# --------------------------------------------------

# 14. object type hint
if grep -Pn '(\bobject\s+\$|:\s*object\b)' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - object type hint [PHP 7.2] -> 改用 @param mixed PHPDoc"
fi

# --------------------------------------------------
# PHP 7.4 語法
# --------------------------------------------------

# 15. Arrow functions: fn($x) =>
if grep -Pn '\bfn\s*\(' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - Arrow function fn() [PHP 7.4] -> 改用 function() { return ... }"
fi

# 16. Typed properties: public int $x, private string $name
if grep -Pn '\b(public|private|protected)\s+(int|string|float|bool|array|\?)\s+\$' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - Typed properties [PHP 7.4] -> 移除型別宣告，改用 @var PHPDoc"
fi

# 17. Null coalescing assignment: ??=
if grep -Pn '\?\?=' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - ??= (null coalescing assignment) [PHP 7.4] -> 改用 if (!isset()) 賦值"
fi

# 18. Spread operator in array: [...$array]
if grep -Pn '\[\s*\.\.\.\$' "$FILE_PATH" 2>/dev/null | grep -q .; then
    ISSUES="${ISSUES}\n  - Spread in array [...\$arr] [PHP 7.4] -> 改用 array_merge()"
fi

# --------------------------------------------------
# PHP 8.0+ 語法
# --------------------------------------------------

# 19. Named arguments: func(name: value)
if grep -Pn '\b\w+\s*\(\s*\w+\s*:(?!:)' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -v 'array(' | grep -v "'" | grep -q .; then
    ISSUES="${ISSUES}\n  - Named arguments [PHP 8.0] -> 改用位置參數或 options array"
fi

# 20. Match expression: match($x) {
if grep -Pn '\bmatch\s*\(' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -v 'preg_match\|str.*match\|stripos' | grep -q .; then
    ISSUES="${ISSUES}\n  - match() expression [PHP 8.0] -> 改用 switch/case"
fi

# 21. Union types: int|string
if grep -Pn '\)\s*:\s*\w+\|\w+' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - Union types [PHP 8.0] -> 改用 @return PHPDoc"
fi

# 22. Constructor promotion: public function __construct(private $x)
if grep -Pn '__construct\s*\([^)]*\b(public|private|protected)\s' "$FILE_PATH" 2>/dev/null | grep -q .; then
    ISSUES="${ISSUES}\n  - Constructor promotion [PHP 8.0] -> 手動在 constructor body 賦值"
fi

# 23. Nullsafe operator: ?->
if grep -Pn '\?->' "$FILE_PATH" 2>/dev/null | grep -Pv '^\d+:\s*//' | grep -Pv '^\d+:\s*\*' | grep -q .; then
    ISSUES="${ISSUES}\n  - ?-> (nullsafe operator) [PHP 8.0] -> 改用 if/isset 檢查"
fi

# --------------------------------------------------
# 輸出結果
# --------------------------------------------------
if [ -n "$ISSUES" ]; then
    echo "WARNING: PHP 5.6 相容性問題 ($FILE_PATH):"
    echo -e "$ISSUES"
    exit 0  # async hook，不阻擋（交由 pre-commit hook 阻擋）
fi
