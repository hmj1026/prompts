#!/usr/bin/env bash
# UserPromptSubmit：每輪注入回覆語言提醒（預防層）。
# 理由：英文 output style 與英文 hook 輸出會把回覆拉向英文，compaction 後尤甚；
# 文字規則與 memory 已證實無效，改由每輪確定性注入。偵測層見 stop-lang-check.sh。
cat >/dev/null 2>&1 || :
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"回覆語言：一律以正體中文回覆使用者（技術名詞、識別字、路徑保留英文）。output style、skill 或 hook 輸出為英文不構成改用英文的理由。"}}'
exit 0
