# Rules Archive

This directory contains **archived** language-specific rules that were previously deployed at the user level. They have been superseded by the three-layer architecture.

## Current Architecture

```
prompts/
├── user/.claude/rules/common/    # Active: language-agnostic rules (always loaded)
├── lib/rules/                    # Templates: language-specific rule sets
│   ├── php/
│   ├── python/
│   ├── typescript/
│   └── golang/
└── user/.claude/rules-archive/   # This directory: historical reference only
    ├── php/
    ├── python/
    ├── typescript/
    └── golang/
```

- **`user/.claude/rules/common/`** contains universal principles -- always loaded at user level.
- **`lib/rules/<lang>/`** contains language-specific rule templates. These are deployed to individual projects via `deploy.sh`.
- **This archive** is kept for historical reference. Do not deploy from here.

## Deploying Language Rules to a Project

Use the deployment script instead of manual copying:

```bash
# Deploy shared resources (including language rules) to a project
./deploy/deploy.sh lib zdpos_dev
```

This creates symlinks from `lib/rules/<lang>/` into the project's `.claude/rules/<lang>/`.

## Adding a New Language

1. Create `lib/rules/<lang>/` with these files:
   - `coding-style.md` -- formatting, idioms, error handling
   - `testing.md` -- test framework, coverage, organization
   - `patterns.md` -- language-specific design patterns
   - `hooks.md` -- PostToolUse hooks for linters/formatters
   - `security.md` -- secret management, security scanning
2. Each file should start with:
   ```
   > This file extends [common/xxx.md](../common/xxx.md) with <Language> specific content.
   ```
3. Add the language to `deploy/manifest.yaml` under the target projects.
4. Deploy: `./deploy/deploy.sh lib <project>`

## Rules vs Skills

- **Rules** define standards and checklists that apply broadly (e.g., "80% test coverage").
- **Skills** (`skills/` directory) provide deep, actionable reference material for specific tasks.
