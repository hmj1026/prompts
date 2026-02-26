> This file extends [common/hooks.md](../common/hooks.md) with PHP specific content.

# PHP PostToolUse Hooks

## Code Quality Hooks Configuration

Add these to your PostToolUse hooks in Claude Code settings to automatically validate PHP code:

### Hook 1: PHP Syntax Validation

```bash
# Validate PHP syntax after Write/Edit tools
php -l "$file_path" 2>&1 | grep -E "Parse error|Syntax Error" && exit 1 || true
```

**What it checks:**
- Parse errors in PHP code
- Syntax violations
- Invalid PHP constructs

### Hook 2: PHPStan Linting (Optional - if available in your environment)

```bash
# Run PHPStan level 5 (medium strictness, PHP 5.6 compatible)
if command -v phpstan &> /dev/null; then
  phpstan analyse --level 5 --no-interaction "$file_path" 2>&1 | head -20
fi
```

**What it checks:**
- Type consistency
- Undefined variables
- Incorrect method calls
- Missing PHPDoc

### Hook 3: PHP_CodeSniffer (PSR-2 Standard)

```bash
# Check PSR-2 coding standard
if command -v phpcs &> /dev/null; then
  phpcs --standard=PSR2 "$file_path" 2>&1 | head -30
fi
```

**What it checks:**
- Indentation (4 spaces)
- Line length (max 120 chars recommended)
- Naming conventions
- Bracket placement

## Pre-Write Validation

Before Write tool on PHP files:

```bash
# Check if file is valid PHP (first 50 lines)
php -l "${file_path}" 2>&1 || echo "Note: File may not exist yet (new file)"
```

## Post-Edit Validation

After Edit tool on PHP files:

```bash
# Validate PHP syntax immediately after edit
php -l "$file_path" 2>&1 | tee /tmp/php_check.log

# Fail if parse errors found
if grep -q "Parse error" /tmp/php_check.log; then
  echo "❌ PHP Syntax Error - Please fix"
  exit 1
fi

# Warn if possible issues (but don't block)
if [ -s /tmp/php_check.log ]; then
  echo "⚠️  PHP Check Warnings (non-blocking)"
fi
```

## PHP 5.6 Compatibility Check

```bash
# Check for PHP 7+ syntax that breaks PHP 5.6
if grep -E "(\?\?|->|: ?(?:void|int|string|bool|float|array)|function.*\(.*:)" "$file_path"; then
  echo "⚠️  WARNING: Found potential PHP 7+ syntax incompatible with PHP 5.6"
  echo "   - Check for: null coalescing (??), type hints, return types"
  exit 0  # Don't block, just warn
fi
```

## Example Hook Configuration in ~/.claude/settings.json

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "tool": "Write",
        "command": "if [[ '$file_path' == *.php ]]; then php -l '$file_path' 2>&1; fi",
        "description": "Validate PHP syntax on Write",
        "blocking": false
      },
      {
        "tool": "Edit",
        "command": "if [[ '$file_path' == *.php ]]; then php -l '$file_path' 2>&1 | grep -q 'Parse error' && exit 1 || true; fi",
        "description": "Validate PHP syntax on Edit",
        "blocking": true
      }
    ]
  }
}
```

## IDE Integration

### PHPStorm / JetBrains

Enable inspections in project settings:
- Enable PHP syntax check
- Enable PHP_CodeSniffer with PSR-2
- Enable PHPStan (if installed)
- PHP version set to 5.6

### VS Code

Install extensions:
- **PHP Intelephense** - PHP language support
- **PHP Sniffer & Beautifier** - Code style checking
- **PHPStan Plugin** - Static analysis (if available)

Add to `.vscode/settings.json`:
```json
{
  "php.validate.executablePath": "/usr/bin/php",
  "php.version": "5.6",
  "[php]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "persisted_state.phpsniffer"
  }
}
```

## Docker PHPUnit Integration

For automated test validation:

```bash
# PostToolUse hook to run tests on model/test changes
if [[ "$file_path" == *"Test.php" ]] || [[ "$file_path" == *models* ]]; then
  echo "Running PHPUnit..."
  docker exec -w //var/www/www.posdev/zdpos_dev pos_php \
    phpunit $(dirname "$file_path") \
    2>&1 | tail -20
fi
```

## Commit Hook Preparation

Before `git commit`:

```bash
# Validate all staged PHP files
php_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.php$')
if [ -n "$php_files" ]; then
  echo "Validating PHP files..."
  php -l $php_files || exit 1
fi

# Check for hardcoded secrets
if git diff --cached | grep -E "(password|token|key|secret)\s*[=:]|'[A-Za-z0-9]{32,}'"; then
  echo "❌ ERROR: Possible hardcoded secret found"
  exit 1
fi
```
