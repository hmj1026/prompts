#!/usr/bin/env bash
set -euo pipefail

# Prompts Deployment Script
# Creates symlinks from this repo to target locations.
# Usage:
#   ./deploy/deploy.sh user              Deploy user-level configs to ~/.claude/
#   ./deploy/deploy.sh project <name>    Deploy a managed project
#   ./deploy/deploy.sh lib <name>        Deploy lib/ skills+commands to a project
#   ./deploy/deploy.sh all               Deploy everything
#   ./deploy/deploy.sh --check           Check sync status (no changes)
#   ./deploy/deploy.sh --dry-run <cmd>   Show what would happen

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN=false
CHECK_ONLY=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_dry()   { echo -e "${YELLOW}[DRY-RUN]${NC} $*"; }

# Detect platform
detect_platform() {
  case "$(uname -s)" in
    Linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    Darwin*) echo "macos" ;;
    *)       echo "unknown" ;;
  esac
}

PLATFORM="$(detect_platform)"

# Expand ~ to $HOME
expand_path() {
  echo "${1/#\~/$HOME}"
}

# Platform-aware base paths
# Override these for non-standard mount points (e.g. different machines)
case "$PLATFORM" in
  wsl|linux) PROJECTS_ROOT="$(expand_path "~/projects")" ;;
  macos)     PROJECTS_ROOT="$(expand_path "~/projects")" ;;
  *)         PROJECTS_ROOT="$(expand_path "~/projects")" ;;
esac
USER_CLAUDE_TARGET="$(expand_path "~/.claude")"

# Create a symlink, handling existing files/links
create_symlink() {
  local src="$1"
  local dst="$2"

  if [ ! -e "$src" ]; then
    log_error "Source not found: $src"
    return 1
  fi

  local dst_dir
  dst_dir="$(dirname "$dst")"

  if $DRY_RUN; then
    if [ -L "$dst" ]; then
      local current
      current="$(readlink "$dst")"
      if [ "$current" = "$src" ]; then
        log_ok "(dry) Already linked: $dst"
      else
        log_dry "Would relink: $dst -> $src (currently -> $current)"
      fi
    elif [ -e "$dst" ]; then
      log_dry "Would backup and link: $dst -> $src"
    else
      log_dry "Would create: $dst -> $src"
    fi
    return 0
  fi

  mkdir -p "$dst_dir"

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      log_ok "Already linked: $(basename "$dst")"
      return 0
    fi
    rm "$dst"
    log_info "Relinked: $(basename "$dst")"
  elif [ -e "$dst" ]; then
    mv "$dst" "${dst}.bak.$(date +%Y%m%d%H%M%S)"
    log_warn "Backed up existing: $(basename "$dst")"
  fi

  ln -s "$src" "$dst"
  log_ok "Linked: $(basename "$dst") -> $src"
}

# Check a symlink without modifying
check_symlink() {
  local src="$1"
  local dst="$2"
  local label="${3:-$(basename "$dst")}"

  if [ ! -e "$src" ]; then
    log_error "Missing source: $src"
    return 1
  fi

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      log_ok "$label"
    else
      log_warn "$label -> $current (expected $src)"
    fi
  elif [ -e "$dst" ]; then
    log_warn "$label exists but is NOT a symlink (file/dir)"
  else
    log_error "$label missing"
  fi
}

# Deploy user-level configs
deploy_user() {
  log_info "Deploying user-level configs to $USER_CLAUDE_TARGET/"
  local src_base="$REPO_ROOT/user/.claude"
  local dst_base="$USER_CLAUDE_TARGET"

  local items=(
    CLAUDE.md
    CX.md
    settings.json
    statusline.sh
    commands
    rules
    rules-archive
    scripts
  )

  for item in "${items[@]}"; do
    create_symlink "$src_base/$item" "$dst_base/$item"
  done

  # Skills (individual, not the whole dir)
  create_symlink "$src_base/skills/claude-health" "$dst_base/skills/claude-health"
}

# Check user-level sync status
check_user() {
  log_info "Checking user-level sync status..."
  local src_base="$REPO_ROOT/user/.claude"
  local dst_base="$USER_CLAUDE_TARGET"

  local items=(
    CLAUDE.md
    CX.md
    settings.json
    statusline.sh
    commands
    rules
    rules-archive
    scripts
  )

  for item in "${items[@]}"; do
    check_symlink "$src_base/$item" "$dst_base/$item"
  done

  check_symlink "$src_base/skills/claude-health" "$dst_base/skills/claude-health"
}

# Deploy lib/ skills and commands to a project
deploy_lib() {
  local project="$1"
  local project_path

  case "$project" in
    zdpos_dev)  project_path="$PROJECTS_ROOT/zdpos_dev" ;;
    ccas)       project_path="$PROJECTS_ROOT/ccas" ;;
    docker_run) project_path="$PROJECTS_ROOT/docker_run" ;;
    line-bot)   project_path="$PROJECTS_ROOT/line-bot" ;;
    *)
      log_error "Unknown project: $project"
      return 1
      ;;
  esac

  log_info "Deploying lib/ to $project..."

  # Shared skills (check manifest for which projects get which)
  case "$project" in
    zdpos_dev|ccas)
      for skill in bug-investigation software-architecture; do
        create_symlink "$REPO_ROOT/lib/skills/$skill" "$project_path/.claude/skills/$skill"
      done
      ;;
  esac

  if [ "$project" = "zdpos_dev" ]; then
    create_symlink "$REPO_ROOT/lib/skills/git-smart-commit" "$project_path/.claude/skills/git-smart-commit"
  fi
}

# Deploy a managed project
deploy_project() {
  local project="$1"
  local project_path

  case "$project" in
    zdpos_dev)  project_path="$PROJECTS_ROOT/zdpos_dev" ;;
    line-bot)   project_path="$PROJECTS_ROOT/line-bot" ;;
    *)
      log_warn "Project '$project' is self-managed. Use 'deploy.sh lib $project' for shared resources."
      return 0
      ;;
  esac

  local src_base="$REPO_ROOT/projects/$project"

  if [ ! -d "$src_base" ]; then
    log_error "Project not found in repo: $src_base"
    return 1
  fi

  log_info "Deploying project: $project -> $project_path"

  # Deploy .claude/ contents
  if [ -d "$src_base/.claude" ]; then
    for item in "$src_base/.claude"/*; do
      local name
      name="$(basename "$item")"
      create_symlink "$item" "$project_path/.claude/$name"
    done
  fi

  # Deploy root-level files (CLAUDE.md, GEMINI.md, AGENTS.md)
  for f in CLAUDE.md GEMINI.md AGENTS.md; do
    if [ -f "$src_base/$f" ]; then
      create_symlink "$src_base/$f" "$project_path/$f"
    fi
  done

  # Also deploy lib/ resources
  deploy_lib "$project"
}

# Deploy everything
deploy_all() {
  deploy_user
  echo ""

  for project in zdpos_dev line-bot; do
    deploy_project "$project"
    echo ""
  done

  for project in ccas docker_run; do
    deploy_lib "$project"
    echo ""
  done
}

# Check all sync status
check_all() {
  check_user
  echo ""
  log_info "Checking projects..."
  for project_dir in "$REPO_ROOT/projects"/*/; do
    local project
    project="$(basename "$project_dir")"
    log_info "  Project: $project"
  done
}

# Parse arguments
if [ $# -eq 0 ]; then
  echo "Usage: $0 [--dry-run] [--check] <command> [args]"
  echo ""
  echo "Commands:"
  echo "  user              Deploy user-level configs to ~/.claude/"
  echo "  project <name>    Deploy a managed project"
  echo "  lib <name>        Deploy lib/ skills+commands to a project"
  echo "  all               Deploy everything"
  echo ""
  echo "Flags:"
  echo "  --check           Check sync status without changes"
  echo "  --dry-run         Show what would happen"
  echo ""
  echo "Platform: $PLATFORM"
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --check)
      CHECK_ONLY=true
      shift
      ;;
    user)
      if $CHECK_ONLY; then
        check_user
      else
        deploy_user
      fi
      shift
      ;;
    project)
      shift
      if [ $# -eq 0 ]; then
        log_error "Missing project name"
        exit 1
      fi
      deploy_project "$1"
      shift
      ;;
    lib)
      shift
      if [ $# -eq 0 ]; then
        log_error "Missing project name"
        exit 1
      fi
      deploy_lib "$1"
      shift
      ;;
    all)
      if $CHECK_ONLY; then
        check_all
      else
        deploy_all
      fi
      shift
      ;;
    *)
      log_error "Unknown command: $1"
      exit 1
      ;;
  esac
done
