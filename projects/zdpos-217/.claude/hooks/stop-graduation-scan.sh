#!/usr/bin/env bash
# stop-graduation-scan.sh — Stop hook (advisory only, knowledge graduation Phase A+B)
#
# 掃描本 session transcript 內被引用的 memory entry filename，更新 cross-session
# 累積計數 + Phase B 信心度評分，重生 graduation-candidates.md 提供 rules-distill 用。
#
# 為何要：memory 累積快（已 50+ entries）。手動 promotion 易遺漏；本 hook 自動
# 抓「高頻引用 + 引用後同類 trap 未再犯」的 entry，建議晉升 rule / skill。
#
# 設計：
# - SSOT 是 .claude/artifacts/memory-usage-counts.json（cross-session 累積）
# - graduation-candidates.md 的 AUTO-GENERATED 區段由本 hook regenerate
# - Phase A：count ≥ 3 → 列為 candidate
# - Phase B 信心度（初始 0.5）：
#     clean session → +0.1（cap at 1.0）
#     trap re-occur 訊號 → −0.2（floor 0.0）
# - suggested_target：rule (≥0.7) / skill (0.2-0.7) / decay (≤0.2)
# - 永遠 exit 0；advisory only
#
# 觸發：Stop event（settings.json wire 在 stop-completion-evidence.sh 之後）
# Cost：transcript 全讀 + 1 次 python3 update，<500ms（大型 session 可能略增）

set -o pipefail

# 注意：本 hook 僅需要 payload.sh 的 `get_hook_profile`；不直接用 SENTINEL_NAMES
# / SENTINEL_AGENTS / extract_tool_input。source 是為了與其他 Stop hook 一致 +
# 取得 profile 判斷。若日後 payload.sh sentinel drift guard exit 1 影響本 hook，
# 可改抽 `get_hook_profile` 到獨立檔。
. "$(dirname "$0")/_lib/payload.sh"

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
COUNTS_JSON="$ROOT/.claude/artifacts/memory-usage-counts.json"
CANDIDATES_MD="$ROOT/.claude/artifacts/graduation-candidates.md"

# === Test-mode isolation ===
# CLAUDE_HOOK_TEST_MODE=1 將所有 state 寫入導向 $CLAUDE_HOOK_TEST_OUTDIR（預設 $TMPDIR/claude-graduation-test），
# 並 export CLAUDE_HOOK_SKIP_OPSX_DRAFT=1 防止測試流程寫進真實 openspec/changes/。
# Smoke test / fixture verification 必走此路；硬寫 CLAUDE_PROJECT_DIR 不夠（$HOME 仍指向真實 memory dir）。
if [[ "${CLAUDE_HOOK_TEST_MODE:-0}" == "1" ]]; then
    TEST_OUT="${CLAUDE_HOOK_TEST_OUTDIR:-${TMPDIR:-/tmp}/claude-graduation-test}"
    mkdir -p "$TEST_OUT" 2>/dev/null || true
    COUNTS_JSON="$TEST_OUT/memory-usage-counts.json"
    CANDIDATES_MD="$TEST_OUT/graduation-candidates.md"
    export CLAUDE_HOOK_SKIP_OPSX_DRAFT=1
fi

PROFILE="$(get_hook_profile)"

# minimal profile 直接 exit 0
[[ "$PROFILE" == "minimal" ]] && exit 0

PAYLOAD="$(cat 2>/dev/null || true)"

# 從 payload 取 transcript_path（與 stop-completion-evidence.sh 對齊）
extract_transcript_path() {
    local payload="$1" out=""
    [ -z "$payload" ] && return 0
    if command -v jq >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | jq -r '.transcript_path // .transcript // empty' 2>/dev/null || true)"
    fi
    if [ -z "$out" ] && command -v python3 >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("transcript_path") or d.get("transcript") or "")
except Exception:
    pass
' 2>/dev/null || true)"
    fi
    [ -z "$out" ] && out="${CLAUDE_TRANSCRIPT_PATH:-}"
    printf '%s' "$out"
}

TRANSCRIPT="$(extract_transcript_path "$PAYLOAD")"
[ -z "$TRANSCRIPT" ] && exit 0
[ -f "$TRANSCRIPT" ] || exit 0

# python3 是必要依賴（JSON state + 文字分析）；缺席則 silent skip
command -v python3 >/dev/null 2>&1 || exit 0

mkdir -p "$(dirname "$COUNTS_JSON")" 2>/dev/null || true

# === 主邏輯交給 python3：掃描 transcript + 維護 counts.json + regenerate md ===
TRANSCRIPT="$TRANSCRIPT" \
COUNTS_JSON="$COUNTS_JSON" \
CANDIDATES_MD="$CANDIDATES_MD" \
HOOK_REPO_ROOT="$ROOT" \
python3 <<'PY' || true
import json, os, re, sys, datetime, pathlib

transcript_path = os.environ["TRANSCRIPT"]
counts_path = os.environ["COUNTS_JSON"]
candidates_path = os.environ["CANDIDATES_MD"]

# === Canonical helpers ===
# repo_root 從 bash wrapper 的 $ROOT 傳進來（不能從 counts_path 反推：test mode
# 會把 counts_path 重導到 $TMPDIR，反推結果是 /tmp 而非真實 repo root）。
repo_root = os.environ.get("HOOK_REPO_ROOT") or os.path.dirname(os.path.dirname(os.path.dirname(counts_path)))

def compute_claude_memory_slug(rr: str) -> str:
    """Mirror Claude Code's project-dir naming exactly.
    Rule (observed in ~/.claude/projects/): replace '/' → '-', '_' → '-',
    KEEP leading dash. e.g. /home/paul/projects/zdpos_dev -> -home-paul-projects-zdpos-dev
    """
    return str(pathlib.Path(rr).resolve()).replace("/", "-").replace("_", "-")

# Sanity assert（每次 Stop 都驗一次；slug logic 偏離立刻噴 error 進 stderr 不影響流程）
try:
    assert compute_claude_memory_slug("/home/paul/projects/zdpos_dev") == "-home-paul-projects-zdpos-dev"
except AssertionError:
    print("[graduation] WARN: compute_claude_memory_slug self-test failed", file=sys.stderr)

memory_dir = pathlib.Path.home() / ".claude" / "projects" / compute_claude_memory_slug(repo_root) / "memory"

def memory_entry_exists(entry: str) -> bool:
    return (memory_dir / f"{entry}.md").is_file()

# === Time-span gate ===
MIN_SPAN_HOURS = int(os.environ.get("CLAUDE_HOOK_MIN_SPAN_HOURS", "24"))
MIN_DISTINCT_DATES = int(os.environ.get("CLAUDE_HOOK_MIN_DISTINCT_DATES", "3"))

def passes_time_gate(rec):
    fs, ls = rec.get("first_seen"), rec.get("last_seen")
    if not fs or not ls:
        return False
    try:
        d_fs = datetime.datetime.fromisoformat(fs)
        d_ls = datetime.datetime.fromisoformat(ls)
    except ValueError:
        return False
    if (d_ls - d_fs).total_seconds() < MIN_SPAN_HOURS * 3600:
        return False
    sd = rec.get("seen_dates") or [fs[:10], ls[:10]]
    return len(set(sd)) >= MIN_DISTINCT_DATES

# === Load existing counts ===
state = {"schema_version": 2, "updated_at": "", "entries": {}}
try:
    with open(counts_path, "r", encoding="utf-8") as f:
        loaded = json.load(f)
        if isinstance(loaded, dict) and isinstance(loaded.get("entries"), dict):
            state = loaded
            state.setdefault("schema_version", 1)
            state.setdefault("entries", {})
except (FileNotFoundError, json.JSONDecodeError, ValueError):
    pass  # 空檔或壞檔 → 重來

# === Schema v1 → v2 migration: synthesize seen_dates from first/last_seen ===
if state.get("schema_version", 1) < 2:
    for _e, _r in state["entries"].items():
        _dates = {(_r.get("first_seen") or "")[:10], (_r.get("last_seen") or "")[:10]}
        _dates.discard("")
        _r.setdefault("seen_dates", sorted(_dates))
    state["schema_version"] = 2

# === Read transcript ===
try:
    with open(transcript_path, "r", encoding="utf-8", errors="replace") as f:
        transcript_text = f.read()
except OSError:
    sys.exit(0)

# === Extract memory entry references ===
# 涵蓋三種路徑形式：
#   - memory/trap_foo.md
#   - ~/.claude/projects/-home-paul-projects-zdpos-dev/memory/trap_foo.md
#   - /home/paul/.claude/projects/.../memory/trap_foo.md
# entry 名是 .md 前的 lowercase + 數字 + _ + -
pattern = re.compile(r"memory/([a-z0-9][a-z0-9_-]*)\.md", re.IGNORECASE)
matches = pattern.findall(transcript_text)
# 各 entry 在本 session 中出現的次數
seen_this_session = {}
for name in matches:
    key = name.lower()
    seen_this_session[key] = seen_this_session.get(key, 0) + 1

# Filter 雜訊：MEMORY (uppercase index, 不算 entry)、極短名稱（< 4 字）
filtered = {k: v for k, v in seen_this_session.items()
            if k not in ("memory",) and len(k) >= 4}

if not filtered:
    # 本 session 無 memory ref，仍 regenerate md（顯示既存 candidates）
    pass

# === Phase B trap re-occurrence heuristic ===
# 對每個 entry：找 reference 位置 ±20 lines 內是否有 trap re-occur 訊號詞
# 訊號詞：踩 / 又 / 再 + （trap / bug / 錯 / fail / regression）
RE_OCCUR_SIGNAL = re.compile(
    r"[踩又再](?!到頂|到底).{0,30}(trap|bug|錯|錯誤|fail|regression|崩|壞|錯掉|噴|warning)",
    re.IGNORECASE,
)
# 純詞共現（粗略 fallback）
# 與 strong signal 對稱：「踩」也要排除「踩到頂 / 踩到底」這類非 trap re-occurrence 慣用語
WEAK_SIGNAL = re.compile(
    r"(?:又|再|還是|仍).{0,5}(?:踩(?!到頂|到底)|錯|fail)",
    re.IGNORECASE,
)

transcript_lines = transcript_text.splitlines()

# Window 自適應：短 transcript（< 50 行）改用 1/4 長度避免單一窗口覆蓋全文
# 造成假陽性（reviewer LOW#4）。下限 5、上限 20。
WINDOW_BASE = 20
WINDOW = max(5, min(WINDOW_BASE, len(transcript_lines) // 4 or WINDOW_BASE))

def is_trap_reoccurred(entry_name, lines):
    """heuristic：reference ±WINDOW lines 內出現「又踩」/「再錯」訊號

    比對 entry name 用 word boundary，避免 prefix 相似的 entry 誤觸
    （e.g. trap_foo 不會匹配 trap_foobar）。
    """
    boundary_re = re.compile(r"\b" + re.escape(entry_name) + r"\b", re.IGNORECASE)
    refs = [i for i, line in enumerate(lines) if boundary_re.search(line)]
    if not refs:
        return False
    for ref_idx in refs:
        lo = max(0, ref_idx - WINDOW)
        hi = min(len(lines), ref_idx + WINDOW)
        window = "\n".join(lines[lo:hi])
        if RE_OCCUR_SIGNAL.search(window) or WEAK_SIGNAL.search(window):
            return True
    return False

# === Update state ===
now_iso = datetime.datetime.now().astimezone().replace(microsecond=0).isoformat()
today_date = now_iso[:10]

# === Reconciliation prune: source memory file 消失的 entry confidence -0.3 + mark orphan ===
# Decay 階段：confidence 每輪 -0.3；歸零當輪即 count -1；count 歸零即從 state 移除（tombstone）。
# 注意：confidence 起點較低（如 0.3 / 0.2）的 entry 可能首輪即 tombstone，無「最少 N 輪」保證。
PRUNE_DECAY = 0.3
for _entry, _rec in list(state["entries"].items()):
    if not memory_entry_exists(_entry):
        _rec["orphan"] = True
        _rec["confidence"] = round(max(0.0, float(_rec.get("confidence", 0.5)) - PRUNE_DECAY), 2)
        if _rec.get("confidence", 0) <= 0.0:
            _rec["count"] = max(0, int(_rec.get("count", 0)) - 1)
        if _rec.get("count", 0) <= 0:
            del state["entries"][_entry]
    else:
        _rec.pop("orphan", None)  # 資源恢復則撤回 orphan 標記

for entry, hit_count in filtered.items():
    # Orphan / 不存在的 entry：transcript 雖有 ref 也不累積（避免 reference-to-deleted
    # 把 stale entry 救活；反之該等使用者真把 file 寫回再從零起算）
    if not memory_entry_exists(entry):
        continue
    rec = state["entries"].get(entry, {
        "count": 0,
        "first_seen": now_iso,
        "last_seen": now_iso,
        "confidence": 0.5,
        "graduated_at": None,
        "decay_warning": False,
        "seen_dates": [],
    })
    # Phase A：累積計數
    rec["count"] = int(rec.get("count", 0)) + 1  # 一個 session 算 1 次，非 hit_count
    rec["last_seen"] = now_iso
    rec.setdefault("first_seen", now_iso)

    # 累積 distinct session-date（time-span gate 用）
    sd = rec.setdefault("seen_dates", [])
    if today_date not in sd:
        sd.append(today_date)

    # Phase B：confidence 升降
    cur = float(rec.get("confidence", 0.5))
    if is_trap_reoccurred(entry, transcript_lines):
        cur = max(0.0, cur - 0.2)
    else:
        cur = min(1.0, cur + 0.1)
    rec["confidence"] = round(cur, 2)
    rec["decay_warning"] = (rec["confidence"] <= 0.2)

    state["entries"][entry] = rec

state["updated_at"] = now_iso

# === Write counts.json atomically ===
tmp = counts_path + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(state, f, ensure_ascii=False, indent=2, sort_keys=True)
os.replace(tmp, counts_path)

# === Regenerate AUTO-GENERATED region in candidates.md ===
def suggested_target(entry, rec):
    # decay 也要 count ≥ 3：避免「曾被引用 1 次但 schema 不清楚」的 entry 直接
    # 進 Decay Warnings 表（reviewer LOW#3）。低於 3 次的低信心度 entry 留在
    # counts.json 等下次累積；表格只列「足夠資料量」的 candidate。
    if rec.get("orphan") or not memory_entry_exists(entry):
        return "orphan"
    if rec["count"] < 3:
        return None
    if rec["confidence"] <= 0.2:
        return "decay"
    # rule / skill 額外要求 time-span gate（避免同日內 3 次引用就 graduate）
    if not passes_time_gate(rec):
        return None
    if rec["confidence"] >= 0.7:
        return "rule"
    return "skill"

active_rows = []
decay_rows = []
orphan_rows = []
for entry, rec in sorted(state["entries"].items(),
                         key=lambda kv: (-kv[1].get("count", 0), -kv[1].get("confidence", 0))):
    target = suggested_target(entry, rec)
    if target == "orphan":
        orphan_rows.append((entry, rec))
    elif target == "decay":
        decay_rows.append((entry, rec))
    elif target in ("rule", "skill"):
        active_rows.append((entry, rec, target))

def fmt_iso(s):
    # YYYY-MM-DD only
    return (s or "")[:10]

def build_active_section():
    if not active_rows:
        return "## Active Candidates\n\n(No candidates yet — accrue 3+ cross-session references)\n"
    out = ["## Active Candidates", ""]
    out.append("| Entry | Count | First Seen | Last Seen | Confidence | Suggested Target |")
    out.append("|---|---|---|---|---|---|")
    for entry, rec, target in active_rows:
        out.append(
            f"| {entry} | {rec['count']} | {fmt_iso(rec.get('first_seen'))} | "
            f"{fmt_iso(rec.get('last_seen'))} | {rec['confidence']:.2f} | {target} |"
        )
    out.append("")
    return "\n".join(out)

def build_decay_section():
    if not decay_rows:
        return "## Decay Warnings\n\n(None)\n"
    out = ["## Decay Warnings", ""]
    out.append("| Entry | Count | Last Seen | Confidence |")
    out.append("|---|---|---|---|")
    for entry, rec in decay_rows:
        out.append(
            f"| {entry} | {rec['count']} | {fmt_iso(rec.get('last_seen'))} | "
            f"{rec['confidence']:.2f} |"
        )
    out.append("")
    return "\n".join(out)

def build_orphan_section():
    """Source memory file 已不存在的 entry。counts.json 有殘留紀錄但無法 graduate。
    Decay：confidence 每輪 -0.3；歸零當輪 count -1；count 歸零從 state 移除（tombstone）。"""
    if not orphan_rows:
        return "## Orphan Entries\n\n(None)\n"
    out = ["## Orphan Entries",
           "",
           "Source memory file 不存在；可能是被改名 / 刪除 / 從未真正寫入（如 smoke-test 殘留）。",
           "Confidence 每輪 -0.3，歸零後 count -1，最終 tombstone。",
           ""]
    out.append("| Entry | Count | Last Seen | Confidence |")
    out.append("|---|---|---|---|")
    for entry, rec in orphan_rows:
        out.append(
            f"| {entry} | {rec['count']} | {fmt_iso(rec.get('last_seen'))} | "
            f"{rec['confidence']:.2f} |"
        )
    out.append("")
    return "\n".join(out)

START = "<!-- AUTO-GENERATED:START -->"
END = "<!-- AUTO-GENERATED:END -->"

try:
    with open(candidates_path, "r", encoding="utf-8") as f:
        md_text = f.read()
except FileNotFoundError:
    # 模板不存在 → 不重生（不該由本 hook 創建 header；候選 markdown 是 committed 檔）
    sys.exit(0)

i = md_text.find(START)
j = md_text.find(END)
if i < 0 or j < 0 or j < i:
    # markers 缺失 → 不冒險改動（避免覆蓋 user 手寫內容）
    sys.exit(0)

new_block = (
    START + "\n\n"
    + build_active_section() + "\n"
    + build_orphan_section() + "\n"
    + build_decay_section() + "\n"
    + END
)
new_md = md_text[:i] + new_block + md_text[j + len(END):]
tmp = candidates_path + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    f.write(new_md)
os.replace(tmp, candidates_path)

# === Phase B+ extension：graduation → OpsX change draft ===
# 對 confidence ≥ 0.7 且 count ≥ 3 且 通過 time-span gate 且 source memory file 存在 的 entry，
# 若 openspec/changes/graduate-<name>/ 尚不存在，自動產 proposal.md skeleton（unstaged）。
# advisory only — 不 git add。
#
# 設計取捨：
# - 用 raw 寫檔而非呼叫 `openspec new change`。理由：openspec CLI v1.2.0 的
#   `new change` 沒文件化非互動模式，且 OpsX schema 在 6 個月內有 v0.1 → v0.2.1
#   遷移；raw 寫檔可鎖定 schema 版本（在 proposal.md 內標 metadata: schema_v=0.2）。
# - skeleton 內容引用 memory entry 路徑供 author 取材，不直接 inline 內容
#   （避免 entry 內容過長拖累 skeleton 可讀性）。
# - 一次最多 draft 3 個 change：避免 confidence 校準誤判造成大量 draft 噪音。
# - Test-mode 透過 CLAUDE_HOOK_SKIP_OPSX_DRAFT=1 短路，避免 smoke-test 寫進真實
#   openspec/changes/（2026-05-27 烏龍 graduate-trap-high-conf 就是這個 gap 造成）。

if os.environ.get("CLAUDE_HOOK_SKIP_OPSX_DRAFT") == "1":
    sys.exit(0)

opsx_changes_dir = os.path.join(repo_root, "openspec", "changes")
repo_slug = compute_claude_memory_slug(repo_root)

drafted = []
if os.path.isdir(opsx_changes_dir):
    high_conf = []
    for entry, rec in state["entries"].items():
        # 三道閘：(1) source file 必須存在 (2) count + confidence 達標 (3) time-span gate
        if not memory_entry_exists(entry):
            continue
        if rec.get("count", 0) < 3 or float(rec.get("confidence", 0)) < 0.7:
            continue
        if not passes_time_gate(rec):
            continue
        high_conf.append((entry, rec))
    # 排序：confidence 高 → count 高
    high_conf.sort(key=lambda kv: (-float(kv[1]["confidence"]), -int(kv[1]["count"])))

    for entry, rec in high_conf[:3]:
        slug = "graduate-" + entry.replace("_", "-")
        target_dir = os.path.join(opsx_changes_dir, slug)
        if os.path.exists(target_dir):
            continue  # 已有 draft 或正在 apply；不覆蓋
        try:
            os.makedirs(target_dir, exist_ok=False)
        except OSError:
            continue

        memory_path = f"~/.claude/projects/{repo_slug}/memory/{entry}.md"
        proposal_md = f"""# Graduate `{entry}` to rule / skill

> Auto-drafted by `.claude/hooks/stop-graduation-scan.sh` on {now_iso}.
> Source memory entry: `{memory_path}`
> Graduation signal: count={rec['count']}, confidence={rec['confidence']:.2f}
>
> **Status: DRAFT** — 本檔由 hook 自動產生，未經 author 審查。請執行
> `/opsx:continue {slug}` 完善 Why / What Changes / Capabilities 段，或刪除目錄
> 拒絕本次 graduation 提案（counts.json 仍會持續累積，下次有機會再 draft）。

## Why

`{entry}` memory entry 已在 {rec['count']} 個 session 被引用，confidence
{rec['confidence']:.2f} ≥ 0.7（無 trap re-occurrence 訊號）。表示這個知識點
已被反覆驗證為「值得記住」，符合 graduation criteria（從 ad-hoc memory 升級
為 `.claude/rules/` 或 skill 的正式條目）。

請於 `## Why` 補：
- 此 entry 涵蓋什麼問題類型（trap / convention / workflow / domain）
- 為何此次累積夠多次後該晉升而非繼續留在 memory（信號 vs 雜訊）
- 與既有 rule / skill 的關係（補強 / 覆蓋 / 並列）

## What Changes

請於本段補：
- 目標位置（`.claude/rules/<path>.md` 或 `.claude/skills/<name>/SKILL.md`
  或 dhpk plugin upstream PR）
- 是否要從 `MEMORY.md` 移除原 entry（typical：是；保留指標到新位置）
- 是否需要更新 `graduation-candidates.md` 的 AUTO-GENERATED 區段
  （typical：hook 下一次跑時自動同步，不必本 change 處理）

## Capabilities

請於本段補對應的 capability slug；或宣告本次 graduation 不對應任何 capability
（純內部 harness 維護）。

## Out of scope

- 不重寫 source entry 的歷史內容（直接從 memory 複製文字到新位置即可）
- 不擴大本次提案到其他 entry（一次一個 graduation，避免 review 困難）
"""
        tasks_md = f"""# Tasks — {slug}

## 1. Confirm graduation worthiness

- [ ] 1.1 讀 `{memory_path}` 完整內容
- [ ] 1.2 比對既有 `.claude/rules/**` 與 dhpk plugin rule，確認無重複
- [ ] 1.3 決定落點：local rule / local skill / dhpk PR

## 2. Migrate content

- [ ] 2.1 在目標位置寫入內容（preserve original wording where possible）
- [ ] 2.2 在 `MEMORY.md` 對應 entry 改為 pointer 指向新位置
- [ ] 2.3 update cross-references in other memory entries（grep `{entry}`）

## 3. Verify

- [ ] 3.1 跑 `dhpk:claude-health` 確認 .claude/ 結構正常
- [ ] 3.2 跑 `dhpk:harness-revise` 驗證 trigger 未遺失
- [ ] 3.3 若 graduating 到 dhpk，需另開 dhpk PR 並 link 本 change
"""
        try:
            with open(os.path.join(target_dir, "proposal.md"), "w", encoding="utf-8") as f:
                f.write(proposal_md)
            with open(os.path.join(target_dir, "tasks.md"), "w", encoding="utf-8") as f:
                f.write(tasks_md)
            drafted.append(slug)
        except OSError:
            pass

if drafted:
    print(f"[graduation-draft] auto-drafted {len(drafted)} OpsX change(s): {', '.join(drafted)}", file=sys.stderr)
    print("[graduation-draft] review with `openspec list` / `/opsx:continue <slug>`; delete dir to reject", file=sys.stderr)
PY

# Advisory only — 永遠不阻塞 stop
exit 0
