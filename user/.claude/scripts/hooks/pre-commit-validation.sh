#!/bin/bash

# Pre-commit validation hook for PHP projects
# Validates all staged PHP files before commits

set -e

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HOOKS_DIR/_lib/detect-project.sh"

# Only run for PHP projects
$HAS_PHP || exit 0

echo "Running pre-commit PHP validation..."

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not in a git repository, skipping pre-commit validation"
    exit 0
fi

# Get all staged PHP files
php_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.php$' || true)

if [ -z "$php_files" ]; then
    echo "✅ No PHP files staged"
    exit 0
fi

echo "📝 Found staged PHP files: $(echo $php_files | wc -w)"

# Counters
syntax_errors=0
security_warnings=0

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. PHP Syntax Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for file in $php_files; do
    if [ -f "$file" ]; then
        lint_log=$(mktemp)
        if ! php -l "$file" > "$lint_log" 2>&1; then
            echo "SYNTAX ERROR in $file:"
            cat "$lint_log"
            syntax_errors=$((syntax_errors + 1))
        else
            echo "$file OK"
        fi
        rm -f "$lint_log"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Security Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for file in $php_files; do
    if [ -f "$file" ]; then
        # Check for hardcoded secrets
        if grep -iE "(password|token|api_?key|secret)\s*[=']" "$file" > /dev/null 2>&1; then
            echo "⚠️  WARNING: Possible hardcoded secret in $file"
            security_warnings=$((security_warnings + 1))
        fi

        # Check for direct $_GET/$_POST access (should use Yii::app()->request)
        if grep -E '\$_(GET|POST|REQUEST|COOKIE)\[' "$file" > /dev/null 2>&1; then
            echo "⚠️  WARNING: Direct \$_GET/\$_POST access in $file (use Yii::app()->request instead)"
            security_warnings=$((security_warnings + 1))
        fi

        # Check for potential SQL injection (string concatenation in SQL)
        if grep -E '\$sql\s*=.*\$[a-zA-Z_]|".*\$[a-zA-Z_].*".*SELECT' "$file" > /dev/null 2>&1; then
            echo "⚠️  WARNING: Possible SQL injection in $file (use prepared statements)"
            security_warnings=$((security_warnings + 1))
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. PHP 5.6 Compatibility Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for file in $php_files; do
    if [ -f "$file" ]; then
        php56_violations=""
        style_warnings=""

        # Check for null coalescing operator (??) - PHP 7+ only
        if grep -E '\?\?' "$file" > /dev/null 2>&1; then
            php56_violations="${php56_violations}  - Null coalescing (??) not supported in PHP 5.6\n"
        fi

        # Check for type hints in function parameters - PHP 7+ only
        if grep -E 'function\s+\w+\s*\([^)]*:\s*(int|string|bool|float|array|void)' "$file" > /dev/null 2>&1; then
            php56_violations="${php56_violations}  - Scalar type hints not supported in PHP 5.6\n"
        fi

        # Check for return type declarations - PHP 7+ only
        if grep -E '\):\s*(void|int|string|bool|float|array)' "$file" > /dev/null 2>&1; then
            php56_violations="${php56_violations}  - Return type declarations not supported in PHP 5.6\n"
        fi

        if [ -n "$php56_violations" ]; then
            echo "⚠️  PHP 5.6 compatibility issues in $file:"
            echo -e "$php56_violations"
        else
            echo "✅ $file"
        fi

        # Style warnings (not compatibility issues)
        if grep -E '\barray\(' "$file" | grep -v 'array_' | grep -v '@' > /dev/null 2>&1; then
            style_warnings="${style_warnings}  - Style: prefer [] over array() (both are PHP 5.6 compatible)\n"
        fi

        if [ -n "$style_warnings" ]; then
            echo "ℹ️  Style suggestions for $file:"
            echo -e "$style_warnings"
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $syntax_errors -gt 0 ]; then
    echo "❌ Found $syntax_errors syntax errors"
    echo ""
    echo "⛔ COMMIT BLOCKED: Fix syntax errors before committing"
    exit 1
fi

if [ $security_warnings -gt 0 ]; then
    echo "⚠️  Found $security_warnings potential security issues"
    echo ""
    echo "COMMIT ALLOWED but REVIEW RECOMMENDED"
    echo "Please review the warnings above before pushing to production"
fi

echo "✅ Pre-commit validation passed"
echo ""
