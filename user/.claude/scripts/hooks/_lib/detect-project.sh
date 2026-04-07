#!/bin/bash
# detect-project.sh -- Detect project language/framework attributes
# Usage: source ~/.claude/scripts/hooks/_lib/detect-project.sh
# All detection is based on marker files; no hardcoded paths.

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# -- Language detection --
# Check root and immediate subdirectories (monorepo support)
HAS_PYTHON=false
if [[ -f "$PROJECT_ROOT/pyproject.toml" || -f "$PROJECT_ROOT/setup.py" || -f "$PROJECT_ROOT/setup.cfg" ]]; then
    HAS_PYTHON=true
elif find "$PROJECT_ROOT" -maxdepth 2 -name "pyproject.toml" -o -name "setup.py" 2>/dev/null | head -1 | grep -q .; then
    HAS_PYTHON=true
fi

HAS_PHP=false
[[ -f "$PROJECT_ROOT/composer.json" || -d "$PROJECT_ROOT/protected" ]] && HAS_PHP=true

HAS_NODE=false
if [[ -f "$PROJECT_ROOT/package.json" ]]; then
    HAS_NODE=true
elif find "$PROJECT_ROOT" -maxdepth 2 -name "package.json" 2>/dev/null | head -1 | grep -q .; then
    HAS_NODE=true
fi

# -- Framework detection --
HAS_YII=false
$HAS_PHP && [[ -d "$PROJECT_ROOT/protected/config" ]] && HAS_YII=true

HAS_FASTAPI=false
if $HAS_PYTHON; then
    if grep -rq "fastapi" "$PROJECT_ROOT"/pyproject.toml "$PROJECT_ROOT"/*/pyproject.toml 2>/dev/null; then
        HAS_FASTAPI=true
    fi
fi

# -- Docker container name detection --
DOCKER_CONTAINER=""
for compose_file in "$PROJECT_ROOT/docker-compose.yaml" "$PROJECT_ROOT/docker-compose.yml"; do
    if [[ -f "$compose_file" ]]; then
        DOCKER_CONTAINER=$(grep -m1 'container_name:' "$compose_file" 2>/dev/null | awk '{print $2}' | tr -d '"' | tr -d "'")
        break
    fi
done

# -- Python backend directory detection --
# Supports flat layout (pyproject.toml at root) and subdirectory layout (backend/)
PYTHON_BACKEND_DIR=""
if $HAS_PYTHON; then
    if [[ -f "$PROJECT_ROOT/pyproject.toml" ]]; then
        PYTHON_BACKEND_DIR="$PROJECT_ROOT"
    elif [[ -f "$PROJECT_ROOT/backend/pyproject.toml" ]]; then
        PYTHON_BACKEND_DIR="$PROJECT_ROOT/backend"
    fi
fi

export PROJECT_ROOT HAS_PYTHON HAS_PHP HAS_NODE
export HAS_YII HAS_FASTAPI
export DOCKER_CONTAINER PYTHON_BACKEND_DIR
