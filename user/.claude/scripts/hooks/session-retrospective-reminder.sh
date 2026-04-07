#!/bin/bash
# Session end: output six-question self-check prompt and skill-retrospective stats
# Project-aware: skips if project has its own session retrospective hook

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HOOKS_DIR/_lib/detect-project.sh"

# Skip if project defines its own session retrospective (avoid double output)
if ls "$PROJECT_ROOT/.claude/hooks/"*session*retrospective* &>/dev/null 2>&1; then
    exit 0
fi

# Dynamic path: derive Claude project slug from PROJECT_ROOT
PROJECT_SLUG=$(echo "$PROJECT_ROOT" | sed 's|/|-|g; s|^-||')
RETRO_FILE="$HOME/.claude/projects/-${PROJECT_SLUG}/memory/skill-retrospective.md"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "六問自檢（execution-policy.md 強制）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Edit/Write 後？       → code-reviewer 已跑？"
echo "2. Bug fix/新功能？      → tdd-guide 已跑？"
echo "3. 涉及 SQL？            → database-reviewer 已跑？"
echo "4. 涉及安全/認證/金額？   → security-reviewer 已跑？"
echo "5. 新陷阱？              → MEMORY.md 已更新？"
echo "6. skill-retrospective？ → 已追加本次任務紀錄？"

if [ -f "$RETRO_FILE" ]; then
  RECORD_COUNT=$(grep -c '^## 20' "$RETRO_FILE" 2>/dev/null || echo "0")
  LAST_STATS=$(grep '最後更新：' "$RETRO_FILE" | tail -1 || echo "（無）")

  echo ""
  echo "skill-retrospective 現況：共 ${RECORD_COUNT} 筆 | ${LAST_STATS}"

  if [ "$((RECORD_COUNT % 5))" -eq 0 ] && [ "$RECORD_COUNT" -gt 0 ]; then
    echo "WARNING: 達到 ${RECORD_COUNT} 筆，請確認統計摘要是否已更新"
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
