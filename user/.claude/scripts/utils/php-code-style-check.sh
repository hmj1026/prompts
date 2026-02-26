#!/bin/bash

# PHP Code Style Check Hook
# Validates PHP code against PSR-2 standard and custom rules

set -e

echo "🎨 Running PHP code style check..."

# Check if file path is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <file_path>"
    exit 1
fi

file_path="$1"

# Only run for PHP files
if [[ ! "$file_path" == *.php ]]; then
    exit 0
fi

# Check if PHP_CodeSniffer is available
if ! command -v phpcs &> /dev/null; then
    echo "ℹ️  PHP_CodeSniffer not installed, skipping code style check"
    echo "   Install with: composer require --dev squizlabs/php_codesniffer"
    exit 0
fi

echo "Checking code style: $file_path"

# Run PHP_CodeSniffer with PSR-2 standard
phpcs --standard=PSR2 --warning-severity=0 "$file_path" 2>&1 || {
    echo ""
    echo "⚠️  Code style issues found. Run:"
    echo "   phpcbf --standard=PSR2 \"$file_path\""
    echo "   to auto-fix style issues"
    exit 0
}

echo "✅ Code style check passed"
