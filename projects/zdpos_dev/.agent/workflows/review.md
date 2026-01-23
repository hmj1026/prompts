---
description: Code review following team standards
execution_mode: STRICT_MANDATORY
fallback_allowed: false
---

# Code Review Workflow (Strict Mode)

> ⚠️ **CRITICAL RULES FOR AI ASSISTANTS**:
> 1. This workflow **MUST** be executed step-by-step **WITHOUT EXCEPTION**
> 2. You are **PROHIBITED** from performing manual code review
> 3. You **MUST** use CLI tools (gemini/codex) for all reviews
> 4. If all CLIs fail, you **MUST** stop and ask user for guidance
> 5. **DO NOT** bypass this workflow by viewing files directly

---

## Execution Rules

### ✅ MUST DO
- Execute **EVERY** step in sequence (Step 0 → Step 8)
- Use **ONLY** the specified CLI tools (gemini/codex)
- Stop immediately if prerequisite checks fail
- Log routing decision and reasoning

### ❌ MUST NOT DO
- Skip any workflow steps
- Perform manual code analysis
- Create custom review reports (unless CLI fails)
- Use `view_file`, `view_file_outline`, or `grep_search` for reviewing
- Proceed without functional CLI tools

---

## Step 0: Environment Check

Verify we're in a git repository:

```bash
git rev-parse --git-dir 2>/dev/null || echo "NOT_A_GIT_REPO"
```

**Success Criteria**: Output contains `.git`

**On Failure**: 
```
STOP workflow immediately.
Report to user: "This directory is not a git repository. Code review requires git. Please initialize with `git init` or navigate to a repository."
```

---

## Step 1: Prerequisites Check

Verify both CLIs are available:

```bash
# Check for Gemini CLI (Windows: use 'where', Linux/Mac: use 'which')
where gemini 2>/dev/null || which gemini 2>/dev/null || echo "GEMINI_NOT_FOUND"

# Check for Codex CLI
where codex 2>/dev/null || which codex 2>/dev/null || echo "CODEX_NOT_FOUND"
```

**Success Criteria**: At least one CLI is found

**If neither CLI is found**: 
```
STOP workflow immediately.
Report to user: "No code review CLI found. Please install at least one:
- Gemini CLI: npm install -g @google/generative-ai-cli
- Codex CLI: npm install -g @openai/codex-cli

Cannot proceed with code review."
```

**If only one CLI available**: Use that CLI (no routing needed, skip to Step 6)

**If both available**: Proceed with routing analysis (Step 2-5)

---

## Step 2: Analyze Git Diff

Gather diff statistics to determine review scope:

```bash
# Get diff stats (staged + unstaged changes)
git --no-pager diff --stat HEAD 2>/dev/null || git --no-pager diff --stat

# Count changed files
git --no-pager diff --name-only HEAD 2>/dev/null | wc -l

# Count total changed lines (added + removed)
git --no-pager diff --numstat HEAD 2>/dev/null | awk '{added+=$1; removed+=$2} END {print added+removed}'
```

**Success Criteria**: File count > 0

**If no changes detected**:
```
STOP workflow.
Report to user: "No uncommitted changes found. Nothing to review."
```

---

## Step 3: Calculate Complexity Score

**MANDATORY**: Follow this scoring table exactly.

Initialize `complexity_score = 0`, then **ADD** points for each matching condition:

| Condition | Points | Detection Method |
|-----------|--------|------------------|
| Files changed > 10 | +2 | Count from `git diff --name-only` |
| Files changed > 20 | +3 (additional, total +5) | Same as above |
| Lines changed > 300 | +2 | Sum from `git diff --numstat` |
| Lines changed > 500 | +3 (additional, total +5) | Same as above |
| Multiple directories | +1 | Count unique dirs in changed paths |
| Test files included | +1 | Files matching `*test*`, `*spec*` |
| Config files changed | +1 | `*.config.*`, `*.json`, `*.yaml`, `*.yml`, `*.toml` |
| Database/schema changes | +2 | `*migration*`, `*schema*`, `*.sql`, `prisma/*` |
| API route changes | +2 | Files in `api/`, `routes/`, matching `endpoint`, `handler` |
| Service layer changes | +2 | Files in `services/`, `*service*`, `*provider*` |

**Example Calculation**:
```
Files: 15 (>10) → +2
Lines: 420 (>300) → +2
Security patterns: found → +3
Total: 7/10
```

---

## Step 4: Detect Language & Framework

Analyze file extensions and patterns in the diff:

### Primary Language
```
.ts, .tsx     → TypeScript
.js, .jsx     → JavaScript
.py           → Python
.php          → PHP
.go           → Go
.java         → Java
```

### Security-Sensitive Patterns
Check diff content for:
```
- File paths: **/auth/**, **/security/**, **/*authentication*
- Code patterns: "password", "api_key", "secret", "Bearer", "JWT"
- Config files: .env*, *credentials*, *secrets*
```

If security patterns found → **Automatically route to Codex**

---

## Step 5: Apply Routing Decision Tree

**MANDATORY**: Evaluate in this exact order, **first match wins**:

### Priority 1: Pattern-Based Rules (Hard Rules)

| Pattern | Route | Reason |
|---------|-------|--------|
| Security-sensitive files/code detected | **Codex** | Requires careful security analysis |
| Files > 20 OR lines > 500 | **Codex** | Large changeset needs thorough review |
| Database migrations or schema changes | **Codex** | Architectural risk |
| API/service layer modifications | **Codex** | Backend architectural changes |
| Changes span 3+ top-level directories | **Codex** | Multi-service impact |
| Pure frontend only (jsx/tsx/vue/css/html) | **Gemini** | Simpler, visual-focused review |
| Python ecosystem (py, Django, FastAPI) | **Gemini** | Strong Python support |
| Documentation only (md/txt/rst) | **Gemini** | Simple text review |

### Priority 2: Complexity Score (if no pattern matched)

| Score | Route | Reason |
|-------|-------|--------|
| ≥ 6 | **Codex** | High complexity warrants deeper analysis |
| < 6 | **Gemini** | Moderate complexity, prefer speed |

### Priority 3: Default

→ **Gemini** (faster feedback loop for unclear cases)

**CHECKPOINT**: Before proceeding to Step 6, you **MUST** output:

```markdown
## Code Review Routing

**Changes detected:**
- Files: [X] files changed
- Lines: [Y] lines modified
- Primary language: [language]
- Framework: [framework or "none detected"]

**Complexity score**: [N]/10
- [List contributing factors, e.g., "Files > 10 (+2)", "Security patterns (+3)"]

**Routing decision**: [Gemini/Codex]
- **Reason**: [Primary reason for choice from decision tree]

**Executing review...**
```

---

## Step 6: Execute Review

**MANDATORY**: Use the **EXACT** command format below based on routing decision.

### If Gemini Selected:

// turbo
```bash
# Pipe diff to Gemini CLI with review prompt
git --no-pager diff HEAD | gemini -p "Review this code diff for: 1) Code quality issues, 2) Best practices violations, 3) Potential bugs, 4) Security concerns, 5) Performance issues. Provide specific, actionable feedback organized by severity (Critical, High, Medium, Low)."
```

### If Codex Selected:

// turbo
```bash
# Use dedicated review subcommand for non-interactive review
codex review --uncommitted
```

**Success Criteria**: Command exits with code 0 and produces output

---

## Step 7: Handle Failures with Fallback

**Trigger**: Primary CLI failed (non-zero exit code or error output)

### Fallback Strategy:

1. **Report the failure**:
```markdown
⚠️ [Primary CLI] failed with error:
[error message from stderr]

Attempting fallback to [alternative CLI]...
```

2. **Try the alternative CLI** (if available)

3. **If fallback also fails**:
```markdown
❌ Both review CLIs failed:

**Gemini error**: [error message]
**Codex error**: [error message]

Code review cannot proceed. Please:
1. Check CLI installations are up-to-date
2. Verify network connectivity (if CLIs need API access)
3. Try manually:
   - Gemini: `git diff HEAD | gemini -p "review this code"`
   - Codex: `codex review --uncommitted`

**PROHIBITED**: I cannot perform manual review as a fallback.
```

**STOP workflow** - Do not attempt manual file review.

---

## Step 8: Format Output

Present the CLI review results exactly as follows:

```markdown
## Code Review Results

**Reviewed by**: [Gemini/Codex]  
**Routing**: [Brief reason why this CLI was selected]

---

[Insert CLI output verbatim here - DO NOT modify or reformat]

---

**Review complete**
- Files analyzed: [X]
- Lines changed: [Y]
- Complexity score: [N]/10
```

**DO NOT**:
- Add your own analysis or commentary
- Reorganize the CLI's findings
- Create additional severity classifications
- Supplement with manual code inspection

---

## Quick Reference: Routing Examples

| Change Type | Files | Lines | Route | Reason |
|-------------|-------|-------|-------|--------|
| React component styling | 3 | 80 | **Gemini** | Pure frontend, low complexity |
| Django view update | 5 | 120 | **Gemini** | Python ecosystem |
| Single bug fix | 1 | 40 | **Gemini** | Simple change (score < 6) |
| New API endpoint + tests | 8 | 350 | **Codex** | API change pattern |
| Auth system changes | 4 | 200 | **Codex** | Security-sensitive |
| Database migration | 2 | 100 | **Codex** | Schema change |
| Multi-service refactor | 25 | 800 | **Codex** | Files > 20 |
| TypeScript type overhaul | 12 | 450 | **Codex** | High complexity (score ≥ 6) |

---

## Verification Checklist

Before completing this workflow, confirm:

- [ ] ✅ Executed ALL steps sequentially (0→8)
- [ ] ✅ Used CLI tool (gemini or codex), not manual analysis
- [ ] ✅ Logged routing decision with reasoning
- [ ] ✅ Did NOT create custom review report (just formatted CLI output)
- [ ] ✅ Stopped at failures without bypassing to manual review
- [ ] ✅ If both CLIs failed, reported to user and stopped

---

## Notes for Future Improvements

- Consider adding support for incremental reviews (review only specific commits)
- Add caching mechanism to avoid re-reviewing unchanged code
- Integrate with CI/CD pipelines for automated reviews
- Support custom review templates per project type