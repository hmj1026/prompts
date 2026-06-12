# Tool Routing

> **Canonical**: `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` (dhpk v0.4.0+) — read that for the cx / gitnexus / claude-mem / Read / Grep decision tree, tie-breakers, and `gitnexus_impact` timing rules.

## zdpos additions

- **claude-mem**: zdpos runs claude-mem MCP. The session-start hook auto-matches context; for explicit lookups: `claude-mem smart_search "<module or symbol>"` before spawning Explore agents.
- **gitnexus index name**: `zdpos_dev`. Resources reachable at `gitnexus://repo/zdpos_dev/{context,clusters,processes,process/<name>}`. If a tool warns the index is stale → `npx gitnexus analyze` first.
- **Sub-agent prompt template**: zdpos has a local copy at `.claude/docs/subagent-prompt-template.md` with project-specific source-reading boilerplate (DDD layer paths, Yii framework path, MySQL container) — paste the relevant block into every Explore / specialist agent prompt.

## Cross-references

- `${CLAUDE_PLUGIN_ROOT}/rules/tool-routing.md` — canonical decision tree
- `dhpk:tool-routing` skill — longer prose version with examples
- `.claude/docs/subagent-prompt-template.md` — zdpos sub-agent prompt boilerplate
