# Commands Index (zdpos_dev)

> **Canonical**: `${CLAUDE_PLUGIN_ROOT}/commands/INDEX.md` (dhpk v0.4.0+) — full list of the ~70 dhpk-shipped commands.

## zdpos local commands (kept after dhpk migration)

| Command | Purpose |
|---|---|
| `/update-codemaps` | Scan code structure, generate / update `docs/CODEMAPS/` architecture docs (zdpos-specific Yii 1.1 / PHP 5.6 / DDD layered shape — `protected/`, `domain/`, `infrastructure/`). Different from dhpk's `/update-codemaps` which is framework-agnostic template. |

> `/create-dev` is now a dhpk plugin command (`/dhpk:create-dev`), no longer a zdpos local. It reads
> the generic `dhpk:adaptive-dev-workflow` skill plus this project's `@rules/dev-workflow-project.md`
> delta; `/dhpk:do` also routes substantial bug/feature tasks through it.

## OpenSpec plugin commands

External OpenSpec plugin provides `/opsx:*` (apply / archive / continue / explore / ff / new / onboard / sync / verify / bulk-archive / validate-sync) — installed separately, not managed by dhpk or zdpos.

## All other commands

Provided by dhpk plugin under `dhpk:` namespace. Use `/dhpk:INDEX` to browse the full catalog, or invoke any of the ~70 commands via `/dhpk:<command-name>`.

Recent migration: as of 2026-05-27, zdpos removed 67 duplicate command files in favour of the dhpk-shipped equivalents (Phase A diff: 60 byte-identical, 5 dhpk-more-complete, 2 ported-to-dhpk). See `.claude/artifacts/dhpk-tidy/phase-a-verdicts.md` for the per-pair audit trail.
