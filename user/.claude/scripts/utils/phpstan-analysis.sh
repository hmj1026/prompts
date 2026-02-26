#!/bin/bash

# PHPStan Static Analysis Hook
# Performs static analysis on PHP files to catch type errors and potential bugs

set -e

echo "🔬 Running PHPStan static analysis..."

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

# Check if PHPStan is available
if ! command -v phpstan &> /dev/null; then
    echo "ℹ️  PHPStan not installed, skipping static analysis"
    echo "   Install with: composer require --dev phpstan/phpstan"
    exit 0
fi

echo "Analyzing: $file_path"

# Run PHPStan with level 5 (medium strictness, good for legacy PHP 5.6 code)
# Use --no-interaction to prevent interactive mode
phpstan analyse \
    --level 5 \
    --no-interaction \
    --memory-limit=256M \
    "$file_path" 2>&1 || {
    echo ""
    echo "⚠️  PHPStan found potential issues"
    echo "   Review the errors above"
    exit 0
}

echo "✅ Static analysis passed"
