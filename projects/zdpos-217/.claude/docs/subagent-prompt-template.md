# Sub-agent Prompt Boilerplate

Referenced from `rules/tool-routing.md`. Sub-agents do NOT inherit project rules — paste the relevant block into the agent prompt.

## Source-reading agents (Explore, tdd-guide, architect, bug-investigation, etc.)

> "Use `cx overview <file>` before any Read on files >200 lines. Use `cx definition --name X` to read specific functions."

## DB / data-access tasks (any agent that queries, inserts, or updates a table)

> "Before planning any new DB query, check `infrastructure/Repositories/` for an existing Repository that handles the target table. First grep: `grep -rl '<target_table>' infrastructure/Repositories/`; if nothing matches, enumerate via `cx overview infrastructure/Repositories/`. If a Repository is found, new queries go there via `queryBuilder()` — not in the Controller. Existing `createCommand()` in a Controller is legacy debt; presence does NOT permit new violations."

## Extended anti-pattern reference

- `Read --offset/--limit` as a substitute for `cx overview` on files >200 lines — first tool call MUST be `cx overview`. Exception: current session already ran `cx overview` / `cx definition` for the file and needed content is within the listed range.
- Running `gitnexus_impact` for append-only changes — pure method additions (not touching existing symbol body/signature/PHPDoc) have no caller blast radius; skip impact and state "append-only — gitnexus_impact skipped" in the plan/commit. Exemption void once existing method behavior is modified.
- Spawning Explore without cx instructions — sub-agent prompts must include the boilerplate above.
- Entering Edit/Write on an existing symbol without prior `gitnexus_impact` — violates CLAUDE.md hard rule; "local / private / single-caller" is not an excuse.
