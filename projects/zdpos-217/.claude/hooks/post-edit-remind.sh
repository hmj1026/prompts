#!/usr/bin/env bash
# post-edit-remind.sh — PostToolUse (Edit/Write/MultiEdit) hook
#
# SSOT for review-agent triggers. execution-policy.md references this file.
# Whitelist-style detection writes one or more sentinels per Edit.
#
# Slot layout matches _lib/payload.sh SENTINEL_NAMES:
#   0 = .pending-review              → dhpk:code-reviewer
#   1 = .pending-db-review           → dhpk:database-reviewer
#   2 = .pending-security-review     → dhpk:security-reviewer
#   3 = .pending-frontend-review     → dhpk:frontend-reviewer
#   4 = .pending-doc-review          → dhpk:doc-reviewer
#   5 = .pending-migration-review    → dhpk:migration-reviewer
#
# Triggers (path patterns are relative to repo root):
#   dhpk:code-reviewer (slot 0) — code final gate:
#     - *.php (any location)
#     - *.js / *.ts NOT in js/ (one-off PHP-adjacent script edits)
#     - **/CLAUDE.md                  ← top-level governance docs that affect dispatch
#     - .claude/hooks/**/*.sh / .claude/scripts/**/*.sh ← shell logic that gates code
#   dhpk:doc-reviewer (slot 4) — doc final gate (lightweight, Haiku):
#     - .claude/{agents,rules,commands,skills,manifests}/**/*.{md,json,yml,yaml}
#       (note: code-affecting .sh in hooks/scripts stays with code-reviewer above)
#     - .claude/{hooks,scripts}/**/*.{md,json,yml,yaml}  ← doc-only files alongside scripts
#   dhpk:database-reviewer (slot 1):
#     - infrastructure/Repositories/**/*.php
#     - protected/migrations/**/*.php
#     - protected/models/**/*.php        ← AR schema changes
#     - **/*.sql
#   dhpk:migration-reviewer (slot 5):
#     - protected/migrations/**/*.php    ← migration-specific safety audit
#       (執行於 db-reviewer 之後；後者抓 SQL 正確性、本層抓 up/down 對稱性、
#        FK naming、large ALTER、跨 22 merchant deploy 風險)
#   dhpk:security-reviewer (slot 2, conservative):
#     - protected/controllers/**/*.php
#     - infrastructure/Config/**/*.php   ← environment / deployment config
#     - **/*{Auth,Login,Acl,Upload,File}*.php
#   dhpk:frontend-reviewer (slot 3):
#     - js/**/*.{js,ts}                  ← legacy POS JS + emerging TS
#     - excludes: vendor / Tier "Global ignores" (ckeditor, ckfinder, jqPlug, etc.)
#       NOTE: protected/views/**/*.php 內 <script> 區塊由 AI-judgment 補位（hook 無法
#       於 PostToolUse 階段判定 PHP 檔內是否變動到 script block）
#
# Non-matching paths (general .md outside .claude/, .txt, .csv, images, openspec/**, docs/**)
# skip sentinel writes. Sentinels are cleared by each agent's Closing hook
# (clear-sentinel.sh <name> <label>).
#
# Doc vs code split policy (2026-05-22):
#   純 .claude/{agents,rules,commands,skills,manifests}/**/*.md edit → 走 .pending-doc-review
#   （Haiku 級 doc-reviewer：frontmatter / cross-ref / SSOT），不再強跑 Sonnet code-reviewer。
#   **CLAUDE.md 例外**：top-level CLAUDE.md / **/CLAUDE.md 仍走 code-reviewer，因為這些是會
#   影響 agent dispatch 的最高層規則，值得 Sonnet 級審。
set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"
. "$(dirname "$0")/_lib/js-tier-detect.sh"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

PAYLOAD="$(cat 2>/dev/null || true)"
FILE_PATH="$(extract_tool_input file_path "$PAYLOAD")"
# Claude tool payload 可能以 camelCase `filePath` 形式提供；對齊 post-edit-js-lint.sh
# 與 post-edit-php-syntax.sh 的兩階段 fallback，避免 sentinel silent-drop。
[[ -z "$FILE_PATH" ]] && FILE_PATH="$(extract_tool_input filePath "$PAYLOAD")"
[[ -z "$FILE_PATH" ]] && exit 0

REL="${FILE_PATH#$ROOT/}"
BASENAME="${REL##*/}"

# Skip self-generated artifacts (review reports, plans, audits, ADRs, sessions).
# Without this, review agents writing their own artifacts would re-trigger
# a sentinel they have to clear right after.
case "$REL" in
    .claude/artifacts/*) exit 0 ;;
esac

ARTIFACTS="$ROOT/.claude/artifacts/sessions"
mkdir -p "$ARTIFACTS"

mark_sentinel() {
    local name="$1" reason="$2"
    printf '%s %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$reason" >> "$ARTIFACTS/$name"
}

# NEEDS / LABELS index must align with SENTINEL_NAMES in _lib/payload.sh.
# Runtime guard at the end aborts if lengths drift.
NEEDS=(0 0 0 0 0 0)
LABELS=("code-reviewer" "database-reviewer" "security-reviewer" "frontend-reviewer" "doc-reviewer" "migration-reviewer")

# ---------------------------------------------------------------------------
# frontend-reviewer (slot 3) — judged first so PHP-side checks don't double-mark.
# 邏輯 SSOT 抽到 _lib/js-tier-detect.sh (共用 post-edit-js-lint.sh)。
# detect_js_tier 設 JS_TIER ∈ {frontend, vendor, non-js}：
#   - frontend → NEEDS[3]=1 (frontend-reviewer)
#   - vendor   → skip every gate
#   - non-js   → 落入 code-reviewer 區塊（PHP / hooks .sh / CLAUDE.md）
# ---------------------------------------------------------------------------
is_frontend=0
is_vendor_js=0
detect_js_tier "$REL"
case "$JS_TIER" in
    frontend) NEEDS[3]=1; is_frontend=1 ;;
    vendor)   is_vendor_js=1 ;;
esac

# ---------------------------------------------------------------------------
# code-reviewer (slot 0) — PHP everywhere, JS/TS only outside js/ AND non-vendor
# ---------------------------------------------------------------------------
case "$BASENAME" in
    *.php) NEEDS[0]=1 ;;
esac
if [[ "$is_frontend" -eq 0 && "$is_vendor_js" -eq 0 ]]; then
    case "$BASENAME" in
        *.js|*.ts) NEEDS[0]=1 ;;
    esac
fi
# **/CLAUDE.md 是 code-reviewer 的範圍（影響 dispatch 的最高層規則）
[[ "$BASENAME" == "CLAUDE.md" ]] && NEEDS[0]=1
# hooks/scripts 內的 .sh 影響 code dispatch，仍由 code-reviewer 把關
case "$REL" in
    .claude/hooks/*|.claude/scripts/*)
        [[ "$BASENAME" == *.sh ]] && NEEDS[0]=1 ;;
esac

# ---------------------------------------------------------------------------
# doc-reviewer (slot 4) — pure policy/doc edits in .claude/
# 例外：**/CLAUDE.md 即使位於 .claude/ 也是治理層，已由 code-reviewer 接管。
# 例外用 guard-in-arm 處理（非後置 NEEDS[4]=0），避免閱讀者誤以為 doc 有條件性。
# ---------------------------------------------------------------------------
if [[ "$BASENAME" != "CLAUDE.md" ]]; then
    case "$REL" in
        .claude/agents/*|.claude/rules/*|.claude/commands/*|.claude/skills/*|.claude/manifests/*)
            case "$BASENAME" in
                *.md|*.json|*.yml|*.yaml) NEEDS[4]=1 ;;
            esac
            ;;
        .claude/hooks/*|.claude/scripts/*)
            # 純 doc/config（非 .sh）走 doc-reviewer
            case "$BASENAME" in
                *.md|*.json|*.yml|*.yaml) NEEDS[4]=1 ;;
            esac
            ;;
    esac
fi

# ---------------------------------------------------------------------------
# database-reviewer (slot 1)
# ---------------------------------------------------------------------------
case "$REL" in
    infrastructure/Repositories/*|protected/migrations/*|protected/models/*)
        [[ "$BASENAME" == *.php ]] && NEEDS[1]=1 ;;
esac
[[ "$BASENAME" == *.sql ]] && NEEDS[1]=1

# ---------------------------------------------------------------------------
# migration-reviewer (slot 5) — specialist for Yii 1.1 migration safety.
# 與 db-reviewer 並行：後者覆蓋 SQL 正確性、本層覆蓋 migration-specific 風險
# （up/down 對稱性、FK naming collision、large ALTER 策略、跨 merchant deploy）。
# ---------------------------------------------------------------------------
case "$REL" in
    protected/migrations/*)
        [[ "$BASENAME" == *.php ]] && NEEDS[5]=1 ;;
esac

# ---------------------------------------------------------------------------
# security-reviewer (slot 2) — conservative
# ---------------------------------------------------------------------------
case "$REL" in
    protected/controllers/*|infrastructure/Config/*)
        [[ "$BASENAME" == *.php ]] && NEEDS[2]=1 ;;
esac
case "$BASENAME" in
    *Auth*.php|*Login*.php|*Acl*.php|*Upload*.php|*File*.php) NEEDS[2]=1 ;;
esac

# ---------------------------------------------------------------------------
# Runtime guard: NEEDS / LABELS / SENTINEL_NAMES lengths must agree.
# ---------------------------------------------------------------------------
if [[ "${#NEEDS[@]}" -ne "${#SENTINEL_NAMES[@]}" || "${#LABELS[@]}" -ne "${#SENTINEL_NAMES[@]}" ]]; then
    echo "[post-edit-remind] slot drift: NEEDS=${#NEEDS[@]} LABELS=${#LABELS[@]} SENTINEL_NAMES=${#SENTINEL_NAMES[@]}" >&2
    exit 1
fi

msg=""
for i in "${!NEEDS[@]}"; do
    if [[ "${NEEDS[$i]}" -eq 1 ]]; then
        mark_sentinel "${SENTINEL_NAMES[$i]}" "$REL"
        msg+=" ${LABELS[$i]}"
    fi
done

if [[ -z "$msg" ]]; then
    echo "[post-edit] skipped (non-tracked type: $REL)"
else
    echo "[post-edit] marked:${msg} ($REL)"
fi

exit 0
