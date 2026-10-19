#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
inspect_scope.py
自動盤點分支 (Branch) 或 Anchor 註釋涉及的檔案範圍，並依 DDD 分層與 ZDPOS 架構分類。

使用方式:
    python3 inspect_scope.py --branch feature/add-split-bill-checkout_0723
    python3 inspect_scope.py --anchor "2025/12/02 paul [爆米發]顧客點數期限客制"
    python3 inspect_scope.py --anchor "2025/12/02 paul"
"""

import argparse
import os
import re
import subprocess
import sys
import json

LAYER_RULES = [
    ("Migrations (資料遷移)", r"^protected/migrations/"),
    ("Domain Core (領域模型與服務)", r"^domain/"),
    ("Infrastructure (基礎設施與倉儲)", r"^infrastructure/"),
    ("Presentation / Controllers (控制器與Trait)", r"^protected/controllers/"),
    ("Models (資料模型與事件)", r"^protected/models/"),
    ("Console Commands (排程與CLI工具)", r"^protected/commands/|^protected/helpers/"),
    ("Views & Frontend (視圖與前端腳本)", r"^protected/views/|^js/"),
    ("Tests (單元與整合測試)", r"^protected/tests/"),
    ("Docs (相關規格與ADR)", r"^docs/|^openspec/"),
]

def run_cmd(cmd, cwd=None):
    res = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, cwd=cwd)
    return res.stdout.strip(), res.stderr.strip(), res.returncode

def inspect_by_branch(branch, base_ref="origin/master", repo_dir="."):
    cmd = f"git diff --name-only {base_ref}...{branch}"
    out, err, code = run_cmd(cmd, cwd=repo_dir)
    if code != 0 or not out:
        # Fallback to local diff if base_ref failed
        cmd = f"git diff --name-only master...HEAD"
        out, err, code = run_cmd(cmd, cwd=repo_dir)
    files = [f.strip() for f in out.splitlines() if f.strip()]
    return list(dict.fromkeys(files))

def inspect_by_anchor(anchor, repo_dir="."):
    # First grep exact or partial anchor with fixed string flag (-F)
    cmd = f"git grep -l -F '{anchor}'"
    out, err, code = run_cmd(cmd, cwd=repo_dir)
    files = [f.strip() for f in out.splitlines() if f.strip()]
    
    # If too few, try normalized keywords
    if len(files) <= 1:
        # Try extracting words inside bracket or author
        match = re.search(r"\[(.*?)\]", anchor)
        if match:
            sub = match.group(1)
            if len(sub) > 2:
                cmd2 = f"git grep -l -F '{sub}'"
                out2, _, _ = run_cmd(cmd2, cwd=repo_dir)
                files.extend([f.strip() for f in out2.splitlines() if f.strip()])

    return list(dict.fromkeys(files))

def categorize_files(files):
    categorized = {name: [] for name, _ in LAYER_RULES}
    categorized["Other (其他)"] = []

    for file_path in sorted(files):
        matched = False
        for name, pattern in LAYER_RULES:
            if re.search(pattern, file_path):
                categorized[name].append(file_path)
                matched = True
                break
        if not matched:
            categorized["Other (其他)"].append(file_path)

    return {k: v for k, v in categorized.items() if v}

def main():
    parser = argparse.ArgumentParser(description="Inspect ZDPOS feature scope")
    parser.add_argument("--branch", help="Git branch name")
    parser.add_argument("--anchor", help="Historical anchor string")
    parser.add_argument("--base", default="origin/master", help="Git base ref")
    parser.add_argument("--repo", default=".", help="Repository root")
    parser.add_argument("--json", action="store_true", help="Output JSON format")

    args = parser.parse_args()

    if not args.branch and not args.anchor:
        print("錯誤: 請至少指定 --branch 或 --anchor 參數", file=sys.stderr)
        sys.exit(1)

    if args.branch:
        files = inspect_by_branch(args.branch, args.base, args.repo)
    else:
        files = inspect_by_anchor(args.anchor, args.repo)

    result = categorize_files(files)

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return

    total_files = sum(len(v) for v in result.values())
    print(f"\n=======================================================")
    print(f" 盤點完成: 共找到 {total_files} 個相關檔案")
    print(f"=======================================================\n")

    for layer, layer_files in result.items():
        print(f"### {layer} ({len(layer_files)} 個檔案)")
        print("| 檔案路徑 | 角色建議 | 核心職責 | 關鍵函式/進入點 |")
        print("|---|---|---|---|")
        for f in layer_files:
            role = "Domain" if "domain" in f else ("Infra" if "infrastructure" in f else ("Controller" if "controllers" in f else ("CLI" if "commands" in f else "Other")))
            print(f"| [`{f}`](file://{os.path.abspath(f)}) | {role} |待補 | 待補 |")
        print("")

if __name__ == "__main__":
    main()
