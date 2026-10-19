#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
zdpos-qa-doc 雙向腳手架與無損編譯器 (Scaffolder & Lossless Markdown-to-HTML Compiler)
負責：
1. --init: 初始化產生標準 QA 手動測試手冊 Markdown (SSOT)
2. --compile: 將已填寫完成的 Markdown SSOT 100% 無損編譯為統一、高對比、離線可用的互動式 HTML 手冊
   （自動消毒 Mermaid 語法、透過 Playwright 批次預渲染高對比 SVG、自動生成案例快速導覽與 §4 即時同步簽核總表）
"""

import argparse
import datetime
import html as html_lib
import json
import os
import re
import subprocess
import sys
import tempfile


def protect_pipes_in_line(line):
    """保護表格列中的跳脫直線 \\| 以及行內程式碼 `...` 內的直線 |，避免拆欄時破版。"""
    line = line.replace(r"\|", "\x00ESC_PIPE\x00")

    def _repl_code(m):
        return "`" + m.group(1).replace("|", "\x00CODE_PIPE\x00") + "`"

    return re.sub(r"`([^`]+)`", _repl_code, line)


def split_table_row(line):
    """安全切分 Markdown 表格列。"""
    protected = protect_pipes_in_line(line.strip())
    if protected.startswith("|"):
        protected = protected[1:]
    if protected.endswith("|"):
        protected = protected[:-1]
    cells = []
    for c in protected.split("|"):
        c = c.replace("\x00ESC_PIPE\x00", r"\|").replace("\x00CODE_PIPE\x00", "|").strip()
        cells.append(c)
    return cells


def is_table_separator(line):
    """判斷是否為 Markdown 表格分隔列 (|---|---|)。"""
    s = line.strip()
    if not s.startswith("|"):
        return False
    cells = [c.strip() for c in s.strip("|").split("|")]
    return bool(cells) and all(re.match(r"^:?-{2,}:?$", c) for c in cells if c != "")


def render_inline_markdown(text):
    """將行內 Markdown 語法安全轉換為 HTML（先保護行內 `code` 再處理連結與粗體）。"""
    if not text:
        return ""
    replacements = {
        r"$\rightarrow$": "→",
        r"$\le$": "≤",
        r"$\ge$": "≥",
        r"$\times$": "×",
        r"$\neq$": "≠",
    }
    for k, v in replacements.items():
        text = text.replace(k, v)

    out = []
    pos = 0
    for m in re.finditer(r"`([^`]+)`", text):
        out.append(_format_non_code(text[pos : m.start()]))
        code_inner = m.group(1).replace(r"\|", "|")
        out.append("<code>" + html_lib.escape(code_inner) + "</code>")
        pos = m.end()
    out.append(_format_non_code(text[pos:]))
    return "".join(out)


def _format_non_code(s):
    if not s:
        return ""
    s = s.replace(r"\|", "|")
    # 保護已允許之 <br> 換行標籤
    s = re.sub(r"<br\s*/?>", "\x00BR\x00", s, flags=re.IGNORECASE)
    s = html_lib.escape(s, quote=False)
    s = s.replace("\x00BR\x00", "<br>")
    # 轉換 Markdown 連結 [text](url)
    s = re.sub(
        r"\[([^\]]+)\]\(([^)]+)\)",
        lambda m: f'<a href="{html_lib.escape(m.group(2), quote=True)}">{m.group(1)}</a>',
        s,
    )
    # 轉換粗體 **text**
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    # 轉換核心標記
    s = s.replace("★核心", '<span class="pill-core">★ 核心</span>')
    return s


def sanitize_mermaid_code(code):
    """
    自動修復 Mermaid 10.9.x 常見語法錯誤：
    1. 節點 ID 使用保留字 end[...] -> EndNode[...]
    2. subgraph ID[未加引號之標題 (含括號)] -> subgraph ID["標題 (含括號)"]
    3. subgraph 未帶 ID 但含括號之標題 -> subgraph SG_n["標題"]
    4. 連線標籤 -->|含括號未加引號| -> -->|"含括號"|
    5. 節點標籤 ID[含括號或冒號但未加引號] -> ID["..."]
    """
    lines = code.strip().splitlines()
    if not lines:
        return code.strip()

    first_line = lines[0].strip()
    is_flowchart = bool(re.match(r"^(?:flowchart|graph)\b", first_line))
    sanitized_lines = []
    sg_counter = 0

    for idx, line in enumerate(lines):
        if idx == 0 or not is_flowchart:
            sanitized_lines.append(line)
            continue

        stripped = line.strip()
        if not stripped or stripped.startswith("%%"):
            sanitized_lines.append(line)
            continue

        # 1. 修正保留字節點 ID `end[...]`
        line = re.sub(r"^(\s*)end(\s*[\[\(\{])", r"\1EndNode\2", line)

        # 2. 修正 subgraph 標題
        sg_match = re.match(r"^(\s*subgraph\s+)([A-Za-z0-9_-]+)\s*\[(.*)\]\s*$", line)
        if sg_match:
            prefix, sg_id, sg_title = sg_match.groups()
            sg_title = sg_title.strip()
            if not (sg_title.startswith('"') and sg_title.endswith('"')):
                sg_title = '"' + sg_title.replace('"', "'") + '"'
            sanitized_lines.append(f"{prefix}{sg_id}[{sg_title}]")
            continue

        sg_bare = re.match(r"^(\s*subgraph\s+)(?!\[)([^\[\n]+)$", line)
        if sg_bare:
            prefix, rest = sg_bare.groups()
            rest_str = rest.strip()
            if any(ch in rest_str for ch in "()（）[]{}：:/") and not (
                rest_str.startswith('"') and rest_str.endswith('"')
            ):
                sg_counter += 1
                clean_title = rest_str.replace('"', "'")
                sanitized_lines.append(f'{prefix}SG_AUTO_{sg_counter}["{clean_title}"]')
                continue

        # 3. 修正連線標籤 |...| 內含特殊字元但未加雙引號
        def _fix_edge_label(m):
            inner = m.group(1).strip()
            if inner.startswith('"') and inner.endswith('"'):
                return f"|{inner}|"
            if any(c in inner for c in "()（）[]{}:：/<>"):
                return '|"' + inner.replace('"', "'") + '"|'
            return m.group(0)

        line = re.sub(r"\|([^|\n]+)\|", _fix_edge_label, line)

        # 4. 修正節點定義 ID[label] 內含 () / : / <br> 但未加雙引號
        def _fix_rect_node(m):
            node_id, inner = m.group(1), m.group(2)
            s_in = inner.strip()
            if s_in.startswith('"') and s_in.endswith('"'):
                return m.group(0)
            # 排除特殊雙重形狀如 [[...]] 或 [(...)]
            if s_in.startswith("[") or s_in.startswith("("):
                return m.group(0)
            if any(c in s_in for c in "()（）[]{}:：/<>"):
                return f'{node_id}["{s_in.replace(chr(34), chr(39))}"]'
            return m.group(0)

        line = re.sub(r'\b([A-Za-z0-9_]+)\[(?!")([^\]\n]+)\]', _fix_rect_node, line)
        sanitized_lines.append(line)

    return "\n".join(sanitized_lines)


def batch_render_mermaid_blocks(mermaid_codes):
    """透過 render_mermaid_cli.js --batch 一次性將所有 Mermaid 語法預渲染為高對比 SVG。"""
    if not mermaid_codes:
        return []

    sanitized_list = [sanitize_mermaid_code(c) for c in mermaid_codes]
    script_dir = os.path.dirname(os.path.abspath(__file__))
    cli_js = os.path.join(script_dir, "render_mermaid_cli.js")

    results = None
    if os.path.exists(cli_js):
        tmp_in_path = None
        tmp_out_path = None
        try:
            with tempfile.NamedTemporaryFile(mode="w", suffix=".in.json", delete=False, encoding="utf-8") as tmp_in:
                json.dump(sanitized_list, tmp_in, ensure_ascii=False)
                tmp_in_path = tmp_in.name
            tmp_out_path = tmp_in_path + ".out.json"

            proc = subprocess.run(
                ["node", cli_js, "--batch", tmp_in_path, tmp_out_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=60,
            )
            if proc.returncode == 0 and os.path.exists(tmp_out_path):
                with open(tmp_out_path, "r", encoding="utf-8") as f_out:
                    results = json.load(f_out)
        except Exception as e:
            print(f"⚠️ Mermaid 批次預渲染發生例外 ({e})，將降級為客戶端渲染。")
        finally:
            if tmp_in_path and os.path.exists(tmp_in_path):
                os.unlink(tmp_in_path)
            if tmp_out_path and os.path.exists(tmp_out_path):
                os.unlink(tmp_out_path)

    html_blocks = []
    for idx, clean_code in enumerate(sanitized_list):
        escaped_code = html_lib.escape(clean_code)
        res = results[idx] if (results and idx < len(results)) else None
        if res and res.get("success") and "<svg" in res.get("svg", ""):
            svg_html = res["svg"].strip()
            html_blocks.append(
                f'<div class="mermaid-container">\n'
                f'  <div class="mermaid-diagram">{svg_html}</div>\n'
                f'  <details class="mermaid-source-details">\n'
                f'    <summary>檢視 Mermaid 原始碼</summary>\n'
                f'    <pre><code>{escaped_code}</code></pre>\n'
                f'  </details>\n'
                f'</div>'
            )
        else:
            err_msg = res.get("error", "未知錯誤") if res else "未執行 CLI"
            print(f"⚠️ 圖表 #{idx + 1} 預渲染未成功 ({err_msg})，保留客戶端渲染區塊。")
            html_blocks.append(
                f'<div class="mermaid-container">\n'
                f'  <pre class="mermaid" data-mermaid-src="true">\n{clean_code}\n  </pre>\n'
                f'</div>'
            )
    return html_blocks


def render_table_html(table_lines):
    """將 Markdown 表格區塊轉為高對比 HTML 表格。"""
    if len(table_lines) < 2:
        return ""
    headers = split_table_row(table_lines[0])
    body_start = 2 if is_table_separator(table_lines[1]) else 1
    body_rows = [split_table_row(ln) for ln in table_lines[body_start:] if ln.strip()]

    out = ['<div class="tbl-wrap"><table><thead><tr>']
    for h in headers:
        out.append(f"<th>{render_inline_markdown(h)}</th>")
    out.append("</tr></thead><tbody>")
    for r in body_rows:
        # 補齊或對齊欄數
        if len(r) < len(headers):
            r = r + [""] * (len(headers) - len(r))
        out.append("<tr>" + "".join(f"<td>{render_inline_markdown(c)}</td>" for c in r[: len(headers)]) + "</tr>")
    out.append("</tbody></table></div>")
    return "".join(out)


def format_step_item(step_html):
    """高亮步驟內之『應該看到...』預期結果字句。"""
    return re.sub(r"(應該?看到[^。<]*。?)", r'<span class="expect">\1</span>', step_html)


def render_markdown_blocks(lines, mermaid_iter, as_steps=False, start_step_num=1):
    """
    通用無損 Markdown 區塊渲染器：
    支援程式碼區塊、Mermaid 圖表、表格、Callout 引言、有序清單、無序清單、標題與段落。
    """
    out = []
    i = 0
    n = len(lines)
    current_step = start_step_num

    while i < n:
        ln = lines[i]
        s = ln.strip()

        if not s or s == "---":
            i += 1
            continue

        # 1. Fenced code block (```mermaid 或一般 ```)
        if s.startswith("```"):
            lang = s[3:].strip().lower()
            j = i + 1
            buf = []
            while j < n and not lines[j].strip().startswith("```"):
                buf.append(lines[j])
                j += 1
            if lang == "mermaid":
                out.append(next(mermaid_iter, '<div class="mermaid-container"></div>'))
            else:
                code_escaped = html_lib.escape("\n".join(buf))
                out.append(f"<pre><code>{code_escaped}</code></pre>")
            i = j + 1
            continue

        # 2. Markdown 表格
        if s.startswith("|") and (i + 1 < n and lines[i + 1].strip().startswith("|")):
            j = i
            buf = []
            while j < n and lines[j].strip().startswith("|"):
                buf.append(lines[j])
                j += 1
            out.append(render_table_html(buf))
            i = j
            continue

        # 3. Blockquote 引言 (> ...)
        if s.startswith(">"):
            buf = []
            while i < n and lines[i].strip().startswith(">"):
                clean_q = re.sub(r"^>\s?", "", lines[i].strip())
                if clean_q:
                    buf.append(render_inline_markdown(clean_q))
                i += 1
            joined_q = "<br>".join(buf)
            callout_cls = "callout"
            if any(k in joined_q for k in ("⚠️", "警告", "注意", "切勿", "不可", "務必")):
                callout_cls = "callout warn"
            elif any(k in joined_q for k in ("🚫", "禁止", "錯誤", "失敗")):
                callout_cls = "callout bad"
            out.append(f'<div class="{callout_cls}">{joined_q}</div>')
            continue

        # 4. 子標題 (### / ####)
        h_match = re.match(r"^(#{3,4})\s+(.*)$", s)
        if h_match:
            lvl = len(h_match.group(1))
            h_text = render_inline_markdown(h_match.group(2).strip())
            out.append(f"<h{lvl}>{h_text}</h{lvl}>")
            i += 1
            continue

        # 5. 有序清單 (1. ...)
        if re.match(r"^\d+\.\s+", s):
            items = []
            while i < n:
                cur_line = lines[i]
                cur_s = cur_line.strip()
                m_num = re.match(r"^\s*\d+\.\s+(.*)$", cur_line)
                if m_num and not cur_line.startswith("   "):
                    items.append([render_inline_markdown(m_num.group(1).strip())])
                    i += 1
                elif items and (cur_line.startswith("   ") or cur_line.startswith("\t")) and cur_s:
                    # 縮排延續行或縮排 blockquote / 項目
                    clean_sub = re.sub(r"^>\s?", "💡 ", cur_s)
                    items[-1].append(render_inline_markdown(clean_sub))
                    i += 1
                else:
                    break

            if as_steps:
                li_html = []
                for item_parts in items:
                    first_part = format_step_item(item_parts[0])
                    rest_parts = [format_step_item(p) for p in item_parts[1:]]
                    body_str = "<br>".join([first_part] + rest_parts)
                    li_html.append(f'<li><span class="step-num">{current_step}</span>{body_str}</li>')
                    current_step += 1
                out.append('<ol class="tc-steps">' + "".join(li_html) + "</ol>")
            else:
                li_html = ["<li>" + "<br>".join(parts) + "</li>" for parts in items]
                out.append("<ol>" + "".join(li_html) + "</ol>")
            continue

        # 6. 無序清單 (- ... 或 * ...)
        if re.match(r"^[-*]\s+", s):
            items = []
            while i < n:
                cur_line = lines[i]
                cur_s = cur_line.strip()
                m_bul = re.match(r"^\s*[-*]\s+(.*)$", cur_line)
                if m_bul and not cur_line.startswith("    "):
                    items.append([render_inline_markdown(m_bul.group(1).strip())])
                    i += 1
                elif items and (cur_line.startswith("  ") or cur_line.startswith("\t")) and cur_s:
                    sub_s = re.sub(r"^[-*]\s+", "• ", cur_s)
                    items[-1].append(render_inline_markdown(sub_s))
                    i += 1
                else:
                    break
            li_html = ["<li>" + "<br>".join(parts) + "</li>" for parts in items]
            out.append("<ul>" + "".join(li_html) + "</ul>")
            continue

        # 7. 一般段落
        out.append(f"<p>{render_inline_markdown(s)}</p>")
        i += 1

    return "\n".join(out), current_step


def parse_tc_card(tc_id, raw_title, body_lines, mermaid_iter):
    """
    解析單一測試案例 (TC) 為標準高對比互動式 <details class="tc"> 卡片。
    支援：
    - 粗體段落標籤 (**適用條件**, **在確認什麼**, **前置**, **操作**, **Pass**, **Fail**)
    - H4 標題標籤 (#### 適用條件, #### 在確認什麼, #### 操作, #### Pass / Fail 判定)
    - 開頭直接為 `| 適用條件 | 內容 |` 表格之精簡格式
    - 多行條列式 Pass / Fail 判定條件與複合式操作步驟（含穿插表格與提示）
    """
    is_core = ("★" in raw_title) or ("核心" in raw_title and "★" in raw_title)
    clean_title = re.sub(r"★\s*核心|★", "", raw_title).strip()

    # 過濾底部靜態 Markdown 填報表 (`| 實際結果 ... |`)，但保留其括號提示作為 textarea placeholder
    filtered_lines = []
    custom_placeholder = "請填寫實際觀察結果、單號、畫面提示文字或異常截圖說明..."
    skip_static_result_table = False
    for ln in body_lines:
        s = ln.strip()
        if s.startswith("| 實際結果"):
            m_hint = re.search(r"實際結果[（(]([^）)]+)[）)]", s)
            if m_hint:
                custom_placeholder = f"實際結果（{m_hint.group(1)}）"
            skip_static_result_table = True
            continue
        if skip_static_result_table:
            if s.startswith("|") and (is_table_separator(s) or "☐" in s or "Pass" in s or "Fail" in s):
                continue
            skip_static_result_table = False
        if is_table_separator(s) and filtered_lines and not filtered_lines[-1].strip().startswith("|"):
            continue
        filtered_lines.append(ln)

    # 將 TC 內部行切分為語義區段: ('pre' | 'goal' | 'steps' | 'pass' | 'fail' | 'general', lines)
    segments = []
    cur_kind = "general"
    cur_buf = []

    def _flush():
        nonlocal cur_buf
        if cur_buf:
            segments.append((cur_kind, cur_buf))
            cur_buf = []

    i = 0
    n = len(filtered_lines)
    while i < n:
        ln = filtered_lines[i]
        s = ln.strip()

        # 檢查 H4 標題 (#### 適用條件 / #### 在確認什麼 / #### 操作 / #### Pass / Fail 判定)
        m_h4 = re.match(r"^####\s+(.*)$", s)
        if m_h4:
            h4_title = m_h4.group(1).strip()
            _flush()
            if "適用條件" in h4_title or "前置" in h4_title:
                cur_kind = "pre"
            elif "在確認什麼" in h4_title or "測試目標" in h4_title:
                cur_kind = "goal"
            elif "操作" in h4_title:
                cur_kind = "steps"
            elif "Pass" in h4_title or "Fail" in h4_title or "判定" in h4_title or "預期結果" in h4_title:
                cur_kind = "verdict_group"
            else:
                cur_kind = "general"
                cur_buf.append(ln)
            i += 1
            continue

        # 檢查粗體段落開頭: **適用條件** / **前置** / **在確認什麼** / **操作(步驟)** / **Pass** / **Fail** / **預期結果**
        m_bold = re.match(
            r"^(?:[-*]\s+)?\*\*(適用條件|前置|在確認什麼|操作步驟|操作|預期結果|Pass|Fail)\*\*(?:[：:]\s*(.*))?$",
            s,
        )
        if m_bold:
            label, inline_val = m_bold.group(1), (m_bold.group(2) or "").strip()
            _flush()
            if label in ("適用條件", "前置"):
                cur_kind = "pre"
                if inline_val:
                    cur_buf.append(f"**{label}**：{inline_val}")
            elif label == "在確認什麼":
                cur_kind = "goal"
                if inline_val:
                    cur_buf.append(inline_val)
            elif label in ("操作", "操作步驟"):
                cur_kind = "steps"
                if inline_val:
                    cur_buf.append(inline_val)
            elif label in ("Pass", "預期結果"):
                cur_kind = "pass"
                if inline_val:
                    cur_buf.append(inline_val)
            elif label == "Fail":
                cur_kind = "fail"
                if inline_val:
                    cur_buf.append(inline_val)
            i += 1
            continue

        # 若開頭直接是 `| 適用條件 | 內容 |` 或 `| 項目 | 內容 |` 表格（例如 commission / kds 手冊）
        if cur_kind == "general" and not cur_buf and s.startswith("|") and ("適用條件" in s or "項目" in s):
            cur_kind = "pre"

        cur_buf.append(ln)
        i += 1

    _flush()

    # 渲染各語義區段為 HTML
    rendered_parts = []
    step_counter = 1

    for kind, seg_lines in segments:
        if kind == "pre":
            inner_html, _ = render_markdown_blocks(seg_lines, mermaid_iter, as_steps=False)
            if inner_html.strip():
                rendered_parts.append(f'<div class="tc-pre"><h4>📋 適用條件與前置</h4>{inner_html}</div>')
        elif kind == "goal":
            non_empty = [x.strip() for x in seg_lines if x.strip() and x.strip() != "---"]
            if len(non_empty) == 1 and not non_empty[0].startswith(("|", "-", "*", "1.", "```", ">")):
                goal_html = render_inline_markdown(non_empty[0])
                rendered_parts.append(f'<div class="tc-goal"><strong>🎯 在確認什麼：</strong>{goal_html}</div>')
            else:
                inner_html, _ = render_markdown_blocks(seg_lines, mermaid_iter, as_steps=False)
                if inner_html.strip():
                    rendered_parts.append(f'<div class="tc-goal"><strong>🎯 在確認什麼：</strong>{inner_html}</div>')
        elif kind == "steps":
            inner_html, step_counter = render_markdown_blocks(
                seg_lines, mermaid_iter, as_steps=True, start_step_num=step_counter
            )
            if inner_html.strip():
                rendered_parts.append(f"<h4>👉 操作步驟</h4>\n{inner_html}")
        elif kind in ("pass", "fail"):
            v_cls = "pass" if kind == "pass" else "fail"
            v_title = "✅ PASS" if kind == "pass" else "❌ FAIL"
            non_empty = [x.strip() for x in seg_lines if x.strip() and x.strip() != "---"]
            if len(non_empty) == 1 and not non_empty[0].startswith(("|", "-", "*", "1.", "```", ">")):
                v_inner = render_inline_markdown(non_empty[0])
            else:
                v_inner, _ = render_markdown_blocks(seg_lines, mermaid_iter, as_steps=False)
            rendered_parts.append(
                f'<div class="verdict-box {v_cls}">'
                f'<span class="verdict-label">{v_title}</span>'
                f'<div class="verdict-content">{v_inner}</div>'
                f"</div>"
            )
        else:
            inner_html, step_counter = render_markdown_blocks(
                seg_lines, mermaid_iter, as_steps=False, start_step_num=step_counter
            )
            if inner_html.strip():
                rendered_parts.append(inner_html)

    core_class = " core" if is_core else ""
    core_attr = "true" if is_core else "false"
    core_pill = '<span class="pill-core">★ 核心</span>' if is_core else ""
    title_html = render_inline_markdown(clean_title)
    body_html = "\n".join(rendered_parts)

    card_html = f"""
<details class="tc{core_class}" id="{tc_id}" data-tc-id="{tc_id}" data-status="NOT_RUN" data-core="{core_attr}">
  <summary>
    <span class="tc-id">{tc_id}</span>
    <span class="tc-title">{title_html}</span>
    {core_pill}
    <span class="pill-status NOT_RUN">NOT_RUN</span>
  </summary>
  <div class="tc-body">
    {body_html}
    <div class="result-area">
      <div class="result-header">
        <span class="result-title">📝 測試執行結果記錄（點擊圓點紀錄，再次點擊或按右側按鈕可取消）</span>
        <button type="button" class="btn-clear-verdict" data-clear-tc="{tc_id}" title="將此案例重置為未填 (NOT_RUN)">↺ 重置未填</button>
      </div>
      <div class="radio-group" role="radiogroup" aria-label="{tc_id} 判定結果">
        <label><input type="radio" name="verdict_{tc_id}" value="Pass"> Pass</label>
        <label><input type="radio" name="verdict_{tc_id}" value="Fail"> Fail</label>
        <label><input type="radio" name="verdict_{tc_id}" value="Blocked"> Blocked</label>
        <label><input type="radio" name="verdict_{tc_id}" value="N/A"> N/A</label>
      </div>
      <textarea class="result-input" placeholder="{html_lib.escape(custom_placeholder, quote=True)}"></textarea>
    </div>
  </div>
</details>"""

    return {
        "id": tc_id,
        "title": clean_title,
        "title_html": title_html,
        "is_core": is_core,
        "card_html": card_html,
    }


def compile_markdown_to_html(md_path, html_path, template_html_path):
    """將已填寫完成的 Markdown 手冊 100% 無損編譯為互動式高對比 HTML 手冊，並自動執行雙重門禁驗證。"""
    if not os.path.exists(md_path):
        print(f"❌ 找不到來源 Markdown 檔案: {md_path}")
        sys.exit(1)

    with open(md_path, "r", encoding="utf-8") as f:
        md_text = f.read()

    with open(template_html_path, "r", encoding="utf-8") as f:
        html_tpl = f.read()

    # 1. 預先抽取整份文件中所有 ```mermaid 區塊並一次性透過 Playwright 批次預渲染為 SVG
    raw_mermaid_blocks = re.findall(r"```mermaid\s*\n(.*?)```", md_text, re.DOTALL)
    rendered_mermaids = batch_render_mermaid_blocks(raw_mermaid_blocks)
    mermaid_iter = iter(rendered_mermaids)

    # 2. 解析 H1 標題與環境名稱
    h1_match = re.search(r"^#\s+(.+)$", md_text, re.MULTILINE)
    doc_title = h1_match.group(1).strip() if h1_match else "QA 手動功能測試手冊"
    feature_name = doc_title
    env_name = "DEV / LOCAL"
    if "—" in doc_title:
        right_part = doc_title.split("—", 1)[1].strip()
        env_m = re.search(r"[（(]([^）)]+)[）)]\s*$", right_part)
        if env_m:
            env_name = env_m.group(1).strip()
            feature_name = right_part[: env_m.start()].strip()
        else:
            feature_name = right_part

    slug = os.path.basename(md_path).replace("QA-", "").replace("-manual.md", "").replace(".md", "")

    # 3. 依 H2 (`## `) 切分頂層章節
    lines = md_text.splitlines()
    top_sections = []  # (title, body_lines)
    intro_meta_lines = []
    cur_h2 = None

    for ln in lines:
        if re.match(r"^#\s+", ln):
            continue
        m_h2 = re.match(r"^##\s+(.*)$", ln)
        if m_h2:
            cur_h2 = [m_h2.group(1).strip(), []]
            top_sections.append(cur_h2)
        else:
            if cur_h2 is None:
                intro_meta_lines.append(ln)
            else:
                cur_h2[1].append(ln)

    meta_html, _ = render_markdown_blocks(intro_meta_lines, mermaid_iter, as_steps=False)

    # 4. 處理各 H2 章節（支援單一 §3 或多章節 TC 如 KDS）
    intro_sections_html = []
    tail_sections_html = []
    nav_sections_html = []
    tc_intro_parts = []
    tc_cards_html = []
    parsed_tcs = []
    signoff_extra_parts = []

    tc_heading_re = re.compile(
        r"^###\s+((?:TC-[A-Za-z0-9._-]+|[ABC]-\d{2}|SV-\d{2}))(?:\s*[—\-:：\u3000]\s*|\s+)(.+)$"
    )

    seen_sec3 = False
    added_sec3_nav = False
    added_sec4_nav = False
    sec_counter = 0

    for h2_title, h2_lines in top_sections:
        sec_counter += 1
        has_tcs = any(tc_heading_re.match(ln.strip()) for ln in h2_lines)
        is_sec3 = bool(re.match(r"^3\.\s*測試案例", h2_title)) or has_tcs
        is_sec4 = bool(re.match(r"^(?:4\.|8\.)?\s*(?:簽核|驗收簽核|簽核彙總)", h2_title))

        if is_sec3:
            seen_sec3 = True
            if not added_sec3_nav:
                nav_sections_html.append('<a href="#sec-3">🧪 3. 測試案例清單</a>')
                added_sec3_nav = True

            # 若為多章節 TC（例如 KDS 的 ## 4. KDS 開啟 / ## 5. KDS 未開啟），加入階段橫幅
            if not re.match(r"^3\.\s*測試案例", h2_title):
                tc_cards_html.append(
                    f'<div class="phase-banner"><span>{render_inline_markdown(h2_title)}</span></div>'
                )

            pre_tc_lines = []
            cur_tc = None
            sec3_items = []

            for ln in h2_lines:
                s = ln.strip()
                m_tc = tc_heading_re.match(s)
                m_h3 = re.match(r"^###\s+(.*)$", s)
                if m_tc:
                    cur_tc = ("tc", m_tc.group(1).strip(), m_tc.group(2).strip(), [])
                    sec3_items.append(cur_tc)
                elif m_h3:
                    cur_tc = ("banner", m_h3.group(1).strip(), [])
                    sec3_items.append(cur_tc)
                else:
                    if cur_tc is None:
                        pre_tc_lines.append(ln)
                    else:
                        cur_tc[-1].append(ln)

            pre_rendered, _ = render_markdown_blocks(pre_tc_lines, mermaid_iter, as_steps=False)
            if pre_rendered.strip():
                tc_intro_parts.append(pre_rendered)

            for item in sec3_items:
                if item[0] == "banner":
                    _, b_title, b_lines = item
                    b_body, _ = render_markdown_blocks(b_lines, mermaid_iter, as_steps=False)
                    tc_cards_html.append(
                        f'<div class="phase-banner"><span>{render_inline_markdown(b_title)}</span></div>\n{b_body}'
                    )
                else:
                    _, tid, ttitle, tlines = item
                    tc_info = parse_tc_card(tid, ttitle, tlines, mermaid_iter)
                    parsed_tcs.append(tc_info)
                    tc_cards_html.append(tc_info["card_html"])
            continue

        if is_sec4:
            if not added_sec4_nav:
                nav_sections_html.append('<a href="#sec-4">✍️ 4. 驗收簽核總表</a>')
                added_sec4_nav = True
            kept_sec4 = []
            for ln in h2_lines:
                if re.match(r"^\|\s*(?:角色|QA\s*執行|開發覆核)\s*\|", ln.strip()):
                    continue
                kept_sec4.append(ln)
            s4_html, _ = render_markdown_blocks(kept_sec4, mermaid_iter, as_steps=False)
            if s4_html.strip():
                signoff_extra_parts.append(s4_html)
            continue

        # 一般章節（§0, §1, §2, 本文不測, 怎麼讀, §5, §6, §7 等）
        sec_id = f"sec-doc-{sec_counter}"
        if "本文不測" in h2_title:
            body_rendered, _ = render_markdown_blocks(h2_lines, mermaid_iter, as_steps=False)
            section_block = (
                f'<section class="card" id="{sec_id}">'
                f'<div class="callout bad" style="margin:0">'
                f'<div class="callout-title">🚫 {render_inline_markdown(h2_title)}</div>'
                f"{body_rendered}</div></section>"
            )
        else:
            body_rendered, _ = render_markdown_blocks(h2_lines, mermaid_iter, as_steps=False)
            section_block = (
                f'<section class="card" id="{sec_id}">'
                f"<h2>{render_inline_markdown(h2_title)}</h2>\n"
                f"{body_rendered}</section>"
            )

        nav_sections_html.append(f'<a href="#{sec_id}">📌 {html_lib.escape(h2_title)}</a>')
        if not seen_sec3:
            intro_sections_html.append(section_block)
        else:
            tail_sections_html.append(section_block)

    # 5. 組裝快速導覽 Chips、左側欄案例清單與 §4 即時同步簽核列
    overview_chips = []
    sidebar_tc_links = []
    signoff_rows = []

    for tc in parsed_tcs:
        tid = tc["id"]
        core_cls = " core" if tc["is_core"] else ""
        star_badge = ' <span class="pill-core">★</span>' if tc["is_core"] else ""
        short_title = tc["title"][:16] + ("…" if len(tc["title"]) > 16 else "")

        overview_chips.append(f'<a class="chip{core_cls}" href="#{tid}" data-chip="{tid}">{tid}</a>')
        sidebar_tc_links.append(
            f'<a href="#{tid}" class="tc-link"><span><strong>{tid}</strong> {html_lib.escape(short_title)}</span>'
            f'{"<span>★</span>" if tc["is_core"] else ""}</a>'
        )
        signoff_rows.append(
            f'<tr data-sign="{tid}">'
            f'<td><a href="#{tid}"><strong>{tid}</strong></a></td>'
            f'<td>{tc["title_html"]}{star_badge}</td>'
            f'<td class="sv">未填</td>'
            f'<td class="sn">－</td>'
            f"</tr>"
        )

    replacements = {
        "{{SLUG}}": html_lib.escape(slug, quote=True),
        "{{FEATURE_NAME}}": html_lib.escape(feature_name),
        "{{ENV}}": html_lib.escape(env_name),
        "{{TC_COUNT}}": str(len(parsed_tcs)),
        "{{NAV_SECTIONS_HTML}}": "\n    ".join(nav_sections_html),
        "{{SIDEBAR_TC_LINKS}}": "\n      ".join(sidebar_tc_links),
        "{{META_HTML}}": meta_html,
        "{{OVERVIEW_CHIPS_HTML}}": "".join(overview_chips),
        "{{INTRO_SECTIONS_HTML}}": "\n\n    ".join(intro_sections_html),
        "{{TC_INTRO_HTML}}": "\n".join(tc_intro_parts),
        "{{TC_CARDS_HTML}}": "\n".join(tc_cards_html),
        "{{SIGNOFF_EXTRA_HTML}}": "\n".join(signoff_extra_parts),
        "{{SIGNOFF_ROWS_HTML}}": "\n            ".join(signoff_rows),
        "{{TAIL_SECTIONS_HTML}}": "\n\n    ".join(tail_sections_html),
    }

    for k, v in replacements.items():
        html_tpl = html_tpl.replace(k, v)

    os.makedirs(os.path.dirname(os.path.abspath(html_path)), exist_ok=True)
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html_tpl)

    print(
        f"✅ 成功編譯互動式 QA HTML 手冊: {html_path} "
        f"(共 {len(parsed_tcs)} 個測試案例, {len(raw_mermaid_blocks)} 個 Mermaid 圖表)"
    )

    # 6. 自動銜接執行雙重門禁驗證 (validate_qa_html.py)
    validator_py = os.path.join(os.path.dirname(os.path.abspath(__file__)), "validate_qa_html.py")
    if os.path.exists(validator_py):
        v_res = subprocess.run([sys.executable, validator_py, html_path])
        if v_res.returncode != 0:
            sys.exit(v_res.returncode)


def main():
    parser = argparse.ArgumentParser(description="zdpos-qa-doc 雙向腳手架與無損編譯器")
    parser.add_argument("--compile", metavar="MD_PATH", help="將指定的 Markdown 手冊無損編譯為互動式 HTML")
    parser.add_argument("--module", help="模組目錄名稱 (如 pickup, split-bill, point, sticker)")
    parser.add_argument("--slug", help="功能識別短名 (如 cross-store-pickup-close)")
    parser.add_argument("--title", help="功能中文名稱 (如 跨店取貨自動結案)")
    parser.add_argument("--env", default="DEV / LOCAL", help="測試環境名稱")
    parser.add_argument("--output-dir", default="docs/qa", help="基礎輸出目錄 (預設: docs/qa)")

    args = parser.parse_args()
    script_dir = os.path.dirname(os.path.abspath(__file__))
    skill_dir = os.path.dirname(script_dir)
    md_tpl_path = os.path.join(skill_dir, "references", "qa-doc-template.md")
    html_tpl_path = os.path.join(skill_dir, "references", "qa-html-template.html")

    if args.compile:
        target = os.path.abspath(args.compile)
        if os.path.isdir(target):
            md_files = []
            for root, _dirs, files in os.walk(target):
                for fname in sorted(files):
                    if fname.startswith("QA-") and fname.endswith("-manual.md"):
                        md_files.append(os.path.join(root, fname))
            if not md_files:
                print(f"❌ 在目錄 {target} 中找不到任何 QA-*-manual.md 檔案", file=sys.stderr)
                sys.exit(1)
            for mp in sorted(md_files):
                hp = re.sub(r"\.md$", ".html", mp)
                compile_markdown_to_html(mp, hp, html_tpl_path)
        else:
            md_path = target
            html_path = re.sub(r"\.md$", ".html", md_path)
            compile_markdown_to_html(md_path, html_path, html_tpl_path)
        return

    if not args.module or not args.slug or not args.title:
        parser.error("初始化模式需提供 --module, --slug 與 --title 參數（或使用 --compile <md_path> 進行編譯）")

    today = datetime.date.today().isoformat()
    target_dir = os.path.join(args.output_dir, args.module)
    os.makedirs(target_dir, exist_ok=True)

    md_filename = f"QA-{args.slug}-manual.md"
    md_out_path = os.path.join(target_dir, md_filename)

    if os.path.exists(md_tpl_path):
        with open(md_tpl_path, "r", encoding="utf-8") as f:
            md_content = f.read()
        md_content = (
            md_content.replace("{{FEATURE_NAME}}", args.title)
            .replace("{{ENV}}", args.env)
            .replace("{{DATE}}", today)
            .replace("{{MODULE}}", args.module)
            .replace("{{SLUG}}", args.slug)
        )
        with open(md_out_path, "w", encoding="utf-8") as f:
            f.write(md_content)
        print(f"✅ 已建立 QA Markdown 手冊 SSOT 草稿: {md_out_path}")
        print(f"👉 請先完成 Markdown 內容撰寫，再執行：python3 {__file__} --compile {md_out_path}")


if __name__ == "__main__":
    main()
