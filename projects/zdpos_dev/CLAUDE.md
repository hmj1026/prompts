# zdpos_dev — Project Context

PHP 5.6 + Yii 1.1 legacy POS. Always-on rules for all AI.

## Rule Priority
1. System/Platform constraints
2. Current user request
3. This file (CLAUDE.md)
4. AGENTS.md
5. Other docs

## Communication
- Reply in Traditional Chinese; code comments in Traditional Chinese
- Keep domain terms in English (Controller, Model, View, Action)
- Lead with conclusion, add details after

## Core Rules
- **SSOT**: Extend existing logic, never duplicate
- **Read-before-write**: `rg`/`fd` before coding
- PHP syntax: `.claude/rules/php/coding-style.md`

## Code Exploration & Memory Tools
- **GitNexus hard rules**: `gitnexus_impact` before editing a symbol / `gitnexus_detect_changes` before commit / `gitnexus_rename` for renaming (no find-and-replace); flag HIGH/CRITICAL risk
- **Full routing** (cx / gitnexus / claude-mem / Read / Grep decision tree + costs) → `.claude/rules/tool-routing.md`

## Key References
| Topic | File |
|-------|------|
| Execution strategy + agents | `.claude/rules/execution-policy.md` |
| Tool routing (cx/gitnexus/claude-mem) | `.claude/rules/tool-routing.md` |
| PHP/Yii DDD patterns | `.claude/rules/php/yii-framework.md` |
| 5 deploy environments / SSH / cron / MySQL / log paths | skill `zdpos-environment` (按需載入；觸發詞：cron、SSH、deploy、Cloud SQL、application.log、5 環境差異) |
| Frontend (AJAX, JS) | `.claude/rules/frontend.md` |
| EILogger | `.claude/docs/eilogger.md` |
| Docs writing rules | `.claude/docs/docs-writing.md` |
| Layer governance | `protected/CLAUDE.md`, `domain/CLAUDE.md`, `infrastructure/CLAUDE.md` |
| Page Service pattern | `docs/page-service-pattern.md` |
| Wanpo offline report SOP | `docs/operations/playbooks/wanpo-offline-report.md` (load on-demand: "wanpo offline report" / "salesConsolidate chunk") |
| Artifact contract（agent 落檔規範） | `docs/contracts/artifact-contract.md` (按需查；agent prompt 已內嵌精簡規則) |
