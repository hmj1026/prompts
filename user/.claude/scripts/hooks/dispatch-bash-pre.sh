#!/bin/bash
# dispatch-bash-pre.sh -- PreToolUse Bash dispatcher
# Detects project attributes and runs only relevant pre-command checks.
set -o pipefail

COMMAND="$1"
[[ -z "$COMMAND" ]] && exit 0

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HOOKS_DIR/_lib/detect-project.sh"

# -- Docker container check (only if project uses Docker) --
if [[ -n "$DOCKER_CONTAINER" ]]; then
    if echo "$COMMAND" | grep -qE '(docker|mysql)'; then
        if ! docker ps 2>/dev/null | grep -q "$DOCKER_CONTAINER"; then
            echo "WARNING: Docker container ($DOCKER_CONTAINER) is not running"
        fi
    fi
fi

# -- Docker exec -i flag check (WSL only, PHP projects that use docker exec for tests) --
if [[ -n "$WSL_DISTRO_NAME" ]] && $HAS_PHP; then
    if echo "$COMMAND" | grep -qE 'docker exec' && ! echo "$COMMAND" | grep -qE 'docker exec[^|]*-i'; then
        echo "WARNING: docker exec missing -i flag, may cause stdin hang on WSL"
    fi
fi

exit 0
