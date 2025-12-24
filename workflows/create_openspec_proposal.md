1.  **Read and Analyze Request**:
    - Understand the user's goal (Bug fix? New feature? Refactor?).
    - Determine if an OpenSpec proposal is needed (Yes for features/complex bugs, No for typos).

2.  **Context Discovery**:
    - Read `openspec/project.md` and `openspec/AGENTS.md` for guidelines.
    - Check existing specs: `openspec spec list --long`.
    - Check active changes: `openspec list`.

3.  **Plan and Scaffold**:
    - Choose a unique `change-id` (e.g., `YYYY-MM-DD-verb-noun`).
    - Create directory: `mkdir -p openspec/changes/<change-id>/specs/<capability>`.
    - Create `proposal.md`: Define Why, What, Impact.
    - Create `tasks.md`: Plan implementation steps.
    - Create spec delta: `openspec/changes/<change-id>/specs/<capability>/spec.md`.

4.  **Draft Specification**:
    - Write requirements in `spec.md` using `## ADDED/MODIFIED/REMOVED Requirements`.
    - **MUST** include at least one `#### Scenario:` per requirement.

5.  **Validate**:
    - Run `openspec validate <change-id> --strict`.
    - Fix any errors reported by the tool.

6.  **Review (APPROVAL GATE)**:
    - Notify user for approval of the proposal and specs.
    - **CRITICAL**: Set `ShouldAutoProceed: false` when calling notify_user.
    - **DO NOT** proceed to implementation until user explicitly replies "Approve" or "同意".
    - Comments like "LGTM" are NOT sufficient - wait for explicit approval text.