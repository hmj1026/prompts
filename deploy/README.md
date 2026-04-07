# Deployment

Manages symlinks from this repo to target locations.

## Quick Start

```bash
# Check current sync status
./deploy/deploy.sh --check all

# Deploy user-level configs
./deploy/deploy.sh user

# Deploy a managed project
./deploy/deploy.sh project zdpos_dev

# Deploy shared lib resources to a self-managed project
./deploy/deploy.sh lib ccas

# Deploy everything
./deploy/deploy.sh all

# Dry run (show what would happen)
./deploy/deploy.sh --dry-run all
```

## Architecture

```
prompts repo                    target location
-----------                     ---------------
user/.claude/*          ->      ~/.claude/*
lib/skills/<skill>      ->      ~/projects/<project>/.claude/skills/<skill>
lib/commands/opsx       ->      ~/projects/<project>/.claude/commands/opsx
projects/<name>/.claude ->      ~/projects/<name>/.claude/
projects/<name>/*.md    ->      ~/projects/<name>/*.md
```

## Project Management Modes

| Mode | Description | Deploy Command |
|------|-------------|----------------|
| **managed** | prompts repo is source of truth | `deploy.sh project <name>` |
| **self** | project's own git repo owns .claude/ | `deploy.sh lib <name>` (shared resources only) |

## Platform Support

Tested on WSL and macOS. Uses `ln -s` for symlinks.
On WSL, ensure Developer Mode is enabled or run from an elevated shell.

## Conflict Handling

- Existing symlinks pointing elsewhere are relinked
- Existing files/dirs are backed up with `.bak.<timestamp>` suffix
- Use `--check` to identify drift before deploying
