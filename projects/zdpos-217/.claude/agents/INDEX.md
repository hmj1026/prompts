# Agents Index (zdpos_dev)

> **Canonical**: `${CLAUDE_PLUGIN_ROOT}/agents/INDEX.md` (dhpk v0.4.0+) — full role / sentinel / scope table for the dhpk-shipped agents.

## Mandatory chain (sentinel-driven)

dhpk v0.10.0 起為官方 7 槽（migration 已升格，zdpos 不再需要本地擴充槽）：

| Slot | Sentinel | Agent | Trigger source |
|---|---|---|---|
| 0 | `.pending-review` | `dhpk:code-reviewer` | plugin post-edit-remind.sh (PHP / JS / CLAUDE.md) |
| 1 | `.pending-db-review` | `dhpk:database-reviewer` | Repository / migration / model / .sql |
| 2 | `.pending-security-review` | `dhpk:security-reviewer` | controllers / config / auth |
| 3 | `.pending-frontend-review` | `dhpk:frontend-reviewer` | JS / TS / view-layer scripts（js module triggers） |
| 4 | `.pending-doc-review` | `dhpk:doc-reviewer` | .claude/{agents,rules,commands,...}/*.md |
| 5 | `.pending-polyfill-review` | `dhpk:polyfill-reviewer` | library-author module（zdpos 未啟用，槽位保留） |
| 6 | `.pending-migration-review` | `dhpk:migration-reviewer` | yii-1.1 module triggers + `mig:protected/migrations/` extra path |

Sentinel mapping SSOT lives in the plugin's `${CLAUDE_PLUGIN_ROOT}/scripts/hooks/_lib/payload.sh`; the local `.claude/hooks/_lib/payload.sh` is an order-mirroring copy for statusline / remaining local hooks.

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
