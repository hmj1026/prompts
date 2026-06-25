#!/usr/bin/env bash
# session-start.sh — SessionStart hook
# - Verify docker containers (pos_php / pos_mysql) availability.
# - Pre-create .claude/artifacts/ directory tree.
# - Write sessions/latest.md for statusline and agent reference.
# - Profile resolved by get_hook_profile() — env $ZDPOS_HOOK_PROFILE >
#   .claude/.harness-profile > "standard".
set -o pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
. "$(dirname "$0")/_lib/payload.sh"
PROFILE="$(get_hook_profile)"
ARTIFACTS="$ROOT/.claude/artifacts"
SESSION_FILE="$ARTIFACTS/sessions/latest.md"

# 1. Pre-create artifact directories
mkdir -p "$ARTIFACTS/reviews" "$ARTIFACTS/plans" "$ARTIFACTS/audits" "$ARTIFACTS/refactors" "$ARTIFACTS/codemaps" "$ARTIFACTS/adr" "$ARTIFACTS/sessions"

# 1b. Reap STALE gitnexus MCP processes (the owning session has ended).
# Reason: each session spawns a gitnexus mcp as a DIRECT child of its `claude`
#         process; when that claude exits the orphan is adopted by the session
#         subreaper (WSL/Claude Code reparents to `Relay(...)`, other hosts to
#         user `systemd` or init/PID 1) and lingers, competing for the LadybugDB
#         write lock and corrupting the FTS index. Per memory trap_mcp_zombie_processes
#         we identify staleness by the PARENT, not "newest": a LIVE gitnexus's parent
#         is `claude`, so we reap ONLY on a recognised subreaper/init parent and KEEP
#         on anything else (claude or any ambiguous parent) — never broad-kill a live
#         process (e.g. a concurrent worktree session's gitnexus). Errs false-negative
#         (an unreaped stray is recoverable; a killed live session is not).
_gn_reaped=0
while IFS= read -r _gn_pid; do
    [ -z "$_gn_pid" ] && continue
    _gn_ppid="$(ps -o ppid= -p "$_gn_pid" 2>/dev/null | tr -d ' ')"
    _gn_pcomm="$(ps -o comm= -p "${_gn_ppid:-0}" 2>/dev/null)"
    case "${_gn_ppid:-}:${_gn_pcomm:-}" in
        1:*|*:Relay*|*:systemd|*:init|*:init-*)
            kill "$_gn_pid" 2>/dev/null && _gn_reaped=$((_gn_reaped + 1)) ;;
    esac
done < <(pgrep -f "gitnexus mcp" 2>/dev/null)
[[ "$_gn_reaped" -gt 0 ]] && echo "[session-start] reaped $_gn_reaped stale gitnexus mcp processes"
unset _gn_pid _gn_ppid _gn_pcomm _gn_reaped

# 1c. Auto-purge sentinels older than 14 days (conservative initial threshold).
# Reason: orphan sentinels from crashed review agents block git push (pre-bash-guard.sh)
#         and require manual `rm`. 14d (336h) protects in-progress reviews; Stop hook
#         continues to warn at 24h. Drop to 7d after 1-2 weeks if no false positives.
bash "$(dirname "$0")/reap-stale-sentinels.sh" --purge --threshold-hours 336 || true

# 1d/1e（已撤）：cross-CLI drift 與 plugin 版本 advisory 已由 dhpk plugin
# (>=0.10.0) 的 session-start 接手（check-cross-cli-drift.sh /
# check-plugin-version.sh + .claude/dhpk-versions.json pin）。

# 1f. 根目錄 symlink 完整性快檢（git pull / clean 誤刪防護 — 斷鏈即大聲警告）。
# .claude/ 直屬斷鏈由 plugin session-start 偵測（harness_restore_hint 印還原指令）；
# 本段僅保留 plugin 看不到的兩個根目錄項：.claude 本體 + CLAUDE.md / GEMINI.md。
if [ ! -d "$ROOT/.claude" ]; then
    echo "[session-start] WARN: $ROOT/.claude itself missing or broken — run: cd ~/projects/prompts && ./deploy/deploy.sh project zdpos-217"
fi
_broken=""
for _f in CLAUDE.md GEMINI.md; do
    if [ -L "$ROOT/$_f" ] && [ ! -e "$ROOT/$_f" ]; then
        _broken="${_broken}${_broken:+$'\n'}$ROOT/$_f"
    fi
done
if [ -n "$_broken" ]; then
    echo "[session-start] WARN: broken harness symlinks detected:"
    echo "$_broken" | sed 's/^/  - /'
    echo "[session-start] restore: cd ~/projects/prompts && ./deploy/deploy.sh project zdpos-217"
fi
unset _broken _f

# 2. Collect status
TS="$(date +'%Y-%m-%d %H:%M:%S %Z')"
BRANCH="$(git -C "$ROOT" branch --show-current 2>/dev/null || echo '(detached)')"
STAGED="$(git -C "$ROOT" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')"
MODIFIED="$(git -C "$ROOT" diff --name-only 2>/dev/null | wc -l | tr -d ' ')"
UNTRACKED="$(git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')"

DOCKER_PHP="unknown"
DOCKER_MYSQL="unknown"
if command -v docker >/dev/null 2>&1; then
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^pos_php$'; then
        DOCKER_PHP="running"
    else
        DOCKER_PHP="STOPPED"
    fi
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^pos_mysql$'; then
        DOCKER_MYSQL="running"
    else
        DOCKER_MYSQL="STOPPED"
    fi
else
    DOCKER_PHP="(docker cli missing)"
    DOCKER_MYSQL="(docker cli missing)"
fi

# 3. strict profile extra checks
STRICT_NOTES=""
if [[ "$PROFILE" == "strict" ]]; then
    if [[ "$DOCKER_PHP" != "running" ]]; then
        STRICT_NOTES+=$'\n- [WARN] pos_php not running: `docker compose up -d`'
    fi
    if [[ "$DOCKER_MYSQL" != "running" ]]; then
        STRICT_NOTES+=$'\n- [WARN] pos_mysql not running: `docker compose up -d`'
    fi
fi

# 4. Write sessions/latest.md
cat > "$SESSION_FILE" <<EOF
# Session Snapshot

- generated_at: $TS
- branch: $BRANCH
- staged: $STAGED / modified: $MODIFIED / untracked: $UNTRACKED
- pos_php: $DOCKER_PHP
- pos_mysql: $DOCKER_MYSQL
- hook_profile: $PROFILE
$STRICT_NOTES
EOF

# 5. stdout summary (enters chat)
echo "[session-start] branch=$BRANCH docker=$DOCKER_PHP/$DOCKER_MYSQL profile=$PROFILE"
if [[ -n "$STRICT_NOTES" ]]; then
    echo "[session-start] strict profile warnings:$STRICT_NOTES"
fi

exit 0
