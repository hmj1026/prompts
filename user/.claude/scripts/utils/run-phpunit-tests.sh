#!/bin/bash

# PHPUnit test runner hook
# Automatically runs relevant tests when test files or models are modified

set -e

echo "🧪 Running PHPUnit tests..."

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

# Check if PHPUnit is available
if ! command -v phpunit &> /dev/null; then
    echo "⚠️  PHPUnit not found, skipping test execution"
    exit 0
fi

# Check if Docker is available and project structure suggests Docker usage
if [ -f "docker-compose.yml" ] || [ -f "Dockerfile" ]; then
    if command -v docker &> /dev/null; then
        echo "📦 Using Docker for PHPUnit execution"

        # Determine test path based on file type
        if [[ "$file_path" == *"Test.php" ]] || [[ "$file_path" == *"tests"* ]]; then
            # Direct test file
            test_path="$file_path"
        else
            # Model/component file - look for corresponding test
            test_basename=$(basename "$file_path" .php)
            test_path="protected/tests/unit/models/${test_basename}Test.php"

            if [ ! -f "$test_path" ]; then
                test_path="protected/tests/unit/${test_basename}Test.php"
            fi
        fi

        if [ -f "$test_path" ]; then
            echo "Running tests in: $test_path"
            docker exec -w //var/www/www.posdev/zdpos_dev pos_php \
                phpunit "$test_path" \
                2>&1 | tail -50
        else
            echo "⚠️  No test file found for $file_path"
        fi
        exit 0
    fi
fi

# Fallback: local PHPUnit execution
echo "Running local PHPUnit..."

# Determine test path based on file type
if [[ "$file_path" == *"Test.php" ]] || [[ "$file_path" == *"tests"* ]]; then
    test_path="$file_path"
else
    # Model/component file - look for corresponding test
    test_basename=$(basename "$file_path" .php)
    test_path="protected/tests/unit/models/${test_basename}Test.php"

    if [ ! -f "$test_path" ]; then
        test_path="protected/tests/unit/${test_basename}Test.php"
    fi
fi

if [ -f "$test_path" ]; then
    echo "Running tests in: $test_path"
    phpunit "$test_path" 2>&1 | tail -50
else
    echo "⚠️  No test file found for $file_path"
fi
