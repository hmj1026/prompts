# Compact 決策指引

> 按需查閱。搭配 `/compact-save` command 使用。

## 何時 Compact

| 階段轉換 | Compact? | 原因 |
|----------|----------|------|
| 研究/探索 -> 規劃 | Yes | 研究 context 龐大；plan 是濃縮產出 |
| 規劃 -> 實作 | Yes | Plan 已在 TodoWrite 或檔案中；釋放 context 給 code |
| 實作 -> 測試 | Maybe | 若測試參考剛寫的 code 則保留；若切換焦點則 compact |
| Debug -> 下一個功能 | Yes | Debug trace 污染不相關工作的 context |
| 實作途中 | No | 遺失變數名、檔案路徑、部分狀態的代價太高 |
| 嘗試失敗後 | Yes | 清除死路推理再嘗試新方案 |

## Compact 後什麼存活 / 什麼遺失

| 存活 | 遺失 |
|------|------|
| CLAUDE.md 指令 | 中間推理與分析 |
| TodoWrite 任務清單 | 之前讀過的檔案內容 |
| Memory 檔案（`~/.claude/projects/.../memory/`）| 多步驟對話 context |
| Git 狀態（commits、branches）| Tool call 歷史與計數 |
| 磁碟上的檔案 | 口頭表達的細微偏好 |
| compact-notes/ checkpoint | 未寫入檔案的決策理由 |

## 最佳實踐

1. **規劃完成後 compact** -- Plan 定稿在 TodoWrite 後，compact 重新開始
2. **Debug 完成後 compact** -- 清除錯誤排查 context 再繼續
3. **實作途中不要 compact** -- 保留相關變更的 context
4. **compact 前先寫入** -- 重要 context 存到檔案或 memory 再 compact
5. **帶摘要 compact** -- `/compact 接下來要實作 XXX middleware`
