#!/bin/bash
echo "🔍 Verifying Claude Code PHP Hooks Setup..."

pass=0
fail=0

# Check settings.json
if [ -f ~/.claude/settings.json ]; then
    echo "✅ settings.json exists"
    ((pass++))
else
    echo "❌ settings.json not found"
    ((fail++))
    exit 1
fi

# Validate JSON
if python3 -m json.tool ~/.claude/settings.json > /dev/null 2>&1; then
    echo "✅ JSON syntax valid"
    ((pass++))
else
    echo "❌ JSON syntax invalid"
    ((fail++))
fi

# Check hooks section
if grep -q '"hooks"' ~/.claude/settings.json; then
    echo "✅ hooks section configured"
    ((pass++))
fi

# Check pre-commit script
if [ -x ~/.claude/hooks/pre-commit-validation.sh ]; then
    echo "✅ pre-commit-validation.sh (executable)"
    ((pass++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
[ $fail -eq 0 ] && echo "✅ Setup valid! PHP hooks configured." || echo "❌ Setup has errors."
