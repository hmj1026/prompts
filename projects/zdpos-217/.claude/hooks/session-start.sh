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

# 1b. Reap stale gitnexus MCP processes, keep only the newest one.
# Reason: each session starts a new gitnexus mcp process; old ones are not auto-reaped.
#         Concurrent processes competing for the LadybugDB write lock break the FTS index.
_gn_pids=($(pgrep -f "gitnexus mcp" 2>/dev/null | sort -n))
if [[ ${#_gn_pids[@]} -gt 1 ]]; then
    _gn_newest="${_gn_pids[$((${#_gn_pids[@]} - 1))]}"
    for _gn_pid in "${_gn_pids[@]}"; do
        if [[ "$_gn_pid" != "$_gn_newest" ]]; then
            kill "$_gn_pid" 2>/dev/null
        fi
    done
    echo "[session-start] reaped $((${#_gn_pids[@]} - 1)) stale gitnexus mcp processes"
fi
unset _gn_pids _gn_newest _gn_pid

# 1c. Auto-purge sentinels older than 14 days (conservative initial threshold).
# Reason: orphan sentinels from crashed review agents block git push (pre-bash-guard.sh)
#         and require manual `rm`. 14d (336h) protects in-progress reviews; Stop hook
#         continues to warn at 24h. Drop to 7d after 1-2 weeks if no false positives.
bash "$(dirname "$0")/reap-stale-sentinels.sh" --purge --threshold-hours 336 || true

# 1d. Cross-CLI mirror drift advisory (.claude/ vs .codex/ / .gemini/).
# minimal profile 跳過（與其他 advisory 一致）。Threshold 1 小時，> threshold 即提醒。
if [[ "$PROFILE" != "minimal" ]]; then
    bash "$ROOT/.claude/scripts/check-cross-cli-drift.sh" || true
fi

# 1e. dhpk plugin 版本 advisory (vs verified-versions.json 範圍)。
# Claude Code 沒有 plugin version pin 語法；以 artifact 比對代替 settings.json pin。
# 安裝版本超出 verified[].range 即 advisory。
if [[ "$PROFILE" != "minimal" ]]; then
    bash "$ROOT/.claude/scripts/check-dhpk-version.sh" || true
fi

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
