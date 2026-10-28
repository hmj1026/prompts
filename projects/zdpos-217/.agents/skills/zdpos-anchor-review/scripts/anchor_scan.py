#!/usr/bin/env python3
"""Phase A 盤點掃描：anchor 與 doc 的機械判定，結果完整寫檔，不截斷。

用法：
  python3 anchor_scan.py --anchor '2026/07/21 paul [v1] 新增拆帳功能0714' --out .scratch/anchor-review-<date>
  可選 --base（預設 origin/master）、--repo（預設目前目錄）。

範圍：相對 merge-base 有變更（含工作樹與 untracked）、且內容含 anchor 的 php/js/html/vue 檔。
輸出（皆 TSV，--out 目錄下）：
  scope.tsv          狀態(A/M) 與檔案
  anchor_new.tsv     新檔：缺 anchor／method 層重複／不在類別層
  anchor_mod.tsv     修改檔：程式段落缺 anchor（已排除純 docblock hunk、develop 帶入、其他功能 anchor）
  doc_nodoc.tsv      新檔全部方法＋修改檔本體有程式變更的方法中，缺 docblock 者
  doc_nozh.tsv       同上範圍，docblock 無中文說明者
  doc_jargon.tsv     同上範圍，docblock 含流程代號（Dnn、task N、Stage X、裁決 X、Ruling X、review-N）
  summary.txt        各檔筆數；Phase A 盤點表筆數必須與此一致
"""
import argparse
import os
import re
import subprocess
import sys

EXTS = ('.php', '.js', '.html', '.vue')
VENDOR_DIRS = ('vendor/', 'protected/vendors/', 'ckeditor/', 'ckfinder/')
OTHER_ANCHOR = re.compile(r'(19|20)\d{2}[/-]\d{1,2}[/-]\d{1,2}\s+\w+')
COMMENT = re.compile(r'\s*(\*|//|/\*\*|\*/|#|<!--)')
CLASS = re.compile(r'\s*(final\s+|abstract\s+)?(class|interface|trait)\s+\w+')
KEYWORDS = {'if', 'for', 'while', 'switch', 'catch', 'do', 'else', 'finally', 'try', 'return'}
FUNC_PHP = re.compile(r'^\s*(?:(?:public|protected|private|static|final|abstract)\s+)*function\s+(\w+)\s*\(')
FUNC_JS_KEY = re.compile(r'^\s*[\'\"]?(\w+)[\'\"]?\s*:\s*(?:async\s+)?function\b')
FUNC_JS_ES6 = re.compile(r'^\s*(?:(?:async|static)\s+)*(\w+)\s*\([^)]*\)\s*\{')
JSBLOCK = re.compile(r'\s*(test|it|describe)\(')
TRIVIAL = re.compile(r'^\s*[{}()\[\];,]*\s*$')
JARGON = re.compile(r'(\bD\d{1,2}\b|\btask\s*\d+(?:\.\d+)?|\bStage\s*[A-Z]{1,2}\b|裁決\s*[A-Z]\b|Ruling\s*[A-Z]\b|\brulings?\b|review-\d+)', re.I)


def match_func(line, is_js=False):
    m = FUNC_PHP.match(line)
    if m:
        return m.group(1)
    if is_js:
        m = FUNC_JS_KEY.match(line)
        if m:
            return m.group(1)
        m = FUNC_JS_ES6.match(line)
        if m and m.group(1) not in KEYWORDS:
            return m.group(1)
    return None


def git(repo, *args):
    return subprocess.check_output(['git', '-C', repo] + list(args)).decode('utf-8', 'replace')


def read_lines(repo, path):
    with open(os.path.join(repo, path), encoding='utf-8', errors='replace') as fh:
        return fh.read().split('\n')


def added_lines(repo, base, path):
    """回傳 [(新檔行號, 內容)]。"""
    out, cur = [], None
    for line in git(repo, 'diff', '-U0', base, '--', path).split('\n'):
        m = re.match(r'@@ -\d+(?:,\d+)? \+(\d+)', line)
        if m:
            cur = int(m.group(1))
            continue
        if cur is None or line.startswith('+++'):
            continue
        if line.startswith('+'):
            out.append((cur, line[1:]))
            cur += 1
        elif not line.startswith('-'):
            cur += 1
    return out


def hunks(repo, base, path):
    """依連續行號切 hunk：[[(行號, 內容), ...], ...]。"""
    groups, prev = [], None
    for n, text in added_lines(repo, base, path):
        if prev is None or n != prev + 1:
            groups.append([])
        groups[-1].append((n, text))
        prev = n
    return groups


def build_scope(repo, base, anchor):
    status = {}
    for line in git(repo, 'diff', '--name-status', base).split('\n'):
        parts = line.split('\t')
        if len(parts) >= 2 and parts[-1].endswith(EXTS):
            if not parts[-1].startswith(VENDOR_DIRS):
                status[parts[-1]] = parts[0][0]
    for path in git(repo, 'ls-files', '--others', '--exclude-standard').split('\n'):
        if path.endswith(EXTS) and not path.startswith(VENDOR_DIRS):
            status[path] = 'A'

    # 檢查工作區有變動的檔案（含 staged、unstaged 與 untracked）
    dirty = set()
    for line in git(repo, 'status', '--porcelain').split('\n'):
        if len(line) > 3:
            p = line[3:].strip()
            if ' -> ' in p:
                p = p.split(' -> ')[1]
            if p.endswith(EXTS) and not p.startswith(VENDOR_DIRS):
                dirty.add(p)

    scope = []
    for path, st in sorted(status.items()):
        full = os.path.join(repo, path)
        if st in 'AMR' and os.path.isfile(full):
            # 檔案若包含本次 anchor，或是目前工作區變更中的檔案，皆應納入審查範圍
            if path in dirty or anchor in open(full, encoding='utf-8', errors='replace').read():
                scope.append((st if st != 'R' else 'M', path))
    return scope


def method_spans(src, path=''):
    """[(名稱, 宣告行, docblock 起始行或 None, 本體結束行)]，行號 1 起算；本體結束於下一個方法 docblock 之前。"""
    is_js = path.endswith(('.js', '.vue'))
    decls = []
    for i, l in enumerate(src):
        name = match_func(l, is_js)
        if name:
            decls.append((i, name))

    spans = []
    for idx, (i, name) in enumerate(decls):
        j = i - 1
        # 跳過空白行與 PHP 8 屬性標註（例如 #[\ReturnTypeWillChange]、#[DataProvider(...)]）
        while j >= 0 and (src[j].strip() == '' or (src[j].strip().startswith('#[') and src[j].strip().endswith(']'))):
            j -= 1
        doc_start = None
        if j >= 0 and src[j].strip().endswith('*/'):
            k = j
            while k >= 0 and '/**' not in src[k]:
                k -= 1
            doc_start = k + 1 if k >= 0 else None
        end = len(src)
        if idx + 1 < len(decls):
            end = decls[idx + 1][0]
            while end - 1 > i and (src[end - 1].strip() == '' or COMMENT.match(src[end - 1])):
                end -= 1
        stop = next((k for k in range(i + 1, end) if CLASS.match(src[k])), None)
        if stop is not None:
            end = stop
        spans.append((name, i + 1, doc_start, end))
    return spans


def anchor_owner(src, idx):
    """anchor 行之後最近的宣告種類：class／method／code（方法本體或檔案層程式）。"""
    for j in range(idx + 1, min(idx + 80, len(src))):
        line = src[j]
        if CLASS.match(line):
            return 'class'
        if match_func(line, is_js=True):
            return 'method'
        if line.strip() and not COMMENT.match(line):
            return 'code'
    return 'code'


def check_new(repo, path, anchor):
    """新檔：恰一次於檔案／類別層；同檔多個 helper class 各一次合法；字串 fixture 不計。"""
    src = read_lines(repo, path)
    hits = [i for i, l in enumerate(src) if anchor in l and COMMENT.match(l)]
    if not hits:
        return [(path, 0, '缺 anchor')]
    first_code = next((i for i, l in enumerate(src) if match_func(l, is_js=True) or JSBLOCK.match(l)), len(src))
    rows = []
    for n, i in enumerate(hits):
        owner = anchor_owner(src, i)
        if owner == 'class':
            continue
        if n == 0 and i < first_code and owner != 'method':
            continue  # 檔頭 anchor
        if owner == 'method' and not any(CLASS.match(l) for l in src[:i]):
            continue  # namespace／script 層獨立函式，本身即物件
        rows.append((path, i + 1, 'method 層重複 anchor（%s）' % owner))
    return rows


def check_mod(repo, base, path, anchor, dev_src):
    src = read_lines(repo, path)
    spans = method_spans(src, path) if path.endswith(('.php', '.js')) else []
    rows = []
    groups = {}
    for h in hunks(repo, base, path):
        texts = [t for _, t in h]
        if all(TRIVIAL.match(t) or COMMENT.match(t) for t in texts):
            continue  # 純 docblock／註解／括號
        if dev_src and all(not t.strip() or t in dev_src for t in texts) and not any(anchor in t for t in texts):
            continue  # develop 帶入
        start = h[0][0]
        # 注意：hunk 可能落在 docblock 範圍 (doc_start ~ decl) 或方法本體 (decl ~ end)
        owner = next((s for s in spans if (s[2] if s[2] else s[1]) <= start <= s[3]), None)
        key = owner if owner else ('<檔案層>', start)  # 方法外的 hunk 各自判定，不合併
        groups.setdefault(key, []).append(h)
    for key, hs in groups.items():
        owner = key if key and key[0] != '<檔案層>' else None
        added = [t for h in hs for _, t in h]
        first = hs[0][0][0]
        if any(anchor in t for t in added):
            continue
        lo = owner[2] or owner[1] if owner else max(1, first - 3)
        context = src[lo - 1:first - 1] if owner else src[max(0, first - 4):first - 1]
        if any(anchor in c for c in context):
            continue
        # 若為方法層級變更，檢查整個方法範圍（含 docblock 與本體）是否已包含本次 anchor
        if owner:
            method_lines = src[(owner[2] or owner[1]) - 1:owner[3]]
            if any(anchor in c for c in method_lines):
                continue
        if any(OTHER_ANCHOR.search(t) for t in added) or any(OTHER_ANCHOR.search(c) and anchor not in c for c in context):
            continue  # 其他功能
        label = owner[0] if owner else '<檔案層>'
        rows.append((path, first, label, len(hs), len(added)))
    return rows


def check_doc(repo, base, path, status, anchor):
    if not path.endswith('.php') or '/views/' in path:
        return [], [], []  # view 內的 JS 函式不套 phpDoc 規則
    src = read_lines(repo, path)
    touched = None if status == 'A' else set(n for n, t in added_lines(repo, base, path) if not TRIVIAL.match(t) and not COMMENT.match(t))
    nodoc, nozh, jargon = [], [], []
    for name, decl, doc_start, end in method_spans(src, path):
        if touched is not None and not any(decl <= n <= end for n in touched):
            continue
        block = '\n'.join(src[doc_start - 1:decl - 1]) if doc_start else ''
        if touched is not None and anchor not in block and OTHER_ANCHOR.search(block):
            continue
        if not doc_start:
            nodoc.append((path, decl, name))
            continue
        if not re.search(r'[一-鿿]', block):
            nozh.append((path, decl, name))
        for m in JARGON.finditer(block):
            jargon.append((path, doc_start, name, m.group(0)))
    return nodoc, nozh, jargon


def write_tsv(out, name, rows):
    with open(os.path.join(out, name), 'w', encoding='utf-8') as fh:
        for r in rows:
            fh.write('\t'.join(str(x) for x in r) + '\n')
    return len(rows)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--anchor', required=True)
    ap.add_argument('--base', default='origin/master')
    ap.add_argument('--repo', default='.')
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    repo = os.path.abspath(args.repo)
    os.makedirs(args.out, exist_ok=True)
    base = git(repo, 'merge-base', args.base, 'HEAD').strip()
    scope = build_scope(repo, base, args.anchor)
    new_rows, mod_rows, nodoc, nozh, jargon = [], [], [], [], []
    for st, path in scope:
        if st == 'A':
            new_rows += check_new(repo, path, args.anchor)
        else:
            try:
                dev_src = git(repo, 'show', 'origin/develop:' + path)
            except subprocess.CalledProcessError:
                dev_src = ''
            mod_rows += check_mod(repo, base, path, args.anchor, dev_src)
        a, b, c = check_doc(repo, base, path, st, args.anchor)
        nodoc += a
        nozh += b
        jargon += c
    counts = [
        ('scope.tsv', write_tsv(args.out, 'scope.tsv', scope)),
        ('anchor_new.tsv', write_tsv(args.out, 'anchor_new.tsv', new_rows)),
        ('anchor_mod.tsv', write_tsv(args.out, 'anchor_mod.tsv', mod_rows)),
        ('doc_nodoc.tsv', write_tsv(args.out, 'doc_nodoc.tsv', nodoc)),
        ('doc_nozh.tsv', write_tsv(args.out, 'doc_nozh.tsv', nozh)),
        ('doc_jargon.tsv', write_tsv(args.out, 'doc_jargon.tsv', jargon)),
    ]
    with open(os.path.join(args.out, 'summary.txt'), 'w', encoding='utf-8') as fh:
        fh.write('base=%s anchor=%s\n' % (base, args.anchor))
        for name, n in counts:
            fh.write('%s\t%d\n' % (name, n))
    for name, n in counts:
        print('%-16s %d' % (name, n))
    return 0


if __name__ == '__main__':
    sys.exit(main())
