---
description: Create a compact context checkpoint in compact-notes/ for session continuity. Run before auto-compact or ending session to preserve task state for the next conversation.
argument-hint: "[optional extra notes]"
allowed-tools: Write, Bash
---

現在請幫我做一次手動 compact。

請回顧整段對話，在 ./compact-notes/ 下建立一個檔案（檔名：compact-YYYY-MM-DD-HH-MM.json，用當前時間）。

先用 Bash 取得當前時間：
```bash
date '+%Y-%m-%dT%H:%M:%S+08:00'
```
以及確保目錄存在：
```bash
mkdir -p ./compact-notes
```

請嚴格按照以下 JSON 結構填寫，不要增減欄位：

```json
{
  "L0": "用一句話寫：正在做什麼 + 目前狀態（完成/進行中/卡住），寫法像 git commit message",
  "compact_version": "2.0",
  "timestamp": "ISO 8601 格式",
  "project": {
    "name": "專案名稱",
    "path": "專案根目錄路徑",
    "tech_stack": ["語言", "框架", "主要工具"],
    "description": "一句話描述專案目標"
  },
  "session_goal": "這段對話原本要完成什麼（一句話）",
  "completed": [
    {
      "task": "做了什麼",
      "files": ["修改的檔案路徑"],
      "detail": "關鍵改動摘要（一句話）"
    }
  ],
  "in_progress": [
    {
      "task": "正在做什麼",
      "status": "做到哪裡了",
      "next_step": "下一步是什麼",
      "blockers": "卡住的原因（沒有就填 null）"
    }
  ],
  "failed_approaches": [
    {
      "attempt": "嘗試了什麼",
      "why_failed": "為什麼失敗",
      "lesson": "教訓 / 不要再這樣做"
    }
  ],
  "key_decisions": [
    {
      "decision": "做了什麼決策",
      "reason": "為什麼這樣決定",
      "alternatives_rejected": ["被否決的方案"]
    }
  ],
  "user_preferences": [
    "使用者明確表達過的偏好或要求"
  ],
  "key_files": {
    "path/to/file": "這個檔案的角色（一句話）"
  },
  "handover_context": "用 2-3 句話寫給下一段對話的交接備忘。假設接手方完全沒有前文。包含目前狀態和建議的第一步動作。"
}
```

注意事項：
1. 每個欄位都要填，沒有內容的陣列填 []，沒有的字串填 null
2. 保持極度精簡，每個值盡量控制在一句話內
3. 寫完後告訴我檔案的完整路徑
