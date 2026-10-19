#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
doc_studio.py — zdpos-doc-studio 統一命令列入口 (Unified CLI Orchestrator)
整合「範圍盤點 (inspect)」、「雙模態腳手架 (scaffold)」、「無損編譯 (compile)」與「雙重門禁驗證 (validate)」。
支援三種模式：
  - feature : 協作者技術與維護手冊 (docs/collaborators/<slug>/README.md & index.html)
  - qa      : QA 手動測試驗收手冊 (docs/qa/<module>/QA-<slug>-manual.md & .html)
  - both    : 單次盤點、雙軌同步建立／編譯／驗證協作者手冊與 QA 驗收手冊
"""

import argparse
import os
import subprocess
import sys


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def run_cmd(cmd):
    res = subprocess.run(cmd)
    return res.returncode


def detect_target_mode(target_path):
    norm = os.path.normpath(target_path).replace("\\", "/")
    if "docs/qa" in norm or os.path.basename(norm).startswith("QA-"):
        return "qa"
    if "docs/collaborators" in norm:
        return "feature"
    return "feature"


def cmd_inspect(args, extra):
    cmd = [sys.executable, os.path.join(SCRIPT_DIR, "inspect_scope.py")]
    if args.anchor:
        cmd.extend(["--anchor", args.anchor])
    if args.base:
        cmd.extend(["--base", args.base])
    if args.repo:
        cmd.extend(["--repo", args.repo])
    cmd.extend(extra)
    sys.exit(run_cmd(cmd))


def cmd_scaffold(args):
    mode = args.mode
    if not args.slug or not args.title:
        print("❌ scaffold 需提供 --slug 與 --title 參數", file=sys.stderr)
        sys.exit(2)

    rc = 0
    if mode in ("feature", "both"):
        cmd = [
            sys.executable,
            os.path.join(SCRIPT_DIR, "scaffold_doc.py"),
            "--slug", args.slug,
            "--title", args.title,
        ]
        if args.anchor:
            cmd.extend(["--anchor", args.anchor])
        if args.migration:
            cmd.append("--migration")
        rc = run_cmd(cmd)
        if rc != 0:
            sys.exit(rc)

    if mode in ("qa", "both"):
        module_name = args.module or args.slug
        cmd = [
            sys.executable,
            os.path.join(SCRIPT_DIR, "scaffold_qa.py"),
            "--module", module_name,
            "--slug", args.slug,
            "--title", args.title,
            "--env", args.env,
        ]
        rc = run_cmd(cmd)
        if rc != 0:
            sys.exit(rc)


def cmd_compile(args):
    mode = args.mode
    targets = args.targets or []

    if not targets:
        if mode == "feature":
            targets = ["docs/collaborators"]
        elif mode == "qa":
            targets = ["docs/qa"]
        elif mode == "both":
            targets = ["docs/collaborators", "docs/qa"]
        else:
            print("❌ 請指定要編譯的目標路徑，或搭配 --mode feature|qa|both", file=sys.stderr)
            sys.exit(2)

    for t in targets:
        t_mode = detect_target_mode(t) if mode == "auto" else mode
        if t_mode == "both":
            t_mode = detect_target_mode(t)
        if t_mode == "qa":
            rc = run_cmd([sys.executable, os.path.join(SCRIPT_DIR, "scaffold_qa.py"), "--compile", t])
        else:
            rc = run_cmd([sys.executable, os.path.join(SCRIPT_DIR, "scaffold_doc.py"), "--compile", t])
        if rc != 0:
            sys.exit(rc)


def cmd_validate(args):
    mode = args.mode
    targets = args.targets or []

    if not targets:
        if mode == "feature":
            targets = ["docs/collaborators"]
        elif mode == "qa":
            targets = ["docs/qa"]
        else:
            targets = ["docs/collaborators", "docs/qa"]

    for t in targets:
        t_mode = detect_target_mode(t) if mode in ("auto", "both") else mode
        if t_mode == "qa":
            rc = run_cmd([sys.executable, os.path.join(SCRIPT_DIR, "validate_qa_html.py"), t])
        else:
            rc = run_cmd([sys.executable, os.path.join(SCRIPT_DIR, "validate_html.py"), t])
        if rc != 0:
            sys.exit(rc)


def main():
    parser = argparse.ArgumentParser(
        description="zdpos-doc-studio 統一技術文件與 QA 手冊工作台 CLI"
    )
    sub = parser.add_subparsers(dest="action", required=True)

    # 1. inspect
    p_insp = sub.add_parser("inspect", help="盤點 Git 分支或 Anchor 影響範圍")
    p_insp.add_argument("--anchor", help="歷史 Anchor 關鍵字 (如 '2025/12/02 paul')")
    p_insp.add_argument("--base", default="master", help="Git 比對基底分支 (預設: master)")
    p_insp.add_argument("--repo", default=".", help="儲存庫路徑")

    # 2. scaffold
    p_scaf = sub.add_parser("scaffold", help="建立協作者手冊、QA 手冊或雙軌腳手架")
    p_scaf.add_argument("--mode", choices=["feature", "qa", "both"], default="both", help="產出模式 (feature | qa | both)")
    p_scaf.add_argument("--slug", required=True, help="功能英文短名 (如 tax-id-validation-api)")
    p_scaf.add_argument("--title", required=True, help="功能中文標題")
    p_scaf.add_argument("--module", help="QA 模組目錄名稱 (如 pickup, split-bill；未指定時預設同 slug)")
    p_scaf.add_argument("--anchor", default="", help="開發 Anchor 字串")
    p_scaf.add_argument("--env", default="DEV / LOCAL", help="QA 測試環境座標")
    p_scaf.add_argument("--migration", action="store_true", help="協作者手冊是否包含既有客戶導入 SOP")

    # 3. compile
    p_comp = sub.add_parser("compile", help="將 Markdown SSOT 無損編譯為高對比互動式 HTML 並自動執行雙重驗證")
    p_comp.add_argument("--mode", choices=["auto", "feature", "qa", "both"], default="auto", help="編譯模式 (預設 auto 依路徑自動判斷)")
    p_comp.add_argument("targets", nargs="*", help="目標 Markdown 檔案或目錄路徑")

    # 4. validate
    p_val = sub.add_parser("validate", help="執行靜態語法檢驗與 Playwright 無頭瀏覽器實機互動驗收")
    p_val.add_argument("--mode", choices=["auto", "feature", "qa", "both"], default="auto", help="驗證模式 (預設 auto 依路徑自動判斷)")
    p_val.add_argument("targets", nargs="*", help="目標 HTML 檔案或目錄路徑")

    args, extra = parser.parse_known_args()
    if args.action == "inspect":
        cmd_inspect(args, extra)
    elif args.action == "scaffold":
        cmd_scaffold(args)
    elif args.action == "compile":
        cmd_compile(args)
    elif args.action == "validate":
        cmd_validate(args)


if __name__ == "__main__":
    main()
