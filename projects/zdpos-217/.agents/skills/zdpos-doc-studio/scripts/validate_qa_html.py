#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
validate_qa_html.py
用於驗證 QA 手動測試手冊 HTML 檔案之完整性與防護規範：
1. 確保所有 {{...}} 模板佔位符皆已替換完畢
2. 靜態驗證所有 Mermaid 圖表（含預渲染原始碼與動態區塊）無語法錯誤或未引號括號
3. 驗證高對比色彩規範（禁止暗色模式半透明混濁背景、強制 Mermaid 白底深字畫布）
4. 驗證互動式 Radio 元件、零初始狀態、單題重置、匯出視窗與全部清空視窗結構齊備
5. 自動調用 Playwright 無頭瀏覽器 (validate_headless.js) 進行真實 DOM 與互動行為全自動驗收
"""

import html as html_lib
import os
import re
import subprocess
import sys

VALID_MERMAID_TYPES = (
    "flowchart",
    "graph",
    "sequenceDiagram",
    "stateDiagram",
    "stateDiagram-v2",
    "classDiagram",
    "erDiagram",
    "gantt",
    "pie",
    "mindmap",
)


def validate_placeholders(content):
    """檢查是否殘留未替換的 {{PLACEHOLDER}} 標籤。"""
    errors = []
    matches = re.findall(r"\{\{[A-Z0-9_]+\}\}", content)
    if matches:
        unique_matches = sorted(list(set(matches)))
        errors.append(f"發現未替換的模板佔位符: {', '.join(unique_matches)}")
    return errors


def validate_mermaid(content):
    """檢查所有 Mermaid 區塊（含預渲染與非預渲染）之語法合規性。"""
    errors = []

    raw_blocks = re.findall(r'<(?:div|pre)\s+class="mermaid"[^>]*>(.*?)</(?:div|pre)>', content, re.DOTALL)
    src_blocks = re.findall(
        r'<details\s+class="mermaid-source-details"[^>]*>.*?<pre><code>(.*?)</code></pre>.*?</details>',
        content,
        re.DOTALL,
    )
    blocks = raw_blocks + [html_lib.unescape(b) for b in src_blocks]

    # 檢查是否有預渲染容器卻缺失 SVG
    diagram_divs = re.findall(r'<div\s+class="mermaid-diagram"[^>]*>(.*?)</div>', content, re.DOTALL)
    for idx, d_html in enumerate(diagram_divs, 1):
        if "<svg" not in d_html:
            errors.append(f"Mermaid 預渲染容器 #{idx} 內缺少 <svg> 元素。")

    for idx, block in enumerate(blocks, 1):
        lines = [line.strip() for line in block.strip().splitlines() if line.strip()]
        if not lines:
            errors.append(f"Mermaid 區塊 #{idx} 內容為空。")
            continue

        first_line = ""
        for line in lines:
            if not line.startswith("%%"):
                first_line = line
                break

        if not first_line:
            errors.append(f"Mermaid 區塊 #{idx} 僅包含註解，無有效圖表宣告。")
            continue

        if not any(first_line.startswith(t) for t in VALID_MERMAID_TYPES):
            errors.append(
                f"Mermaid 區塊 #{idx} 開頭宣告無效: '{first_line}'。"
                f"必須為 {', '.join(VALID_MERMAID_TYPES)} 之一。"
            )

        if "```" in block:
            errors.append(f"Mermaid 區塊 #{idx} 內殘留 Markdown 圍欄符號 (```)，會導致渲染失敗。")

        is_flowchart = first_line.startswith("flowchart") or first_line.startswith("graph")
        if is_flowchart:
            for line_num, line in enumerate(lines, 1):
                if line.startswith("%%"):
                    continue
                # 檢查 subgraph ID[Title (with parens)] 未加雙引號
                sg_m = re.match(r"^subgraph\s+[A-Za-z0-9_-]+\s*\[(.*)\]$", line)
                if sg_m:
                    sg_inner = sg_m.group(1).strip()
                    if not (sg_inner.startswith('"') and sg_inner.endswith('"')) and (
                        "(" in sg_inner or ")" in sg_inner
                    ):
                        errors.append(
                            f"Mermaid 區塊 #{idx} 第 {line_num} 行 subgraph 標題含括號卻未加雙引號: [{sg_inner}]"
                        )
                # 檢查節點 [label] 內有 () 卻未加雙引號
                rect_nodes = re.findall(r'\b[A-Za-z0-9_]+\[(?!")([^\]\n]+)\]', line)
                for inner in rect_nodes:
                    s_in = inner.strip()
                    if s_in.startswith('"') and s_in.endswith('"'):
                        continue
                    if "(" in s_in or ")" in s_in:
                        errors.append(
                            f"Mermaid 區塊 #{idx} 第 {line_num} 行節點標籤含半形括號卻未加雙引號: [{s_in}]"
                        )
                # 檢查連線標籤 |...| 內有 () 卻未加雙引號
                edge_labels = re.findall(r"\|([^|\n]+)\|", line)
                for edge in edge_labels:
                    s_ed = edge.strip()
                    if s_ed.startswith('"') and s_ed.endswith('"'):
                        continue
                    if "(" in s_ed or ")" in s_ed or "[" in s_ed or "]" in s_ed:
                        errors.append(
                            f"Mermaid 區塊 #{idx} 第 {line_num} 行連線標籤含括號卻未加雙引號: |{s_ed}|"
                        )

    return errors, len(blocks)


def validate_contrast_and_styles(content):
    """檢查 Mermaid 白底畫布與深色模式高對比色彩規範。"""
    errors = []
    if not re.search(r"\.mermaid(?:-container)?\s*[^{]*\{[^}]*background(?:-color)?\s*:\s*(?:#fff|#ffffff)\s*!important", content, re.IGNORECASE | re.DOTALL):
        errors.append("缺少 .mermaid / .mermaid-container 的高對比白底強制樣式 (background: #ffffff !important)。")

    # 禁止舊版暗色模式半透明混濁背景色碼 (#1e3a8a33, #14532d33, #7f1d1d33, #78350f33)
    muddy_alphas = re.findall(r"#(?:1e3a8a33|14532d33|7f1d1d33|78350f33)", content, re.IGNORECASE)
    if muddy_alphas:
        errors.append(
            f"發現舊版低對比半透明暗色背景變數 ({', '.join(set(muddy_alphas))})，請改用高對比純色面板變數。"
        )

    # 禁止強制將窄型圖表硬拉到 600px 的舊規則
    if re.search(r"\.mermaid-diagram\s+svg\s*\{[^}]*min-width\s*:\s*600px", content):
        errors.append("發現 .mermaid-diagram svg { min-width: 600px } 舊版失真規則，請移除以避免垂直流程圖變形。")

    return errors


def validate_interactive_features(content):
    """檢查互動式 QA 手冊必備之 DOM 與邏輯特徵。"""
    errors = []
    if "localStorage" not in content:
        errors.append("缺少 localStorage 狀態自動保存邏輯。")

    has_tc_cards = ('class="tc' in content) or ('class="case' in content)
    if not has_tc_cards:
        errors.append("缺少可折疊之測試案例卡片 (<details class=\"tc\"> 或 <details class=\"case\">)。")

    if 'type="radio"' not in content and "type=radio" not in content:
        errors.append("缺少四態單選判定按鈕 (input[type=\"radio\"])。")

    # 檢查是否有靜態預選之 checked 屬性
    checked_radios = re.findall(r'<input[^>]+type=["\']?radio["\']?[^>]*\bchecked\b[^>]*>', content, re.IGNORECASE)
    if checked_radios:
        errors.append(f"發現 {len(checked_radios)} 個靜態預設 checked 之 radio，違反初始零狀態 (0%) 原則。")

    if "btn-clear-verdict" not in content and "rbtn-clear" not in content:
        errors.append("缺少單一案例重置按鈕 (.btn-clear-verdict 或 .rbtn-clear)。")

    if "export-modal" not in content and "exportModal" not in content:
        errors.append("缺少測試結果匯出視窗 (#export-modal)。")

    if "reset-modal" not in content and "resetModal" not in content:
        errors.append("缺少清空全部紀錄確認視窗 (#reset-modal)。")

    return errors


def run_playwright_headless_validation(filepath):
    """調用同目錄下的 validate_headless.js 進行真實無頭瀏覽器全功能驗收。"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    headless_js = os.path.join(script_dir, "validate_headless.js")

    if not os.path.exists(headless_js):
        return [f"找不到無頭瀏覽器驗證腳本: {headless_js}"]

    try:
        res = subprocess.run(
            ["node", headless_js, filepath],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=45,
        )
        out = res.stdout.decode("utf-8", errors="ignore").strip()
        err = res.stderr.decode("utf-8", errors="ignore").strip()
        if out:
            for line in out.splitlines():
                print(f"  {line}")
        if res.returncode != 0:
            err_lines = [line.strip() for line in err.splitlines() if line.strip()]
            return err_lines if err_lines else ["Playwright 無頭瀏覽器動態驗證未通過。"]
        return []
    except Exception as e:
        return [f"執行 Playwright 驗證時發生例外: {str(e)}"]


def validate_file(filepath):
    """驗證單一 HTML 檔案。"""
    print(f"🔍 正在驗證: {filepath}")
    if not os.path.exists(filepath):
        print(f"  ❌ 檔案不存在: {filepath}")
        return False

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    all_errors = []

    ph_errors = validate_placeholders(content)
    if ph_errors:
        all_errors.extend(ph_errors)
    else:
        print("  ✅ 模板佔位符檢查通過")

    mm_errors, mm_count = validate_mermaid(content)
    if mm_errors:
        all_errors.extend(mm_errors)
    else:
        print(f"  ✅ Mermaid 語法與結構靜態檢查通過 ({mm_count} 個圖表)")

    style_errors = validate_contrast_and_styles(content)
    if style_errors:
        all_errors.extend(style_errors)
    else:
        print("  ✅ 高對比度色彩與 Mermaid 白底畫布檢查通過")

    ui_errors = validate_interactive_features(content)
    if ui_errors:
        all_errors.extend(ui_errors)
    else:
        print("  ✅ 互動式單選、匯出與重置結構靜態檢查通過")

    pw_errors = run_playwright_headless_validation(filepath)
    if pw_errors:
        all_errors.extend(pw_errors)

    if all_errors:
        for err in all_errors:
            print(f"  ❌ {err}")
        return False

    return True


def main():
    if len(sys.argv) < 2:
        print("用法: python3 validate_qa_html.py <path_to_html_or_directory>")
        sys.exit(1)

    target = sys.argv[1]
    files_to_check = []

    if os.path.isdir(target):
        for root, _, files in os.walk(target):
            for file in files:
                if file.startswith("QA-") and file.endswith("-manual.html"):
                    files_to_check.append(os.path.join(root, file))
    else:
        files_to_check.append(target)

    if not files_to_check:
        print("⚠️ 未找到任何 .html 檔案可供驗證。")
        sys.exit(0)

    all_passed = True
    for fpath in sorted(files_to_check):
        if not validate_file(fpath):
            all_passed = False
        print("-" * 60)

    if not all_passed:
        print("❌ QA HTML 驗證失敗！請修正上述問題後重新執行驗證。")
        sys.exit(1)
    else:
        print("🎉 所有 QA HTML 檔案皆通過靜態與 Playwright 瀏覽器互動驗證！")
        sys.exit(0)


if __name__ == "__main__":
    main()
