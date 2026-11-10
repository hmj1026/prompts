#!/usr/bin/env bash
# anchor_scan.py 迴歸測試：在拋棄式 git repo 重現已知盲點（跨方法 hunk、WIP、未追蹤目錄、git mv、同方法重複 anchor）。
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

# 第二組（2026-11-10）：未追蹤目錄、git mv 搬移檔、同方法重複 anchor
R="$T/r2"
mkdir -p "$R" && cd "$R"
git init -q -b master
git config user.email t@t; git config user.name t
mkdir -p old
cat > old/Moved.php <<'EOF'
<?php
class Moved
{
    /**
     * 既有方法一。
     */
    public function first()
    {
        return 1;
    }

    /**
     * 既有方法二。
     */
    public function second()
    {
        return 2;
    }
}
EOF
cp old/Moved.php old/Dup.php
sed -i 's/class Moved/class Dup/' old/Dup.php
git add . && git commit -qm base
git branch origin/master
git checkout -qb feature
mkdir -p moved
git mv old/Moved.php moved/Moved.php
python3 - "$R/moved/Moved.php" "$R/old/Dup.php" "$A" <<'PY'
import sys
moved, dup, a = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(moved, encoding='utf-8').read()
s = s.replace("        return 1;\n", "        // %s\n        return 10;\n" % a, 1)
open(moved, 'w', encoding='utf-8').write(s)
s = open(dup, encoding='utf-8').read()
s = s.replace("        return 1;\n", "        // %s - 第一段\n        $x = 1;\n\n        // %s - 第二段\n        return $x;\n" % (a, a), 1)
open(dup, 'w', encoding='utf-8').write(s)
PY
mkdir -p tests/newdir
printf '<?php\nclass NewDirTest\n{\n}\n' > tests/newdir/NewDirTest.php
python3 "$SCAN" --anchor "$A" --base origin/master --repo "$R" --out "$R/out" >/dev/null 2>&1 || true
check '未追蹤目錄內新檔進 scope 並列為缺 anchor' 'grep -q "tests/newdir/NewDirTest.php	0	缺 anchor" "$R/out/anchor_new.tsv"'
check 'git mv 搬移檔：既有方法 second 不被當新方法' '! grep -q "second" "$R/out/anchor_mod.tsv"'
check 'git mv 搬移檔：已帶 anchor 的 first 不被列出' '! grep -q "first" "$R/out/anchor_mod.tsv"'
check '同方法重複 anchor：Dup::first 列入 anchor_dup' 'grep -q "old/Dup.php	[0-9]*	first	2" "$R/out/anchor_dup.tsv"'
check 'anchor 只出現一次的 Moved::first 不列入 anchor_dup' '! grep -q "Moved.php" "$R/out/anchor_dup.tsv"'

# 第三組（2026-11-10）：逐行 style／術語／佔位 anchor 檢查
S3="$T/r3"
mkdir -p "$S3" && cd "$S3"
git init -q -b master
git config user.email t@t; git config user.name t
printf '<?php\n' > keep.php
git add . && git commit -qm base
git branch origin/master
git checkout -qb feature
mkdir -p domain tests
cat > domain/Lines.php <<EOF
<?php
/**
 * 逐行檢查樣本。
 *
 * $A
 */
class Lines
{
    private static \$fooList = [];

    /**
     * 執行。
     */
    public function run()
    {
        // 2026/11/09 paul [臨時]佔位_1109 - 開發期佔位 anchor
        // 對應任務 6.3（Decision 15），單一來源見 SSOT
        // 呼叫 report() 與 import 不算術語
        \$badList = [];
        \$good_list = [];
        \$repo = new \\ArrayObject();
        \$Repo = new \\ArrayObject();
        return [\$badList, \$good_list, \$repo, \$Repo];
    }
}
EOF
cat > tests/LinesTest.php <<EOF
<?php
/**
 * 測試樣本。
 *
 * $A
 */
class LinesTest
{
    public function testRun_Default_ReturnsArray()
    {
    }

    public function testRunWorks()
    {
    }
}
EOF
python3 "$SCAN" --anchor "$A" --base origin/master --repo "$S3" --out "$S3/out" >/dev/null 2>&1 || true
check '流程代號：任務 6.3 與 Decision 15 被列出' 'grep -q "任務 6.3" "$S3/out/doc_jargon.tsv" && grep -q "Decision 15" "$S3/out/doc_jargon.tsv"'
check '英文術語：SSOT 被列出' 'grep -q "	SSOT	" "$S3/out/doc_terms.tsv"'
check '英文術語：report／import 不誤報' '! grep -qiE "	(port|Port)	" "$S3/out/doc_terms.tsv"'
check '變數命名：$badList 與 $repo 被列出' 'grep -q "\$badList" "$S3/out/style_vars.tsv" && grep -q "\$repo	" "$S3/out/style_vars.tsv"'
check '變數命名：$good_list、$Repo、static 屬性不誤報' '! grep -qE "\\\$(good_list|Repo|fooList)	" "$S3/out/style_vars.tsv"'
check '測試命名：testRunWorks 被列出、三段式不列' 'grep -q testRunWorks "$S3/out/style_tests.tsv" && ! grep -q testRun_Default "$S3/out/style_tests.tsv"'
check '佔位 anchor：同作者不同文字被列出' 'grep -q "\[臨時\]佔位_1109" "$S3/out/anchor_foreign.tsv"'
check '佔位 anchor：本次正式 anchor 不列入' '[ "$(wc -l < "$S3/out/anchor_foreign.tsv")" -eq 1 ]'
exit $fail
