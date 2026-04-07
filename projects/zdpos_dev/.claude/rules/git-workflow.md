# Git Rules

Branches: `feat/*` | `fix/*` | `docs/*` | `refactor/*` -> main
Commit: `<type>: <subject>` (feat/fix/docs/refactor/test/chore/perf/ci)

Claude 預設不主動 git add/commit/push/stash，需透過 /smart-commit 或 /precommit 觸發
Claude forbidden: reset --hard | rebase | push --force | clean -f
Claude allowed (read-only): git status | diff | log | branch | rev-parse | show

Prohibited: Push directly to main | Force push to shared branches | Commit containing secrets
PR workflow: Develop -> /codex-review-fast -> /precommit -> /pr-review -> PR
