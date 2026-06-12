#!/usr/bin/env bash
# check-dhpk-version.sh — SessionStart advisory：偵測安裝的 dhpk plugin 版本，
# 比對 `.claude/artifacts/dhpk-tidy/verified-versions.json` 的已驗證範圍。
# 超出範圍即 advisory，不阻擋。
#
# 設計取捨：
# - Claude Code 的 `pluginConfigs` 目前沒有「version pin」語法（marketplace-based
#   install，不是 npm-style），所以 enforcement 走 artifact 比對而非 settings.json。
# - 比對 logic：用 prefix match（"0.4" vs "0.4.0" / "0.4.1"）。允許 patch / minor
#   範圍宣告（"0.4.x"、"0.4"）；major bump 必須手動更新 verified-versions.json。
# - JSON parse 採 python3（系統可用；jq 也可，但 python3 在 zdpos 已是必要依賴）。
# - 若 plugin cache 內有多個版本（升級過渡期），advisory 列出全部偵測到的版本。
#
# 呼叫端：`.claude/hooks/session-start.sh`（已 wire 在 1e）。
# Exit code：永遠 0（advisory only）。

set -o pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DHPK_CACHE="$HOME/.claude/plugins/cache/dhpk/dhpk"
VERIFIED_JSON="$ROOT/.claude/artifacts/dhpk-tidy/verified-versions.json"

[ -d "$DHPK_CACHE" ] || exit 0
[ -f "$VERIFIED_JSON" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

# 列出安裝的版本（目錄名）。while-read 取代 mapfile：macOS 內建 bash 3.2 無 mapfile。
INSTALLED=()
while IFS= read -r _v; do
    [ -n "$_v" ] && INSTALLED+=("$_v")
done < <(ls -1 "$DHPK_CACHE" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' | sort -V)
[ ${#INSTALLED[@]} -eq 0 ] && exit 0

# python3 比對：把每個 installed 版本對 verified.range[] 做 prefix match
result="$(VERIFIED_JSON="$VERIFIED_JSON" INSTALLED_VERSIONS="${INSTALLED[*]}" python3 <<'PY'
import json, os, sys

try:
    with open(os.environ["VERIFIED_JSON"], "r", encoding="utf-8") as f:
        verified = json.load(f)
except Exception:
    sys.exit(0)

installed = (os.environ.get("INSTALLED_VERSIONS") or "").split()
if not installed:
    sys.exit(0)

ranges = []
for v in verified.get("verified", []):
    r = v.get("range", "").strip()
    if r:
        # 轉成 prefix（剝掉 .x 結尾）
        prefix = r.replace(".x", "").rstrip(".")
        ranges.append((prefix, r))

incompat = set()
for v in verified.get("incompatible", []):
    rng = v.get("range", "").strip().replace(".x", "").rstrip(".")
    if rng:
        incompat.add(rng)

def in_verified(ver):
    return any(ver == p or ver.startswith(p + ".") for p, _ in ranges)

def is_incompat(ver):
    return any(ver == p or ver.startswith(p + ".") for p in incompat)

unverified = []
for ver in installed:
    if is_incompat(ver):
        unverified.append((ver, "incompatible"))
    elif not in_verified(ver):
        unverified.append((ver, "unverified"))

if unverified:
    parts = []
    for v, kind in unverified:
        parts.append(f"{v}({kind})")
    print(" ".join(parts))
PY
)"

if [ -n "$result" ]; then
    echo "[session-start] dhpk version advisory: $result — review .claude/artifacts/dhpk-tidy/verified-versions.json"
fi

exit 0
