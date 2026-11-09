#!/usr/bin/env bash
# anchor_scan.py 迴歸測試：在拋棄式 git repo 重現三種盲點。
set -euo pipefail
SCAN="$(cd "$(dirname "${1:?scanner path}")" && pwd -P)/$(basename "$1")"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
A='2026/07/21 paul [v1] 新增拆帳功能0714'
W='2026/11/09 paul [v1] 拆帳PHP84相容_1109'
cd "$T"
git init -q -b master
git config user.email t@t; git config user.name t
mkdir -p domain
cat > domain/Svc.php <<'EOF'
<?php
class Svc
{
    /**
     * 既有方法。
     */
    public function legacy()
    {
        return 1;
    }
}
EOF
git add . && git commit -qm base
git branch origin/master
git checkout -qb feature
cat > domain/Svc.php <<EOF
<?php
class Svc
{
    /**
     * 既有方法。
     */
    public function legacy()
    {
        return 1;
    }

    /**
     * 有 anchor 的新方法。
     *
     * $A
     */
    public function withAnchor(\$x = null)
    {
        return 2;
    }

    /**
     * 沒有 anchor 的新方法（與上一個方法同一 hunk）。
     */
    public function missingAnchor()
    {
        return 3;
    }
}
EOF
git add . && git commit -qm feature
# WIP：只改 withAnchor 的簽章，未加子題 anchor
sed -i 's/withAnchor(\$x = null)/withAnchor($x = null, $y = null)/' domain/Svc.php

python3 "$SCAN" --anchor "$A" --base origin/master --repo "$T" --out "$T/out" >/dev/null 2>&1 || true
python3 "$SCAN" --anchor "$A" --base origin/master --repo "$T" --out "$T/out2" --wip-anchor "$W" >/dev/null 2>&1 || true

fail=0
check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
check '跨方法 hunk：missingAnchor 被列出' 'grep -q missingAnchor "$T/out/anchor_mod.tsv"'
check 'withAnchor 不被誤報（0714）' '! grep -q withAnchor "$T/out/anchor_mod.tsv"'
check 'legacy 不被列出' '! grep -q legacy "$T/out/anchor_mod.tsv"'
check '--wip-anchor：withAnchor 簽章變更被列出' 'grep -q withAnchor "$T/out2/anchor_wip.tsv"'
check '未給 --wip-anchor 時 anchor_wip 為 0' 'grep -q "^anchor_wip.tsv	0$" "$T/out/summary.txt"'
# 補上子題 anchor 後應消失
python3 - "$T/domain/Svc.php" "$W" <<'PY'
import sys
p, w = sys.argv[1], sys.argv[2]
s = open(p, encoding='utf-8').read()
s = s.replace(" * 有 anchor 的新方法。\n", " * 有 anchor 的新方法。\n *\n * %s\n" % w, 1)
open(p, 'w', encoding='utf-8').write(s)
PY
python3 "$SCAN" --anchor "$A" --base origin/master --repo "$T" --out "$T/out3" --wip-anchor "$W" >/dev/null 2>&1 || true
check '補 wip anchor 後 withAnchor 消失' '[ -f "$T/out3/anchor_wip.tsv" ] && ! grep -q withAnchor "$T/out3/anchor_wip.tsv"'
exit $fail
