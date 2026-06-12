# Agents Index (zdpos_dev)

> **Canonical**: `${CLAUDE_PLUGIN_ROOT}/agents/INDEX.md` (dhpk v0.4.0+) — full role / sentinel / scope table for the dhpk-shipped agents.

## Mandatory chain (sentinel-driven)

zdpos extends dhpk's 5-slot review_agents with a 6th slot:

| Slot | Sentinel | Agent | Trigger source |
|---|---|---|---|
| 0 | `.pending-review` | `dhpk:code-reviewer` | post-edit-remind.sh (PHP / JS / CLAUDE.md) |
| 1 | `.pending-db-review` | `dhpk:database-reviewer` | Repository / migration / model / .sql |
| 2 | `.pending-security-review` | `dhpk:security-reviewer` | controllers / config / auth |
| 3 | `.pending-frontend-review` | `dhpk:frontend-reviewer` | JS / TS / view-layer scripts |
| 4 | `.pending-doc-review` | `dhpk:doc-reviewer` | .claude/{agents,rules,commands,...}/*.md |
| 5 | `.pending-migration-review` | `dhpk:migration-reviewer` | protected/migrations/**/*.php (zdpos local) |

Sentinel mapping SSOT lives in `.claude/hooks/_lib/payload.sh` (`SENTINEL_NAMES` / `SENTINEL_AGENTS` arrays).

## Situational agents (back-stop, AI-judgment)

- `dhpk:tdd-guide` — before any implementation in business layer
- `dhpk:architect` — cross-module / DDD layer design
- `dhpk:performance-analyzer` — Repository methods on hot tables (`records` / `orders` / `stock` / `inventory` / `pay_actions`)
- `dhpk:refactor-cleaner` — files > 800 lines / dedupe / split file
- `dhpk:ui-ux-verifier` — UI/UX vs OpenSpec spec comparison via playwright-cli
- `dhpk:doc-updater` — after structural code changes that affect codemaps

## See also

- `${CLAUDE_PLUGIN_ROOT}/agents/INDEX.md` for the canonical dhpk roster (15 role agents + 1 module-scoped polyfill-reviewer)
- `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` for the full chain rule + dispatch table
