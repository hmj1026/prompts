# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Central source of truth for all AI tool configurations (Claude, Gemini, Codex). Contains no executable application code -- only Markdown configs, shell scripts (hooks/deploy), and YAML manifests. All changes are deployed via symlinks to target locations.

## Commands

```bash
# Deploy user-level configs to ~/.claude/
./deploy/deploy.sh user

# Deploy a fully-managed project (copies .claude/ + root *.md files + lib/)
./deploy/deploy.sh project zdpos_dev

# Deploy only shared lib/ resources to a self-managed project
./deploy/deploy.sh lib ccas

# Deploy everything (user + all managed projects + lib for self-managed)
./deploy/deploy.sh all

# Check sync status (no changes made)
./deploy/deploy.sh --check all

# Dry run (preview what would happen)
./deploy/deploy.sh --dry-run all
```

Optional: `markdownlint` for Markdown validation. No build system, no test suite.

## Three-Layer Architecture

```
user/       -> ~/.claude/              Global baseline (rules, hooks, commands, settings)
lib/        -> <project>/.claude/      Shared skills, commands, language rule templates
projects/   -> ~/projects/<name>/      Per-project agents, rules, docs, overrides
```

**Precedence**: project-level overrides user-level when same-named resources conflict.

### Deployment Flow

`deploy.sh` reads hardcoded mappings (not `manifest.yaml` at runtime) to create symlinks. `manifest.yaml` is the declarative intent document -- keep it in sync when adding new symlinks to `deploy.sh`.

### Project Management Modes

| Mode | Meaning | Deploy command |
|------|---------|----------------|
| **managed** | This repo owns the project's `.claude/` | `deploy.sh project <name>` |
| **self** | Project's own git repo owns `.claude/` | `deploy.sh lib <name>` (shared resources only) |

Current projects: `zdpos_dev` (managed, PHP/Yii), `line-bot` (managed, Laravel), `ccas` (self, Python/TS), `docker_run` (self, Docker).

## Key Architecture Decisions

**Hook dispatcher pattern**: Global hooks in `user/.claude/scripts/hooks/` use dispatchers (`dispatch-write.sh`, `dispatch-edit.sh`, `dispatch-bash-pre.sh`) that source `_lib/detect-project.sh` to detect project language/framework, then call only relevant language-specific hooks. Hook wiring lives in `user/.claude/settings.json`.

**Agent templates vs deployed agents**: `user/.claude/agents/` is a reference library of generic agent prompts (architect, tdd-guide, security-reviewer, etc.). These are NOT deployed to `~/.claude/agents/`. Project-level agents in `projects/<name>/.claude/agents/` are the ones actually deployed and may use project-specific names.

**Language rules are templates**: `lib/rules/{php,python,typescript,golang}/` are templates copied (via symlink) into project `.claude/rules/` directories. User-level rules (`user/.claude/rules/`) only contain `common/` (language-agnostic).

## Editing Conventions

- Default communication language: Traditional Chinese (zh-TW) for project docs targeting zh-TW users; English for structural/technical files
- File naming: `CLAUDE.md`, `GEMINI.md`, `AGENTS.md` (uppercase). Workflow files use `lower_snake_case`
- When adding a new project: create `projects/<name>/`, add model-specific files, update `deploy.sh` case statements AND `manifest.yaml`
- When adding a new lib skill: create `lib/skills/<name>/`, add target projects in both `deploy.sh` (`deploy_lib` function) and `manifest.yaml`
- When adding a new hook: add the script in `user/.claude/scripts/hooks/<lang>/`, register it in the appropriate dispatcher, and ensure Write/Edit matchers have parity
