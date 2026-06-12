#!/usr/bin/env bash
# pre-bash-guard.sh — PreToolUse (Bash) hook
# Block known-dangerous local commands. First entry: vendor/bin/php-cs-fixer
# (local vendor pinned to v2; CI uses v3 with v3 config — local run mangles formatting).
# Reference: memory/workflow-traps.md "CI php-cs-fixer 雙版本決策".
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

# Pattern 2: rm 遞迴刪除對根目錄或系統關鍵目錄（含 -r / -R / -rf / -fr / -Rf 等任何旗標組合）。
# 採白名單：只阻擋已知危險的 top-level dir，避免誤擋 /tmp /var/tmp /var/log 等合法清理。
# 命中：rm -rf / · rm -r /etc · rm -Rf /home · rm -fr /boot · rm -rf -- /usr · rm -rf /*
# 放行：rm -rf relative/ · rm -rf /tmp/foo · rm -rf /var/tmp/build · rm -rf ./x
# 注意：DANGEROUS_ROOT 故意不含 var — 子目錄 /var/tmp /var/log 需要放行；
#       若硬加 var，整個 /var/* 都會被擋下，會打到 Docker/PHPUnit 清理流程。
DANGEROUS_ROOT='(etc|usr|bin|sbin|lib|lib64|boot|proc|sys|dev|run|root|home|opt|srv|snap)'
if printf '%s' "$CMD_STRIPPED" | grep -Eq \
  "(^|[[:space:];&|])rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)+(--[[:space:]]+)?/([[:space:]\$\*]|$|${DANGEROUS_ROOT}([/[:space:]]|$))"; then
  echo "[guard] BLOCKED: rm -rf 對根目錄或系統關鍵目錄。請改縮小範圍，或在 Claude 之外手動執行。" >&2
  exit 2
fi

# Pattern 3: 把遠端下載直接管線到 shell（curl|sh / wget|bash / fetch|zsh ...）。
# 阻擋典型的供應鏈攻擊模式 "curl ... | sh" / "wget -O- ... | bash"。
if printf '%s' "$CMD_STRIPPED" | grep -Eq '(curl|wget|fetch)[^|]*\|[[:space:]]*(sh|bash|zsh|ksh)([[:space:]]|$|;|\|)'; then
  echo "[guard] BLOCKED: 把遠端下載管線到 shell。請先存檔、檢視內容，再執行。" >&2
  exit 2
fi

# Pattern 4: chmod 777/666（含 -R777 / -rR 777 等變體）— 幾乎必為錯誤。
# (-[a-zA-Z]*[[:space:]]*)? 同時涵蓋 -R / -rR / -R777 / -v 等旗標排列。
if printf '%s' "$CMD_STRIPPED" | grep -Eq '(^|[[:space:];&|])chmod[[:space:]]+(-[a-zA-Z]*[[:space:]]*)?[0-7]?(777|666)([[:space:]]|$)'; then
  echo "[guard] BLOCKED: chmod 777/666。請改用較嚴格的權限（如 750/640），或縮小路徑範圍。" >&2
  exit 2
fi

# Pattern 5: git push 前確認無懸掛 review sentinel。
# execution-policy.md 禁止在 .pending-* sentinel 存在時推送，此 hook 強制執行該規則。
# 排除 --help / -h / --dry-run，避免誤擋說明查詢。
if printf '%s' "$CMD_STRIPPED" | grep -Eq '(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)' && \
   ! printf '%s' "$CMD_STRIPPED" | grep -Eq '(--help|[[:space:]]-h([[:space:]]|$)|--dry-run)'; then
  HOOK_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  SENTINEL_DIR="$HOOK_ROOT/.claude/artifacts/sessions"
  FOUND=""
  # 用 _lib/payload.sh 的 SENTINEL_NAMES SSOT（全 6 槽），避免硬寫清單漏掉
  # frontend / doc / migration review。payload.sh 已於檔頭 source。
  for _s in "${SENTINEL_NAMES[@]}"; do
    [ -f "$SENTINEL_DIR/$_s" ] && FOUND="$FOUND $_s"
  done
  if [ -n "$FOUND" ]; then
    echo "[guard] BLOCKED: git push 因懸掛 sentinel 存在：$FOUND" >&2
    echo "[guard] 請先執行所需的 review agent，再推送。" >&2
    exit 2
  fi
fi

# Pattern 6: git commit → staged JS lint/typecheck gate（委派 pre-commit-js-validation.sh）。
# 該腳本原本獨立 wire 在 PreToolUse(Bash)，導致每次 Bash 呼叫都 spawn 第二個 hook process
# 空轉（source payload.sh + 解析 stdin）。改由本 guard 先以字串便宜判斷 git commit
# 才委派，settings.json 不再單獨 wire（2026-06-12 harness 健檢 H-1）。
# 排除 git commit-tree（plumbing，rebase / merge 內部使用）與委派腳本內部邏輯一致。
case "$CMD_STRIPPED" in
  *"git commit-tree"*) : ;;
  *"git commit"*)
    if ! printf '%s' "$PAYLOAD" | bash "$(dirname "$0")/pre-commit-js-validation.sh"; then
      exit 2
    fi
    ;;
esac

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

exit 0
