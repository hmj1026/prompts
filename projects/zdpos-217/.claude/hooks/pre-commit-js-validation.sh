#!/usr/bin/env bash
# pre-commit-js-validation.sh — git commit 時的 staged JS lint/typecheck gate
# 攔截 `git commit*` 命令；若 staged diff 命中 `js/**/*.{js,ts}` 則跑 lint + typecheck。
# 失敗 exit 2 → Claude Code 視為 reject，commit 不會發生。
#
# Wiring（2026-06-12 起）：不再直接 wire 在 settings.json PreToolUse(Bash)；
# 改由 pre-bash-guard.sh Pattern 6 偵測到 git commit 時以 stdin 轉送 payload 委派呼叫，
# 避免每次 Bash 呼叫都 spawn 本腳本空轉。單獨測試：echo "$payload" | bash 本檔。
#
# 設計理由：
# - JS 靜態檢查（eslint + tsc --noEmit）是 modernize-zpos-js-static-checks change 的 CI gate；
#   但 CI 是事後驗證、PR 才跑。本 hook 把同樣防線提前到 commit time，避免推上去才知道壞。
# - 只對 staged JS 觸發；無 JS 改動的 commit 不延遲。
# - PHP 不在這跑，PHP 有獨立的 user-level pre-commit hook。
#
# 跳過機制：commit message 含 `[skip-js-lint]` 時不檢查（緊急熱修專用，需配 reviewer 解釋）。

set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"

stdin_data=$(cat 2>/dev/null || true)
[ -z "$stdin_data" ] && exit 0

cmd="$(extract_tool_input command "$stdin_data")"
[ -z "$cmd" ] && exit 0

# 只攔截實際 commit 動作（git commit / git commit -m / git commit --amend 等）。
# `git commit-tree` 是 plumbing（rebase / merge 內部會用），不能誤觸發；先排除掉。
case "$cmd" in
    *"git commit-tree"*) exit 0 ;;
    *"git commit"*) ;;
    *) exit 0 ;;
esac

# 命令字串內明確 skip（PreToolUse hook 看的是命令字串本身；editor-buffer 模式
# `git commit`（無 -m）打開編輯器寫的訊息，hook 此時 *讀不到*，因為命令還沒執行。
# 緊急 skip 寫法：`git commit -m "fix [skip-js-lint]"` —— 把 token 放進 -m 參數。）
if echo "$cmd" | grep -Fq '[skip-js-lint]'; then
    echo "[pre-commit-js] skip-js-lint sentinel found in command; bypassing" >&2
    exit 0
fi

# 必須在 git repo 內
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# 取得 staged 檔案；無變更直接放行
staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -z "$staged" ] && exit 0

# 命中 js/**/*.{js,ts} 才跑
js_hits="$(echo "$staged" | grep -E '^js/.*\.(js|ts)$' || true)"
if [ -z "$js_hits" ]; then
    exit 0
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root" || exit 0

# 沒 node_modules 時 fail-soft 警告（user 環境可能尚未 npm i）；不擋 commit 但要可見。
if [ ! -d node_modules ]; then
    echo "[pre-commit-js] WARN: node_modules missing; skipping lint+typecheck (run 'npm i' to enable gate)" >&2
    exit 0
fi

echo "[pre-commit-js] staged JS detected; running lint + typecheck..." >&2

if ! npm run --silent lint >&2; then
    echo "[pre-commit-js] FAIL: npm run lint failed. Fix errors or add '[skip-js-lint]' to commit msg." >&2
    exit 2
fi

if ! npm run --silent typecheck >&2; then
    echo "[pre-commit-js] FAIL: npm run typecheck failed. Fix errors or add '[skip-js-lint]' to commit msg." >&2
    exit 2
fi

echo "[pre-commit-js] OK: lint + typecheck passed" >&2
exit 0
