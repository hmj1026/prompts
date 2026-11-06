#!/usr/bin/env python3
"""QA 手冊畫面字串查證：抓出 `「…」` 引號字串，確認專案原始碼裡真的有。

找不到的字串列為「疑似臆測」警告（預設 exit 0，`--strict` 才 exit 1）。
選單名稱只存在 DB（zdn_menu），查證後寫進手冊同目錄的 `.verified-labels.txt`（一行一個，`#` 開頭為註解）。
必須在 app repo 根目錄執行（用 `git grep`）；手冊對應的功能在其他分支時加 `--ref <分支>`。
"""
import argparse
import os
import re
import subprocess
import sys

SEARCH_PATHS = [
    "protected/*.php", "protected/*.js", "js/*.js", "domain/*.php", "infrastructure/*.php",
]
EXCLUDE = [
    ":!protected/tests", ":!js/tests", ":!protected/vendors", ":!js/vendor",
    ":!*.min.js", ":!*.html",
]
QUOTE = re.compile(r"「([^」\n]{2,30})」")
SPLIT = re.compile(r"\s*(?:>|＞|／|/|＋|\+)\s*")
TRAIL = re.compile(r"[：:?？…\s]+$|\.{2,}$")
SKIP = re.compile(r"^[\w\-.,/\\ ]+$|^(?:PASS|FAIL|BLOCKED|N/A|NOT_RUN)")


def load_allow(md_path):
    allow = set()
    p = os.path.join(os.path.dirname(os.path.abspath(md_path)), ".verified-labels.txt")
    if os.path.isfile(p):
        for ln in open(p, encoding="utf-8"):
            ln = ln.strip()
            if ln and not ln.startswith("#"):
                allow.add(ln)
    return allow


def candidates(md_text):
    body = re.sub(r"```.*?```", "", md_text, flags=re.S)
    found = {}
    for lineno, line in enumerate(body.splitlines(), 1):
        for m in QUOTE.finditer(line):
            for part in SPLIT.split(m.group(1)):
                key = TRAIL.sub("", part.replace("*", "").replace("「", "").strip())
                if len(key) < 2 or SKIP.match(key) or "＝" in key:
                    continue
                found.setdefault(key, lineno)
    return found


def in_source(text, ref=None):
    cmd = ["git", "grep", "-q", "-F", "-e", text] + ([ref] if ref else []) + ["--"] + SEARCH_PATHS + EXCLUDE
    return subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def verify(md_path, ref=None):
    text = open(md_path, encoding="utf-8").read()
    allow = load_allow(md_path)
    missing = [(k, ln) for k, ln in sorted(candidates(text).items(), key=lambda kv: kv[1])
               if k not in allow and not in_source(k, ref)]
    return missing


def collect(target):
    if os.path.isfile(target):
        return [target]
    out = []
    for root, _, files in os.walk(target):
        out += [os.path.join(root, f) for f in files if re.match(r"QA-.*-manual\.md$", f)]
    return sorted(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("target", help="QA 手冊 .md 或目錄")
    ap.add_argument("--ref", help="手冊對應的分支或 commit（手冊所述功能不在目前 checkout 時使用）")
    ap.add_argument("--strict", action="store_true", help="有疑似臆測字串時 exit 1")
    args = ap.parse_args()
    bad = 0
    for md in collect(args.target):
        missing = verify(md, args.ref)
        if not missing:
            print(f"✅ 畫面字串查證：{md} 所有引號字串皆可在原始碼找到")
            continue
        bad += len(missing)
        print(f"⚠️ 畫面字串查證：{md} 有 {len(missing)} 個字串在原始碼找不到（疑似臆測、改名，或只存在 DB）：")
        for key, ln in missing:
            print(f"   L{ln}: 「{key}」")
        print("   處理：查原始碼或 zdn_menu 後改成真名；確定只存在 DB 的選單名稱，寫進同目錄 .verified-labels.txt。")
    sys.exit(1 if (bad and args.strict) else 0)


if __name__ == "__main__":
    main()
