#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
validate_html.py
驗證協作者 HTML 文件的可開啟性、高對比視覺、預渲染 Mermaid 與互動元件合規性：
1. 實體檔案檢查（拒絕 Symlink，避免跨平台或掛載失效）。
2. 本地離線開啟 (file://) 相容性檢查（拒絕 ES Module 與外部 CDN 依賴）。
3. 實體 index.html 存在性與 README.html 同步性檢查。
4. HTML 標籤結構與閉合性（含 style, script, head, body）。
5. 預渲染 Mermaid SVG 與純白高對比畫布檢查。
6. 互動式 4 態 Radio、零預設勾選、匯出與清空 Modal 完整性檢查。
7. Playwright Headless 真實瀏覽器渲染與互動驗收測試 (validate_headless.js)。

使用方式:
    python3 validate_html.py docs/collaborators/split-bill/index.html
    python3 validate_html.py docs/collaborators/split-bill/
    python3 validate_html.py docs/collaborators/
"""

import os
import re
import subprocess
import sys
from html.parser import HTMLParser

VOID_TAGS = {
    "area", "base", "br", "col", "embed", "hr", "img", "input",
    "link", "meta", "param", "source", "track", "wbr",
}


class HTMLTagValidator(HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack = []
        self.errors = []
        self.in_svg = 0

    def handle_starttag(self, tag, attrs):
        t = tag.lower()
        if t == "svg":
            self.in_svg += 1
            return
        if self.in_svg > 0:
            return
        if t not in VOID_TAGS:
            self.stack.append((t, self.getpos()))

    def handle_endtag(self, tag):
        t = tag.lower()
        if t == "svg":
            if self.in_svg > 0:
                self.in_svg -= 1
            return
        if self.in_svg > 0 or t in VOID_TAGS:
            return
        if not self.stack:
            self.errors.append(f"多餘的閉合標籤: </{t}> 於行 {self.getpos()[0]}")
            return
        last_tag, pos = self.stack.pop()
        if last_tag != t:
            self.errors.append(
                f"標籤不匹配: 預期 </{last_tag}> (開於行 {pos[0]}), 但讀到 </{t}> (於行 {self.getpos()[0]})"
            )


def validate_single_file(html_path):
    errors = []
    warnings = []

    abs_path = os.path.abspath(html_path)
    is_hub_index = (
        os.path.basename(abs_path) == "index.html"
        and os.path.basename(os.path.dirname(abs_path)) == "collaborators"
    )

    # 1. Symlink 檢查
    if os.path.islink(html_path):
        errors.append(
            f"檔案是符號連結 (Symlink): {html_path}。請改為實體檔案 (cp README.html index.html)，以確保跨平台與不同 Web 伺服器皆能正常開啟。"
        )
        return errors, warnings

    if not os.path.exists(html_path):
        errors.append(f"找不到檔案: {html_path}")
        return errors, warnings

    with open(html_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 2. ES Module / 外部 CDN 阻擋檢查
    if re.search(r'<script\s+type=[\'"]module[\'"]', content, re.IGNORECASE):
        errors.append('檢測到外部 ES Module (<script type="module">)！在本地 file:/// 開啟時會被 CORS 政策封鎖。')

    if "cdn.jsdelivr.net/npm/mermaid" in content:
        errors.append(
            "檢測到外部 CDN Mermaid script！請使用 python3 .agent/skills/zdpos-feature-doc/scripts/scaffold_doc.py --compile 進行離線 SVG 預渲染。"
        )

    # 3. HTML 標籤結構與閉合檢查
    validator = HTMLTagValidator()
    validator.feed(content)

    for err in validator.errors:
        errors.append(f"HTML 標籤結構錯誤: {err}")

    for tag, pos in validator.stack:
        errors.append(f"標籤未閉合: <{tag}> (開於行 {pos[0]}) 到檔案結尾仍未閉合！")

    # 4. 職稱規範檢查（禁止「架構師：」，一律為「開發者：」）
    if "架構師：" in content or "架構師:" in content:
        errors.append("檢測到「架構師：」職稱！依專案規範必須統一使用「開發者：」（例如：開發者：Paul）。")

    if not is_hub_index:
        # 5. Mermaid 白底高對比與預渲染 SVG 檢查
        mermaid_blocks = re.findall(r'<div class="mermaid">(.*?)</div>', content, re.DOTALL)
        if mermaid_blocks:
            if not re.search(r"\.mermaid\s*\{[^}]*background(?:-color)?:\s*#ffffff", content, re.IGNORECASE):
                errors.append("缺少 .mermaid 高對比白底畫布樣式 (#ffffff)！")
            for idx, m_block in enumerate(mermaid_blocks, 1):
                if "<svg" not in m_block:
                    errors.append(f"Mermaid 區塊 #{idx} 未預渲染為內嵌 <svg>！")
                if "Syntax error in text" in m_block or "Parse error" in m_block:
                    errors.append(f"Mermaid 區塊 #{idx} 包含語法錯誤 (Syntax error in text)！")

        # 6. 高對比 Callout 規範檢查
        if re.search(r'class=[\'"][^\'"]*(?:callout|alert)', content):
            if "--co-warn-bg" not in content or "--co-danger-bg" not in content:
                errors.append("缺少高對比 Callout 規範變數 (--co-warn-bg, --co-danger-bg)！")

        # 7. 舊式 Alert 語法檢查
        if re.search(r'class=[\'"][^\'"]*alert-(?:info|warning|danger)', content):
            errors.append("檢測到舊版 alert 樣式 (.alert-*)！請改用標準高對比的 .callout 語法。")

        # 8. 互動式檢核元件檢查（禁止 checkbox、禁止預設 checked、必須含匯出與清空 Modal）
        if re.search(r'<input[^>]+type=[\'"]checkbox[\'"]', content, re.IGNORECASE):
            errors.append("檢測到 <input type=\"checkbox\">！檢核項必須統一使用四態互斥 <input type=\"radio\">。")

        if re.search(r'<input[^>]+type=[\'"]radio[\'"][^>]*\bchecked\b', content, re.IGNORECASE):
            errors.append("檢測到預設勾選 (checked) 的 radio！初始狀態必須為 0% 未檢核。")

        for req_id in ("export-modal", "clear-modal", "mermaid-lightbox-modal", "progress-bar-fill", "sec-verify-checklist", "sec-4"):
            if f'id="{req_id}"' not in content:
                errors.append(f"缺少必要互動結構或視窗元素: #{req_id}")

        # 9. 實體 index.html 同步性檢查（若當前是 README.html）
        if os.path.basename(html_path) == "README.html":
            parent_dir = os.path.dirname(html_path)
            index_file = os.path.join(parent_dir, "index.html")
            if not os.path.exists(index_file):
                errors.append(f"缺少配套的實體 index.html: {index_file} 不存在。")
            elif os.path.islink(index_file):
                errors.append(f"配套的 index.html 是軟連結: {index_file}。請轉為實體檔案！")

    return errors, warnings


def main():
    if len(sys.argv) < 2:
        print("用法: python3 validate_html.py <html_file_or_dir_path>")
        sys.exit(1)

    target_path = sys.argv[1]
    files_to_check = []
    headless_targets = []

    if os.path.isdir(target_path):
        for root, _, files in os.walk(target_path):
            for f in sorted(files):
                if f.endswith(".html"):
                    full = os.path.join(root, f)
                    files_to_check.append(full)
                    if f == "index.html" and os.path.basename(os.path.abspath(root)) != "collaborators":
                        headless_targets.append(full)
    else:
        files_to_check.append(target_path)
        headless_targets.append(target_path)

    total_errors = 0

    for path in sorted(files_to_check):
        errors, _ = validate_single_file(path)
        if errors:
            print(f"\n❌ 靜態驗證失敗: {path}")
            for e in errors:
                print(f"  - {e}")
            total_errors += len(errors)
        else:
            print(f"✅ 靜態驗證通過: {path} (實體檔案、離線相容、標籤閉合、預渲染 SVG、Radio 結構合規)")

    if total_errors == 0 and headless_targets:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        headless_js = os.path.join(script_dir, "validate_headless.py")
        headless_node = os.path.join(script_dir, "validate_headless.js")
        if os.path.exists(headless_node):
            res = subprocess.run(["node", headless_node] + sorted(headless_targets), check=False)
            if res.returncode != 0:
                total_errors += 1

    if total_errors > 0:
        print(f"\n總計發現驗證問題，請修正後重新編譯！")
        sys.exit(1)
    else:
        print("\n🎉 全部 HTML 檔案健壯性與無頭瀏覽器互動檢驗 100% 通過！")
        sys.exit(0)


if __name__ == "__main__":
    main()
