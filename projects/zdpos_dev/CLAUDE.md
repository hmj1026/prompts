# zdpos_dev — Project Context

PHP 5.6 + Yii 1.1 legacy POS. PHP 用 Composer；npm 只用於 JS lint / typecheck / tests.

## Rule priority

1. System / platform constraints
2. Current user request
3. This file (CLAUDE.md)
4. `.claude/rules/*.md` (auto-loaded — local overrides) + `${CLAUDE_PLUGIN_ROOT}/rules/*.md` (dhpk canonical)
5. Other docs (load on demand)

## Communication

- Reply in **Traditional Chinese**; code comments in Traditional Chinese.
- Keep domain terms in English (Controller, Model, View, Action).
- Lead with conclusion; details after.

## Core rules

- **SSOT** — extend existing logic, never duplicate.
- **Read-before-write** — `cx` for definition / overview；編輯前 `gitnexus_impact`；execution flow 用 `gitnexus_query`。完整決策樹 → `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` (dhpk canonical) + `.claude/rules/tool-routing.md` (zdpos overrides).
- **No auto-commit** — invoke `/dhpk:smart-commit` or `/dhpk:precommit`; never auto `git add/commit/push/stash`. See `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` "Git pipeline".
- PHP 5.6 syntax limits → `.claude/rules/php/coding-style.md`.

## Agent skills

### Issue tracker

Issues and specs are tracked as local markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Domain docs

This repository uses a single-context layout. See `docs/agents/domain.md`.

## Key references

| Topic | File |
|---|---|
| Install / leftover hooks / `${CLAUDE_PLUGIN_ROOT}` | `.claude/docs/plugin-and-harness.md` |
| Settings / harness-profile / Stop-hook | `.claude/docs/settings-split.md` |
| Execution strategy + sentinel chain | `${CLAUDE_PLUGIN_ROOT}/rules/execution-policy.md` (canonical) + `.claude/rules/execution-policy.md` (zdpos overrides) |
| Tool routing (cx / gitnexus / claude-mem) | `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` + `.claude/rules/tool-routing.md` |
| Anti-rationalization patterns | `${CLAUDE_PLUGIN_ROOT}/rules/anti-rationalization.md` + `.claude/rules/anti-rationalization.md` |
| Sub-agent prompt boilerplate (cx + DB) | `.claude/docs/subagent-prompt-template.md` |
| Agent roster | `${CLAUDE_PLUGIN_ROOT}/agents/INDEX.md` + `.claude/agents/INDEX.md` |
| Commands catalog | `${CLAUDE_PLUGIN_ROOT}/commands/INDEX.md` + `.claude/commands/INDEX.md` |
| MCP server inventory (gitnexus / context7 / codex / claude-mem) | `.claude/docs/mcp-servers.md` |
| PHP / Yii / DDD patterns | `.claude/rules/php/{yii-framework,patterns,coding-style,testing,security}.md` |
| Frontend (AJAX, JS) | `.claude/rules/frontend.md` |
| Environment 座標（主機／碼基／帳號／MySQL） | skill `zdpos-environment` |
| EILogger / docs writing | `.claude/docs/{eilogger,docs-writing}.md` |
| Layer governance | `protected/CLAUDE.md`, `domain/CLAUDE.md`, `infrastructure/CLAUDE.md` |
| Page Service pattern | `docs/guides/page-service-pattern.md` |
| Wanpo offline report SOP | `docs/operations/playbooks/wanpo-offline-report.md` (on demand) |
| Artifact contract (agent file spec) | `docs/contracts/artifact-contract.md` (on demand) |

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **zdpos-217** (90145 symbols, 229751 relationships, 300 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/zdpos-217/context` | Codebase overview, check index freshness |
| `gitnexus://repo/zdpos-217/clusters` | All functional areas |
| `gitnexus://repo/zdpos-217/processes` | All execution flows |
| `gitnexus://repo/zdpos-217/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
