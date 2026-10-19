#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scaffold_doc.py
快速初始化與無損編譯 ZDPOS 協作者技術手冊 (Markdown SSOT -> 互動式高對比 HTML)。

支援兩種模式:
1. 初始化並編譯骨架:
   python3 scaffold_doc.py --slug new-feature --title "新功能模組名稱" --anchor "2026/01/01 paul [topic]"
2. 將既有 README.md 無損編譯為 README.html 與實體 index.html (含 Mermaid SVG 預渲染與自動驗證):
   python3 scaffold_doc.py --compile docs/collaborators/split-bill/README.md
   python3 scaffold_doc.py --compile docs/collaborators/split-bill/
   python3 scaffold_doc.py --compile docs/collaborators/
"""

import argparse
import html
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile


def slugify_heading(text):
    clean = re.sub(r"<[^>]+>", "", text)
    clean = re.sub(r"[`*_~]", "", clean).strip().lower()
    clean = re.sub(r"[^\w\u4e00-\u9fff\s-]", "", clean)
    clean = re.sub(r"[\s]+", "-", clean)
    return clean or "section"


def sanitize_mermaid_code(code):
    """
    自動修復 Mermaid 10.9.x 常見語法地雷：
    1. 保護已加雙引號的節點 ID["..."]、ID{"..."}、ID(["..."])、ID[("...")]。
    2. 自動為含 ()、{}、[]、<br/>、:、; 的未加引號節點與連線標籤 |...| 補上雙引號。
    3. 自動為含空白或括號的 subgraph ID [Title] 標題補上雙引號。
    4. 將 classDiagram 誤混入 flowchart 的 <|-- / <|.. 轉換為相容箭頭。
    """
    lines = code.strip().splitlines()
    if not lines:
        return code

    first_non_empty = ""
    for l in lines:
        s = l.strip()
        if s and not s.startswith("%%"):
            first_non_empty = s
            break

    is_flowchart = bool(re.match(r"^(flowchart|graph)\b", first_non_empty))
    is_sequence = bool(re.match(r"^sequenceDiagram\b", first_non_empty))

    out_lines = []
    for raw_line in lines:
        line = raw_line
        stripped = line.strip()
        if not stripped or stripped.startswith("%%"):
            out_lines.append(line)
            continue

        if is_flowchart:
            line = line.replace("<|..", "-.->").replace("<|--", "-->")

            # Subgraph title quoting: subgraph ID [Unquoted Title (with parens)]
            m_sub = re.match(r'^(\s*subgraph\s+[A-Za-z0-9_.-]+\s*)\[\s*(?!")([^\]\n]+)\s*\]\s*$', line)
            if m_sub:
                prefix, title = m_sub.group(1), m_sub.group(2).strip()
                title_clean = title.replace('"', "'")
                line = f'{prefix}["{title_clean}"]'
                out_lines.append(line)
                continue

            # Edge label |...| quoting when containing (), {}, [], <br>, :, /
            def fix_edge_label(m):
                inner = m.group(1).strip()
                if (inner.startswith('"') and inner.endswith('"')) or (inner.startswith("'") and inner.endswith("'")):
                    return m.group(0)
                if any(ch in inner for ch in ("(", ")", "{", "}", "[", "]", "<br", ":", ";")):
                    escaped = inner.replace('"', "'")
                    return f'|"{escaped}"|'
                return m.group(0)

            line = re.sub(r"\|([^|\n]+)\|", fix_edge_label, line)

            # Cylinder node ID[(...)]
            def fix_cylinder(m):
                nid, inner = m.group(1), m.group(2).strip()
                if inner.startswith('"') and inner.endswith('"'):
                    return m.group(0)
                escaped = inner.replace('"', "'")
                return f'{nid}[("{escaped}")]'

            line = re.sub(r'\b([A-Za-z0-9_]+)\s*\[\(\s*(?!")([^\n]+?)\s*\)\]', fix_cylinder, line)

            # Stadium node ID([...])
            def fix_stadium(m):
                nid, inner = m.group(1), m.group(2).strip()
                if inner.startswith('"') and inner.endswith('"'):
                    return m.group(0)
                escaped = inner.replace('"', "'")
                return f'{nid}(["{escaped}"])'

            line = re.sub(r'\b([A-Za-z0-9_]+)\s*\(\[\s*(?!")([^\n]+?)\s*\]\)', fix_stadium, line)

            # Rectangular node ID[...] (excluding [(...)] and ["..."])
            def fix_rect(m):
                nid, inner = m.group(1), m.group(2).strip()
                if inner.startswith('"') and inner.endswith('"'):
                    return m.group(0)
                if any(ch in inner for ch in ("(", ")", "{", "}", "<br", ":", ";", "/")):
                    escaped = inner.replace('"', "'")
                    return f'{nid}["{escaped}"]'
                return m.group(0)

            line = re.sub(r'\b([A-Za-z0-9_]+)\s*\[(?![\(\"\s]*\"|\()([^\]\n]+)\]', fix_rect, line)

            # Rhombus node ID{...} (excluding {{"..."}} and {"..."})
            def fix_rhombus(m):
                nid, inner = m.group(1), m.group(2).strip()
                if inner.startswith('"') and inner.endswith('"'):
                    return m.group(0)
                if any(ch in inner for ch in ("(", ")", "[", "]", "<br", ":", ";", "/")):
                    escaped = inner.replace('"', "'")
                    return f'{nid}{{"{escaped}"}}'
                return m.group(0)

            line = re.sub(r'\b([A-Za-z0-9_]+)\s*\{(?![\{\"\s]*\"|\{)([^\}\n]+)\}', fix_rhombus, line)

        elif is_sequence:
            # Ensure sequence message text doesn't break on unescaped HTML tags other than <br/>
            pass

        out_lines.append(line)

    return "\n".join(out_lines)


def batch_render_mermaid_svgs(mermaid_blocks, script_dir):
    if not mermaid_blocks:
        return []
    cli_js = os.path.join(script_dir, "render_mermaid_cli.js")
    if not os.path.exists(cli_js):
        qa_cli_js = os.path.abspath(os.path.join(script_dir, "..", "..", "zdpos-qa-doc", "scripts", "render_mermaid_cli.js"))
        if os.path.exists(qa_cli_js):
            cli_js = qa_cli_js

    sanitized = [sanitize_mermaid_code(b) for b in mermaid_blocks]
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f_in:
        json.dump(sanitized, f_in, ensure_ascii=False)
        in_path = f_in.name
    out_path = in_path + ".out.json"

    try:
        subprocess.run(
            ["node", cli_js, "--batch", in_path, out_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=60,
            check=False,
        )
        if os.path.exists(out_path):
            with open(out_path, "r", encoding="utf-8") as f_out:
                results = json.load(f_out)
            svgs = []
            for idx, item in enumerate(results):
                if isinstance(item, dict) and item.get("svg") and not item.get("error"):
                    svgs.append(item["svg"])
                elif isinstance(item, str) and "<svg" in item:
                    svgs.append(item)
                else:
                    err_msg = item.get("error") if isinstance(item, dict) else "Unknown render error"
                    print(f"⚠️ Mermaid 區塊 #{idx + 1} 預渲染警告: {err_msg}", file=sys.stderr)
                    svgs.append(f'<pre class="mermaid-fallback">{html.escape(sanitized[idx])}</pre>')
            return svgs
    except Exception as e:
        print(f"⚠️ Mermaid 批次渲染執行失敗: {e}", file=sys.stderr)
    finally:
        for p in (in_path, out_path):
            if os.path.exists(p):
                try:
                    os.remove(p)
                except OSError:
                    pass

    return [f'<pre class="mermaid-fallback">{html.escape(b)}</pre>' for b in sanitized]


def normalize_inline_spans(text):
    """將 Markdown 內嵌的舊式 <span style="background-color:..."> 轉為高對比 .badge"""
    def repl_span(m):
        style = m.group(1).lower()
        inner = m.group(2).strip()
        cls = "badge-slate"
        if any(k in style for k in ["#1a7f37", "#16a34a", "green"]):
            cls = "badge-green"
        elif any(k in style for k in ["#0969da", "#0284c7", "blue"]):
            cls = "badge-blue"
        elif any(k in style for k in ["#8250df", "#7c3aed", "purple"]):
            cls = "badge-purple"
        elif any(k in style for k in ["#bf8700", "#d97706", "amber", "orange"]):
            cls = "badge-amber"
        elif any(k in style for k in ["#cf222e", "#dc2626", "red"]):
            cls = "badge-red"
        return f'<span class="badge {cls}">{inner}</span>'

    return re.sub(r'<span\s+style="([^"]*)"[^>]*>(.*?)</span>', repl_span, text, flags=re.IGNORECASE | re.DOTALL)


def format_inline_md(text):
    """處理行內 Markdown 語法：行內 code、連結、粗體、斜體、內嵌 badge span"""
    if not text:
        return ""

    text = normalize_inline_spans(text)

    # 1. 保護行內 `code`
    code_tokens = []
    def save_code(m):
        idx = len(code_tokens)
        inner = html.escape(m.group(1))
        code_tokens.append(f"<code>{inner}</code>")
        return f"\x00CODE{idx}\x00"

    text = re.sub(r"`([^`\n]+)`", save_code, text)

    # 2. 保護允許的內嵌 HTML 標籤 (<br>, <br/>, <b>, </b>, <strong>, </strong>, <span class="badge...">, </span>, <code>, </code>)
    html_tokens = []
    def save_html(m):
        idx = len(html_tokens)
        html_tokens.append(m.group(0))
        return f"\x00HTML{idx}\x00"

    text = re.sub(
        r"</?(?:br\s*/?|b|strong|i|em|u|sub|sup|kbd|mark|span(?:\s+class=\"[^\"]*\")?|code)>",
        save_html,
        text,
        flags=re.IGNORECASE,
    )

    # 3. 處理 Markdown 連結 [label](url)
    link_tokens = []
    def save_link(m):
        idx = len(link_tokens)
        label = m.group(1)
        url = m.group(2).strip()
        # 處理 label 內可能已被替換的 CODE token
        label_escaped = html.escape(label)
        for c_i, c_val in enumerate(code_tokens):
            label_escaped = label_escaped.replace(f"\x00CODE{c_i}\x00", c_val)
        link_tokens.append(f'<a href="{html.escape(url)}">{label_escaped}</a>')
        return f"\x00LINK{idx}\x00"

    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", save_link, text)

    # 4. 轉義剩餘一般文字的 HTML 特殊字元
    text = html.escape(text, quote=False)

    # 5. 粗體與斜體
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<!\*)\*([^*\n]+)\*(?!\*)", r"<em>\1</em>", text)

    # 6. 還原 LINK, HTML, CODE tokens
    for idx, val in enumerate(link_tokens):
        text = text.replace(f"\x00LINK{idx}\x00", val)
    for idx, val in enumerate(html_tokens):
        text = text.replace(f"\x00HTML{idx}\x00", val)
    for idx, val in enumerate(code_tokens):
        text = text.replace(f"\x00CODE{idx}\x00", val)

    return text


def split_md_table_row(line):
    """安全切分 Markdown 表格列，保護行內 `a || b` 與跳脫字元 \\|"""
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|") and not s.endswith(r"\|"):
        s = s[:-1]

    # 保護行內 `...` 中的 |
    protected = []
    def protect_code(m):
        idx = len(protected)
        protected.append(m.group(0))
        return f"\x00TBLCODE{idx}\x00"

    s = re.sub(r"`[^`]*`", protect_code, s)
    s = s.replace(r"\|", "\x00ESCAPED_PIPE\x00")

    cells = s.split("|")
    out = []
    for c in cells:
        c = c.replace("\x00ESCAPED_PIPE\x00", "|")
        for idx, val in enumerate(protected):
            c = c.replace(f"\x00TBLCODE{idx}\x00", val)
        out.append(c.strip())
    return out


def render_table(table_lines):
    if len(table_lines) < 2:
        return ""
    headers = split_md_table_row(table_lines[0])
    body_rows = table_lines[2:]
    th_html = "".join(f"<th>{format_inline_md(h)}</th>" for h in headers)
    trs_html = []
    for r_line in body_rows:
        if not r_line.strip():
            continue
        cols = split_md_table_row(r_line)
        if len(cols) < len(headers):
            cols.extend([""] * (len(headers) - len(cols)))
        tds = "".join(f"<td>{format_inline_md(c)}</td>" for c in cols[:len(headers)])
        trs_html.append(f"<tr>{tds}</tr>")
    return (
        '<div class="table-responsive"><table>'
        f"<thead><tr>{th_html}</tr></thead>"
        f'<tbody>{"".join(trs_html)}</tbody>'
        "</table></div>"
    )


def detect_callout_tone(text):
    lower = text.lower()
    if any(k in lower for k in ["[!caution]", "[!danger]", "🚨", "🛑", "危險", "致命", "嚴禁", "#cf222e", "#dc2626", "#ffebe9"]):
        return "danger"
    if any(k in lower for k in ["[!warning]", "[!important]", "⚠️", "警告", "注意", "雷區", "避坑", "#d29922", "#d97706", "#fff8c5"]):
        return "warning"
    if any(k in lower for k in ["[!tip]", "✅", "成功", "#1a7f37", "#16a34a"]):
        return "success"
    return "info"


def render_markdown_blocks(md_text, mermaid_collector):
    """將章節內的 Markdown 區塊無損轉譯為高對比 HTML"""
    lines = md_text.splitlines()
    n = len(lines)
    i = 0
    out = []

    while i < n:
        line = lines[i]
        stripped = line.strip()

        # 1. 空行或水平分隔線
        if not stripped:
            i += 1
            continue
        if re.match(r"^-{3,}\s*$", stripped) or re.match(r"^\*{3,}\s*$", stripped):
            i += 1
            continue

        # 2. Fenced Code Block (```lang ... ```)
        m_fence = re.match(r"^(`{3,}|~{3,})\s*([A-Za-z0-9_+-]*)\s*$", stripped)
        if m_fence:
            fence_marker = m_fence.group(1)
            lang = m_fence.group(2).strip().lower()
            i += 1
            code_lines = []
            while i < n and not re.match(rf"^\s*{re.escape(fence_marker)}\s*$", lines[i]):
                code_lines.append(lines[i])
                i += 1
            if i < n:
                i += 1  # skip closing fence
            raw_code = "\n".join(code_lines)

            if lang == "mermaid":
                idx = len(mermaid_collector)
                mermaid_collector.append(raw_code)
                out.append(f'<div class="mermaid">__MERMAID_PLACEHOLDER_{idx}__</div>')
            else:
                is_ascii_box = (not lang) and any(ch in raw_code for ch in ("┌", "─", "│", "└", "┘", "┐", "┤", "├", "┬", "┴", "▼", "►", "◄"))
                if is_ascii_box:
                    out.append(
                        '<div class="code-block-wrap">'
                        '<div class="code-lang-bar">ARCHITECTURE / ASCII DIAGRAM</div>'
                        f'<pre class="ascii-diagram"><code>{html.escape(raw_code)}</code></pre>'
                        "</div>"
                    )
                else:
                    lang_label = lang.upper() if lang else "CODE"
                    lang_cls = f' class="language-{html.escape(lang)}"' if lang else ""
                    out.append(
                        '<div class="code-block-wrap">'
                        f'<div class="code-lang-bar">{html.escape(lang_label)}</div>'
                        f"<pre><code{lang_cls}>{html.escape(raw_code)}</code></pre>"
                        "</div>"
                    )
            continue

        # 3. <details> 摺疊區塊 (內部遞迴解析 Markdown!)
        if stripped.lower().startswith("<details"):
            i += 1
            det_lines = []
            summary_html = "點擊展開詳細內容"
            while i < n and not lines[i].strip().lower().startswith("</details>"):
                cur_s = lines[i].strip()
                m_sum = re.match(r"^<summary>(.*?)</summary>$", cur_s, re.IGNORECASE)
                if m_sum:
                    summary_html = m_sum.group(1)
                else:
                    det_lines.append(lines[i])
                i += 1
            if i < n:
                i += 1  # skip </details>
            inner_rendered = render_markdown_blocks("\n".join(det_lines), mermaid_collector)
            out.append(f"<details><summary>{summary_html}</summary>\n{inner_rendered}\n</details>")
            continue

        # 4. 原始 HTML <div style="...border-left..."> 或 <div class="callout...">
        if stripped.lower().startswith("<div"):
            div_buf = [line]
            depth = line.lower().count("<div") - line.lower().count("</div>")
            i += 1
            while i < n and depth > 0:
                div_buf.append(lines[i])
                depth += lines[i].lower().count("<div") - lines[i].lower().count("</div>")
                i += 1
            raw_div = "\n".join(div_buf)
            tone = detect_callout_tone(raw_div)
            # 抽取內部文字，移除外層帶有淺色死底的 <div style="...">
            inner_div = re.sub(r"^<div[^>]*>", "", raw_div.strip(), count=1, flags=re.IGNORECASE)
            inner_div = re.sub(r"</div>\s*$", "", inner_div.strip(), flags=re.IGNORECASE)
            inner_div = normalize_inline_spans(inner_div)
            out.append(f'<div class="callout {tone}">\n{inner_div}\n</div>')
            continue

        # 5. Sub-headings (### / #### / #####)
        m_h = re.match(r"^(#{3,5})\s+(.+)$", stripped)
        if m_h:
            level = len(m_h.group(1))
            title_txt = m_h.group(2).strip()
            hid = slugify_heading(title_txt)
            tag = f"h{min(level, 4)}"
            out.append(f'<{tag} id="{hid}">{format_inline_md(title_txt)}</{tag}>')
            i += 1
            continue

        # 6. Blockquote / GitHub Alert (> ...)
        if stripped.startswith(">"):
            bq_lines = []
            while i < n and lines[i].strip().startswith(">"):
                content_part = re.sub(r"^>\s?", "", lines[i].strip())
                bq_lines.append(content_part)
                i += 1
            full_bq = "\n".join(bq_lines).strip()
            tone = detect_callout_tone(full_bq)
            # 移除 [!IMPORTANT] / [!WARNING] / [!NOTE] / [!TIP] / [!CAUTION] 標記
            title_map = {
                "[!important]": "📌 重要規範 (Important)",
                "[!warning]": "⚠️ 注意事項 (Warning)",
                "[!caution]": "🚨 關鍵警訊 (Caution)",
                "[!tip]": "💡 實作技巧 (Tip)",
                "[!note]": "ℹ️ 補充說明 (Note)",
            }
            callout_title = ""
            first_line_lower = bq_lines[0].strip().lower() if bq_lines else ""
            if first_line_lower in title_map:
                callout_title = title_map[first_line_lower]
                bq_lines = bq_lines[1:]
            body_html = "<br/>".join(format_inline_md(l) for l in bq_lines if l.strip())
            if callout_title:
                out.append(f'<div class="callout {tone}"><div class="callout-title">{callout_title}</div>{body_html}</div>')
            else:
                out.append(f'<div class="callout {tone}">{body_html}</div>')
            continue

        # 7. Markdown Table
        if stripped.startswith("|") and (i + 1 < n) and re.match(r"^\s*\|[\s:-]+\|", lines[i + 1]):
            tbl_lines = []
            while i < n and lines[i].strip().startswith("|"):
                tbl_lines.append(lines[i])
                i += 1
            out.append(render_table(tbl_lines))
            continue

        # 8. Unordered or Ordered Lists
        m_ul = re.match(r"^(\s*)([-*+])\s+(.+)$", line)
        m_ol = re.match(r"^(\s*)(\d+\.)\s+(.+)$", line)
        if m_ul or m_ol:
            list_tag = "ul" if m_ul else "ol"
            items_html = []
            while i < n:
                cur_line = lines[i]
                cur_s = cur_line.strip()
                if not cur_s:
                    i += 1
                    break
                m_u = re.match(r"^(\s*)([-*+])\s+(.+)$", cur_line)
                m_o = re.match(r"^(\s*)(\d+\.)\s+(.+)$", cur_line)
                if m_u or m_o:
                    item_txt = (m_u.group(3) if m_u else m_o.group(3)).strip()
                    i += 1
                    sub_lines = []
                    while i < n:
                        nxt = lines[i]
                        nxt_s = nxt.strip()
                        if not nxt_s:
                            break
                        if re.match(r"^(\s*)([-*+]|\d+\.)\s+", nxt) and len(re.match(r"^(\s*)", nxt).group(1)) == 0:
                            break
                        if re.match(r"^(#{1,5}\s+|`{3,}|<div|<details|\|)", nxt_s):
                            break
                        if re.match(r"^\s{2,}([-*+]|\d+\.)\s+(.+)$", nxt):
                            m_sub_li = re.match(r"^\s{2,}(?:[-*+]|\d+\.)\s+(.+)$", nxt)
                            sub_lines.append(f"<li>{format_inline_md(m_sub_li.group(1))}</li>")
                        else:
                            item_txt += " " + nxt_s
                        i += 1
                    if sub_lines:
                        items_html.append(f"<li>{format_inline_md(item_txt)}<ul>{''.join(sub_lines)}</ul></li>")
                    else:
                        items_html.append(f"<li>{format_inline_md(item_txt)}</li>")
                else:
                    break
            out.append(f"<{list_tag}>{''.join(items_html)}</{list_tag}>")
            continue

        # 9. Paragraph
        para_lines = [stripped]
        i += 1
        while i < n:
            nxt_s = lines[i].strip()
            if not nxt_s:
                break
            if re.match(r"^(#{1,5}\s+|`{3,}|~{3,}|>{1}|[-*+]\s+|\d+\.\s+|\||<div|<details|-{3,}|\*{3,})", nxt_s):
                break
            para_lines.append(nxt_s)
            i += 1
        out.append(f"<p>{format_inline_md(' '.join(para_lines))}</p>")

    return "\n".join(out)


def extract_verification_checkpoints(sections):
    """
    從協作者手冊的各章節（特別是 §6 導入 SOP、§7 維護指南、§8 測試與驗證）
    自動萃取結構化的「協作者導入與測試驗收檢核項 (CHK-01 .. CHK-NN)」。
    """
    checkpoints = []

    for sec in sections:
        sec_title = sec["title"]
        sec_body = sec["body"]

        # 從 §6 SOP 萃取 Step 1..N 或 6.x
        if any(k in sec_title for k in ["SOP", "導入", "部署", "設定", "遷移"]):
            steps = re.findall(r"^#{3,4}\s+(Step\s*\d+[^\n]*|\d+\.\d+\s+[^\n]*)$", sec_body, re.M | re.I)
            if not steps:
                steps = re.findall(r"^\d+\.\s+\*\*(Step\s*\d+[^*]+)\*\*", sec_body, re.M | re.I)
            for st in steps:
                clean_st = re.sub(r"[`*_]", "", st).strip()
                checkpoints.append({
                    "category": "導入與設定 SOP",
                    "title": clean_st,
                    "desc": f"依據「{sec_title}」章節規範，完成「{clean_st}」之環境確認、備份或指令操作。",
                })

        # 從 §8 測試與驗證萃取 8.x
        elif any(k in sec_title for k in ["測試", "驗證", "Testing", "Verification"]):
            sub_tests = re.findall(r"^#{3,4}\s+([^\n]+)$", sec_body, re.M)
            for st in sub_tests:
                clean_st = re.sub(r"[`*_]", "", st).strip()
                checkpoints.append({
                    "category": "自動化測試與驗證",
                    "title": clean_st,
                    "desc": f"執行「{clean_st}」所列之測試指令、語法檢查或驗收項目並確認全數通過。",
                })

    # 若章節內未抓到足夠細項，從核心章節自動產生標準協作者交接檢核項
    default_checks = [
        ("架構與邊界確認", "DDD 分層與雙層權限/環境開關確認", "確認 Presentation / Domain / Infrastructure 職責邊界與環境配置旗標符合手冊 §1–§3 規範。"),
        ("核心邏輯與邊界防護", "併發、例外降級與邊界條件核對", "確認關鍵業務邏輯、例外防護 (ExceptionLogHelper / EILogger) 與邊界條件符合手冊 §4 規範。"),
        ("資料契約與 Schema", "資料表 Schema、索引與 API 契約核對", "確認 Migration DDL、資料表欄位型別與前後端 API Payload 契約符合手冊 §5 規範。"),
        ("既有客戶導入 SOP", "向後相容 Fail-Safe 與導入步驟演練", "確認未啟用新制之既有客戶具備零中斷 Fallback 保護，且導入 SOP 步驟可安全執行。"),
        ("PHP 5.6 與自動化測試", "PHP 5.6 語法相容與測試套件全數通過", "執行 php -l 語法檢查與相關 PHPUnit / Jest 測試套件，確認 0 錯誤、0 退化。"),
    ]
    idx_def = 0
    while len(checkpoints) < 5 and idx_def < len(default_checks):
        cat, t, d = default_checks[idx_def]
        checkpoints.append({"category": cat, "title": t, "desc": d})
        idx_def += 1

    # 限制最多 12 項，並編號為 CHK-01 .. CHK-NN
    checkpoints = checkpoints[:12]
    for idx, cp in enumerate(checkpoints, 1):
        cp["id"] = f"CHK-{idx:02d}"
    return checkpoints


def build_verification_html(checkpoints):
    chips_html = []
    cards_html = []
    rows_html = []

    for cp in checkpoints:
        cid = cp["id"]
        title = html.escape(cp["title"])
        cat = html.escape(cp["category"])
        desc = html.escape(cp["desc"])

        chips_html.append(
            f'<a href="#card-{cid}" class="tc-chip" data-chip-tc="{cid}" data-status="">'
            f'<span class="chip-dot"></span>'
            f"<span>{cid}</span>"
            f'<span class="chip-status-text"></span>'
            f"</a>"
        )

        radios_card = []
        radios_row = []
        for val in ("Pass", "Fail", "Blocked", "N/A"):
            radios_card.append(
                f'<label class="radio-pill" data-val="{val}">'
                f'<input type="radio" name="tc_card_{cid}" value="{val}" data-tc-id="{cid}">'
                f"<span>{val}</span>"
                f"</label>"
            )
            radios_row.append(
                f'<label class="radio-pill" data-val="{val}" style="padding: 3px 8px; font-size: 12px;">'
                f'<input type="radio" name="tc_row_{cid}" value="{val}" data-tc-id="{cid}">'
                f"<span>{val}</span>"
                f"</label>"
            )

        cards_html.append(
            f'<div class="tc-card" id="card-{cid}" data-tc-id="{cid}" data-tc-title="{title}" data-status="">'
            f'  <div class="tc-header">'
            f'    <div class="tc-title-wrap">'
            f'      <span class="tc-id">{cid}</span>'
            f'      <span class="badge badge-slate">{cat}</span>'
            f'      <h3 class="tc-title">{title}</h3>'
            f"    </div>"
            f'    <span class="tc-status-badge">未檢核</span>'
            f"  </div>"
            f'  <div class="tc-body">{desc}</div>'
            f'  <div class="tc-controls">'
            f'    <div class="radio-group">{"".join(radios_card)}</div>'
            f'    <input type="text" class="tc-note-input" data-note-tc="{cid}" placeholder="填寫驗證紀錄、測試單號或備註...">'
            f'    <button type="button" class="tc-reset-btn" data-reset-tc="{cid}">↺ 重置</button>'
            f"  </div>"
            f"</div>"
        )

        rows_html.append(
            f'<tr data-summary-tc="{cid}" data-status="">'
            f'  <td><a href="#card-{cid}"><strong>{cid}</strong></a></td>'
            f"  <td><strong>{title}</strong><br/><span style=\"color: var(--muted); font-size: 12px;\">{cat}</span></td>"
            f'  <td><span class="tc-status-badge summary-status-badge">未檢核</span></td>'
            f'  <td><div class="radio-group">{"".join(radios_row)}</div></td>'
            f'  <td><input type="text" class="tc-note-input" data-note-tc="{cid}" style="width: 100%; min-width: 140px;" placeholder="備註..."></td>'
            f"</tr>"
        )

    return "\n".join(chips_html), "\n".join(cards_html), "\n".join(rows_html)


def compile_markdown_to_html(md_path, validate=True):
    md_path = os.path.abspath(md_path)
    if not os.path.exists(md_path):
        print(f"❌ 找不到 Markdown 檔案: {md_path}", file=sys.stderr)
        return False

    target_dir = os.path.dirname(md_path)
    slug = os.path.basename(target_dir)
    html_path = os.path.join(target_dir, "README.html")
    index_path = os.path.join(target_dir, "index.html")

    script_dir = os.path.dirname(os.path.abspath(__file__))
    tpl_path = os.path.join(script_dir, "..", "references", "html-template.html")
    with open(tpl_path, "r", encoding="utf-8") as f:
        tpl = f.read()

    with open(md_path, "r", encoding="utf-8") as f:
        md_raw = f.read()

    # 1. 擷取 H1 標題
    m_h1 = re.search(r"^#\s+(.+)$", md_raw, re.M)
    doc_title = m_h1.group(1).strip() if m_h1 else f"{slug} 協作者技術手冊"

    # 2. 擷取頂部 Metadata 表格 (於第一個 ## 之前)
    first_h2_pos = md_raw.find("\n## ")
    preamble = md_raw[:first_h2_pos] if first_h2_pos != -1 else md_raw
    meta_dict = {}
    for line in preamble.splitlines():
        s = line.strip()
        if s.startswith("|") and not re.match(r"^\|\s*[-:]+\s*\|", s):
            cols = split_md_table_row(s)
            if len(cols) >= 2:
                k = re.sub(r"[`*_]", "", cols[0]).strip().lower()
                v = cols[1].strip()
                if k not in ("欄位", "field", "property", "key"):
                    meta_dict[k] = v

    raw_author = re.sub(r"[`*_]", "", meta_dict.get("author", "Paul")).strip()
    raw_author = raw_author.replace("架構師：", "").replace("架構師:", "").replace("架構師", "").strip() or "Paul"
    anchor_str = re.sub(r"[`*_]", "", meta_dict.get("feature-anchor", slug)).strip()
    last_verified = re.sub(r"[`*_]", "", meta_dict.get("last-verified", "2026-10-19")).strip()

    meta_grid_items = []
    for k, v in meta_dict.items():
        v_clean = format_inline_md(v)
        meta_grid_items.append(
            f'<div class="meta-item"><span class="k">{html.escape(k)}</span><span class="v">{v_clean}</span></div>'
        )
    meta_grid_html = "\n".join(meta_grid_items)

    # 3. 切分 ## 章節
    parts = re.split(r"(?m)^##\s+(.+)$", md_raw)
    raw_sections = []
    for idx in range(1, len(parts), 2):
        sec_title = parts[idx].strip()
        sec_body = parts[idx + 1] if idx + 1 < len(parts) else ""
        raw_sections.append({"title": sec_title, "body": sec_body})

    badges_list = []
    lead_summary_html = ""
    content_sections = []

    badge_colors = ["badge-blue", "badge-green", "badge-purple", "badge-amber", "badge-red", "badge-slate"]

    for sec in raw_sections:
        stitle = sec["title"]
        sbody = sec["body"]
        if "快速導覽" in stitle:
            spans = re.findall(r"<span[^>]*>(.*?)</span>", sbody, re.I | re.S)
            for b_i, sp in enumerate(spans):
                b_txt = re.sub(r"<[^>]+>", "", sp).strip()
                if b_txt:
                    cls = badge_colors[b_i % len(badge_colors)]
                    badges_list.append(f'<span class="badge {cls}">{html.escape(b_txt)}</span>')
            bqs = re.findall(r"^>\s*(.+)$", sbody, re.M)
            if bqs:
                lead_txt = " ".join(b.strip() for b in bqs)
                lead_summary_html = f'<div class="lead-summary">{format_inline_md(lead_txt)}</div>'
            continue
        if "目錄" in stitle or "table of contents" in stitle.lower():
            continue
        content_sections.append(sec)

    if not badges_list:
        badges_list = [
            '<span class="badge badge-blue">核心模組 Core Module</span>',
            '<span class="badge badge-green">DDD 分層架構</span>',
            '<span class="badge badge-purple">PHP 5.6 嚴格相容</span>',
        ]

    # 4. 轉譯各章節內容並收集 Mermaid 圖表
    mermaid_collector = []
    nav_links = []
    sections_html = []

    legacy_id_map = {
        "1": "overview",
        "2": "architecture",
        "3": "file-map",
        "4": "business-logic",
        "5": "data-contracts",
        "6": "migration-sop",
        "7": "developer-guide",
        "8": "testing",
    }

    for idx, sec in enumerate(content_sections, 1):
        stitle = sec["title"]
        sbody = sec["body"]
        m_num = re.match(r"^(\d+)\.", stitle)
        num_key = m_num.group(1) if m_num else str(idx)
        sec_id = f"sec-{num_key}"
        legacy_id = legacy_id_map.get(num_key, f"section-{idx}")
        md_slug_id = slugify_heading(stitle)

        short_nav = re.sub(r"\s*\([^)]*\)\s*$", "", stitle).strip()
        nav_links.append(f'<a href="#{sec_id}" class="nav-item">{html.escape(short_nav)}</a>')

        rendered_body = render_markdown_blocks(sbody, mermaid_collector)
        sections_html.append(
            f'<section id="{sec_id}" class="section-card">'
            f'<span id="{legacy_id}"></span><span id="{md_slug_id}"></span>'
            f"<h2>{format_inline_md(stitle)}</h2>\n"
            f"{rendered_body}\n"
            f"</section>"
        )

    # 5. 批次預渲染所有 Mermaid 圖表為高對比內嵌 SVG
    full_sections_str = "\n\n".join(sections_html)
    if mermaid_collector:
        svgs = batch_render_mermaid_svgs(mermaid_collector, script_dir)
        for m_idx, svg_str in enumerate(svgs):
            full_sections_str = full_sections_str.replace(f"__MERMAID_PLACEHOLDER_{m_idx}__", svg_str)

    # 6. 產生互動式 SOP 與測試驗收檢核系統
    checkpoints = extract_verification_checkpoints(content_sections)
    chips_html, tc_cards_html, signoff_rows_html = build_verification_html(checkpoints)

    # 7. 組裝最終 HTML
    final_html = tpl
    final_html = final_html.replace("{{SLUG}}", slug)
    final_html = final_html.replace("{{TITLE}}", html.escape(doc_title))
    final_html = final_html.replace("{{ANCHOR}}", html.escape(anchor_str))
    final_html = final_html.replace("{{AUTHOR}}", html.escape(raw_author))
    final_html = final_html.replace("{{LAST_VERIFIED}}", html.escape(last_verified))
    final_html = final_html.replace("{{BADGES_HTML}}", "\n        ".join(badges_list))
    final_html = final_html.replace("{{LEAD_SUMMARY_HTML}}", lead_summary_html)
    final_html = final_html.replace("{{META_GRID_HTML}}", meta_grid_html)
    final_html = final_html.replace("{{NAV_LINKS}}", "\n    ".join(nav_links))
    final_html = final_html.replace("{{TOTAL_TCS}}", str(len(checkpoints)))
    final_html = final_html.replace("{{OVERVIEW_CHIPS}}", chips_html)
    final_html = final_html.replace("{{SECTIONS_HTML}}", full_sections_str)
    final_html = final_html.replace("{{TC_CARDS_HTML}}", tc_cards_html)
    final_html = final_html.replace("{{SIGNOFF_ROWS_HTML}}", signoff_rows_html)

    # 寫入 README.html 並同步複製為實體 index.html
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(final_html)

    if os.path.islink(index_path) or os.path.exists(index_path):
        os.remove(index_path)
    shutil.copyfile(html_path, index_path)

    print(
        f"✓ 編譯完成 [{slug}]: 章節={len(content_sections)}, "
        f"Mermaid預渲染={len(mermaid_collector)}, 檢核項={len(checkpoints)} -> {index_path}"
    )

    if validate:
        val_script = os.path.join(script_dir, "validate_html.py")
        if os.path.exists(val_script):
            res = subprocess.run([sys.executable, val_script, target_dir], check=False)
            if res.returncode != 0:
                return False

    return True


def register_in_hub_index(repo_root, slug, title, anchor, desc=""):
    hub_index_path = os.path.join(repo_root, "docs", "collaborators", "index.html")
    if not os.path.exists(hub_index_path):
        return
    with open(hub_index_path, "r", encoding="utf-8") as f:
        hub_content = f.read()
    target_link = f'href="{slug}/index.html"'
    if target_link not in hub_content:
        card_desc = desc or f"{title} 協作者架構、資料契約與維護指南。"
        card_html = f"""    <!-- {title} -->
    <a href="{slug}/index.html" class="card">
      <div>
        <span class="card-badge">Module</span>
        <h2 class="card-title">{html.escape(title)}</h2>
        <p class="card-desc">{html.escape(card_desc)}</p>
      </div>
      <div class="card-meta">
        <span class="card-anchor">{html.escape(anchor or slug)}</span>
        <span class="view-btn">進入手冊 →</span>
      </div>
    </a>\n"""
        hub_content = hub_content.replace('<div class="grid">', '<div class="grid">\n' + card_html, 1)
        with open(hub_index_path, "w", encoding="utf-8") as f:
            f.write(hub_content)
        print(f"✓ 已自動註冊至協作者手冊總覽頁: {hub_index_path}")


def main():
    parser = argparse.ArgumentParser(description="Scaffold and compile ZDPOS collaborator documentation")
    parser.add_argument("--compile", dest="compile_target", help="Compile README.md file or directory into HTML")
    parser.add_argument("--slug", help="Feature slug (e.g., split-bill)")
    parser.add_argument("--title", help="Feature Chinese title")
    parser.add_argument("--anchor", default="", help="Feature anchor or branch identifier")
    parser.add_argument("--migration", action="store_true", help="Include legacy migration SOP chapter")
    parser.add_argument("--repo", default=".", help="Repository root")
    parser.add_argument("--no-validate", action="store_true", help="Skip automatic validation after compile")

    args = parser.parse_args()

    # 模式 A：--compile 無損編譯模式
    if args.compile_target:
        target = args.compile_target
        md_files = []
        if os.path.isdir(target):
            direct_md = os.path.join(target, "README.md")
            if os.path.exists(direct_md):
                md_files.append(direct_md)
            else:
                for root, _, files in os.walk(target):
                    if "README.md" in files:
                        md_files.append(os.path.join(root, "README.md"))
        elif os.path.isfile(target):
            md_files.append(target)
        else:
            print(f"❌ 找不到指定路徑: {target}", file=sys.stderr)
            sys.exit(1)

        all_ok = True
        for md_f in sorted(md_files):
            ok = compile_markdown_to_html(md_f, validate=not args.no_validate)
            if not ok:
                all_ok = False
        sys.exit(0 if all_ok else 1)

    # 模式 B：--slug / --title 初始化模式
    if not args.slug or not args.title:
        parser.error("請提供 --compile <path> 或同時提供 --slug 與 --title")

    target_dir = os.path.join(args.repo, "docs", "collaborators", args.slug)
    os.makedirs(target_dir, exist_ok=True)
    md_path = os.path.join(target_dir, "README.md")

    script_dir = os.path.dirname(os.path.abspath(__file__))
    md_tpl_path = os.path.join(script_dir, "..", "references", "doc-template.md")

    if not os.path.exists(md_path) and os.path.exists(md_tpl_path):
        with open(md_tpl_path, "r", encoding="utf-8") as f:
            raw_tpl = f.read()
        # 抽取 ```markdown ... ``` 區塊內的範本
        m_block = re.search(r"```markdown\n(.*?)```", raw_tpl, re.S)
        md_content = m_block.group(1) if m_block else raw_tpl
        md_content = md_content.replace("[功能名稱]", args.title)
        md_content = md_content.replace("[Author Name]", "Paul")
        md_content = md_content.replace("YYYY-MM-DD", "2026-10-19")
        md_content = md_content.replace("[YYYY/MM/DD author (branch/anchor)]", args.anchor or args.slug)
        md_content = md_content.replace("<slug>", args.slug)
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(md_content)
        print(f"✓ 初始化 Markdown SSOT 模板: {md_path}")

    register_in_hub_index(args.repo, args.slug, args.title, args.anchor)
    ok = compile_markdown_to_html(md_path, validate=not args.no_validate)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
