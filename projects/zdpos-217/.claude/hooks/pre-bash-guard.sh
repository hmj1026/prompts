#!/usr/bin/env bash
# pre-bash-guard.sh — PreToolUse (Bash) hook，zdpos 專案專屬守則。
#
# 2026-06-12 de-fork：通用守則（rm -rf 系統目錄、curl|sh、chmod 777、
# git push sentinel 攔截、--no-verify 阻擋、git commit JS gate）已升級由
# dhpk plugin (>=0.10.0) 的 pre-bash-dispatch.sh + pre-bash-guard.sh +
# modules/js pre-commit hook 接手。本檔僅保留 dhpk 不該收的 zdpos 在地陷阱：
#   Pattern 1: vendor/bin/php-cs-fixer（本地 vendor v2 vs CI v3 雙版本陷阱）
#   Pattern 7: playwright E2E → dev4 opcache reset 提醒（advisory）
#   Pattern 8: 容器內舊 workdir zdpos_dev 路徑提醒（advisory）
set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"

PAYLOAD="$(cat 2>/dev/null || true)"
CMD="$(extract_tool_input command "$PAYLOAD")"
[ -z "$CMD" ] && exit 0

# Strip shell comments before matching (avoid false-positive on `# see vendor/bin/php-cs-fixer`)
CMD_STRIPPED="$(printf '%s' "$CMD" | sed 's/[[:space:]]*#.*//')"

# Pattern 1: vendor/bin/php-cs-fixer (local v2 binary)
if printf '%s' "$CMD_STRIPPED" | grep -Eq '(^|[[:space:]/])vendor/bin/php-cs-fixer\b'; then
  cat <<'EOF' >&2
[guard] BLOCKED: vendor/bin/php-cs-fixer
Local vendor is php-cs-fixer v2 (PHP 5.6); CI uses v3 with v3-only config.
Running locally will mangle formatting. Use one of:
  - GitHub Actions CI run
  - docker tooling-php container with php-cs-fixer v3
See memory/workflow-traps.md "CI php-cs-fixer 雙版本決策".
EOF
  exit 2  # Non-zero blocks the tool call in Claude Code
fi

# Pattern 7: playwright E2E → opcache reset 提醒（advisory，不阻擋；JSON additionalContext）。
# dev4 直接 render 本 repo views，但 opcache revalidate_freq=60 會服務舊 bytecode →
# E2E 偽綠 / RED demo 失效（memory: trap_dev4_opcache_revalidate_false_green）。
# 以 marker mtime 節流：30 分鐘內只提醒一次，避免 playwright-cli 連續呼叫洗版。
if printf '%s' "$CMD_STRIPPED" | grep -Eq '(^|[[:space:]])(npx[[:space:]]+playwright|playwright-cli)([[:space:]]|$)'; then
  _ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  _MARKER="$_ROOT/.claude/artifacts/sessions/.opcache-reminded"
  _now="$(date +%s)"
  _last=0
  if [ -f "$_MARKER" ]; then
    if [ "$(uname)" = "Darwin" ]; then
      _last="$(stat -f %m "$_MARKER" 2>/dev/null || echo 0)"
    else
      _last="$(stat -c %Y "$_MARKER" 2>/dev/null || echo 0)"
    fi
  fi
  if [ $((_now - _last)) -gt 1800 ]; then
    mkdir -p "$(dirname "$_MARKER")" 2>/dev/null
    touch "$_MARKER" 2>/dev/null
    cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"[guard] E2E 提醒：dev4 opcache revalidate_freq=60 — 跑 E2E / 截圖前先 docker exec -i pos_php sh -c 'kill -USR2 1' reset，避免偽綠（trap_dev4_opcache_revalidate_false_green）。"}}
JSON
    exit 0
  fi
fi

# Pattern 8: 舊 codebase 容器路徑 www.posdev/zdpos_dev 提醒（advisory，不阻擋）。
# 容器內正確 workdir 已改為 www.posdev/zdpos-217；沿用舊路徑的指令仍可能執行但
# 對應到錯誤/不存在目錄，故僅提醒不 exit 2。
if printf '%s' "$CMD_STRIPPED" | grep -Fq 'www.posdev/zdpos_dev'; then
  cat <<'EOF' >&2
[guard] 提醒：偵測到舊 workdir 路徑 www.posdev/zdpos_dev；目前正確路徑為 www.posdev/zdpos-217，請確認指令是否需要更新。
EOF
fi

exit 0
