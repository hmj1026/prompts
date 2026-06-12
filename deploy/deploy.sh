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
    zdpos-217)  project_path="$PROJECTS_ROOT/zdpos-217" ;;
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
    zdpos-217)  project_path="$PROJECTS_ROOT/zdpos-217" ;;
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

  # Deploy .claude/ contents (incl. dotfiles like .gitignore).
  # NOTE: only items present in the SSOT get linked; personal/runtime files
  # (settings.local.json, artifacts/, cache/, worktrees/) live only in the
  # working tree and are never present here, so they are left untouched.
  if [ -d "$src_base/.claude" ]; then
    shopt -s dotglob
    for item in "$src_base/.claude"/*; do
      local name
      name="$(basename "$item")"
      create_symlink "$item" "$project_path/.claude/$name"
    done
    shopt -u dotglob
  fi

  # Deploy root-level files (CLAUDE.md, GEMINI.md, AGENTS.md)
  for f in CLAUDE.md GEMINI.md AGENTS.md; do
    if [ -f "$src_base/$f" ]; then
      create_symlink "$src_base/$f" "$project_path/$f"
    fi
  done

  # Also deploy lib/ resources
  deploy_lib "$project"

  check_pluginconfig_drift "$src_base" "$project_path"
}

# Compare dhpk pluginConfigs.modules between the committed template (settings.json)
# and the real local file (settings.local.json). The dhpk reader only reads
# settings.local.json (no fallback), so silent drift between the two sources
# would otherwise go unnoticed until a "modules=none" banner appears.
check_pluginconfig_drift() {
  local src_settings="$1/.claude/settings.json"
  local local_settings="$2/.claude/settings.local.json"
  [ -f "$src_settings" ] && [ -f "$local_settings" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  local drift
  drift="$(python3 - "$src_settings" "$local_settings" <<'PY'
import json, sys

def mods(path):
    try:
        with open(path) as f:
            d = json.load(f)
        return d.get("pluginConfigs", {}).get("dhpk@dhpk", {}).get("options", {}).get("modules")
    except Exception:
        return None

team, local = mods(sys.argv[1]), mods(sys.argv[2])
if team is not None and local is not None and team != local:
    print("team=%s local=%s" % (team, local))
PY
)"
  if [ -n "$drift" ]; then
    log_warn "pluginConfigs.modules drift: $drift — dhpk 只讀 settings.local.json，請對齊兩處"
  fi
}

# Check a managed project without modifying (mirrors deploy_project)
check_project() {
  local project="$1"
  local project_path

  case "$project" in
    zdpos_dev)  project_path="$PROJECTS_ROOT/zdpos_dev" ;;
    zdpos-217)  project_path="$PROJECTS_ROOT/zdpos-217" ;;
    line-bot)   project_path="$PROJECTS_ROOT/line-bot" ;;
    *)
      log_warn "Project '$project' is self-managed; nothing to check."
      return 0
      ;;
  esac

  local src_base="$REPO_ROOT/projects/$project"

  if [ ! -d "$src_base" ]; then
    log_error "Project not found in repo: $src_base"
    return 1
  fi

  log_info "Checking project: $project -> $project_path"

  if [ -d "$src_base/.claude" ]; then
    shopt -s dotglob
    for item in "$src_base/.claude"/*; do
      check_symlink "$item" "$project_path/.claude/$(basename "$item")"
    done
    shopt -u dotglob
  fi

  for f in CLAUDE.md GEMINI.md AGENTS.md; do
    if [ -f "$src_base/$f" ]; then
      check_symlink "$src_base/$f" "$project_path/$f"
    fi
  done

  check_pluginconfig_drift "$src_base" "$project_path"
}

# Deploy everything
deploy_all() {
  deploy_user
  echo ""

  for project in zdpos_dev zdpos-217 line-bot; do
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
  for project in zdpos_dev zdpos-217 line-bot; do
    check_project "$project"
    echo ""
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

# Pre-scan flags so position doesn't matter（`project zdpos-217 --check` 也能生效）。
# while 迴圈內的 --check/--dry-run case 仍保留消耗 trailing flags（刪掉會落入
# Unknown command exit 1）；pre-scan 與其並存是 defence-in-depth。
for _arg in "$@"; do
  case "$_arg" in
    --check)   CHECK_ONLY=true ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

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
      if $CHECK_ONLY; then
        check_project "$1"
      else
        deploy_project "$1"
      fi
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
