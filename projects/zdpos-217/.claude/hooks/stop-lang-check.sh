#!/usr/bin/env bash
# Stop：偵測最終回覆是否漂移成英文（偵測層）。
# 剔除 code fence、inline code、URL、路徑後，計算 CJK 字元占比；
# 低於門檻即回 decision=block，要求以正體中文重述。任何錯誤一律 fail-open。
# 注意：Stop hook 撤不回已顯示的回覆，block 只會促使模型補一則中文版本。
# 可調：LANG_CHECK_MIN_RATIO（預設 0.3）、LANG_CHECK_MIN_UNITS（預設 25）。
python3 -I -c '
import json, os, re, sys

MIN_RATIO = float(os.environ.get("LANG_CHECK_MIN_RATIO", "0.3"))
MIN_UNITS = int(os.environ.get("LANG_CHECK_MIN_UNITS", "25"))

def last_assistant_text(data):
    msg = data.get("last_assistant_message")
    if isinstance(msg, str) and msg.strip():
        return msg
    path = data.get("transcript_path")
    if not path or not os.path.isfile(path):
        return ""
    texts = []
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            content = (entry.get("message") or {}).get("content")
            if entry.get("type") == "user":
                is_tool_result = isinstance(content, list) and any(
                    isinstance(b, dict) and b.get("type") == "tool_result" for b in content)
                if not is_tool_result:
                    texts = []
                continue
            if entry.get("type") != "assistant" or not isinstance(content, list):
                continue
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    texts.append(block.get("text", ""))
    return "\n".join(texts[-1:]) if texts else ""

def prose_only(text):
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"`[^`\n]*`", " ", text)
    text = re.sub(r"https?://\S+", " ", text)
    text = re.sub(r"(?:[\w.~-]*/)+[\w.-]+", " ", text, flags=re.A)
    return text

try:
    data = json.load(sys.stdin)
    if data.get("stop_hook_active"):
        sys.exit(0)
    prose = prose_only(last_assistant_text(data))
    cjk = len(re.findall(r"[㐀-鿿豈-﫿]", prose))
    words = len(re.findall(r"[A-Za-z]{2,}", prose))
    units = cjk + words
    if units < MIN_UNITS or cjk / float(units) >= MIN_RATIO:
        sys.exit(0)
    print(json.dumps({
        "decision": "block",
        "reason": "語言檢查：上一則回覆的中文占比 %.0f%%，低於門檻 %.0f%%。請以正體中文重述上一則回覆的完整內容（技術名詞、識別字、路徑保留英文），不要另外道歉或說明。" % (100.0 * cjk / units, 100 * MIN_RATIO),
    }, ensure_ascii=False))
except Exception:
    sys.exit(0)
'
exit 0
