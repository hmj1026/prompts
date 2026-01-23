# Investigation Checklist

Complete reference checklist for all investigation phases.

## Investigation Checklist

### Phase 1: Problem Discovery
- [ ] 理解預期與實際行為
- [ ] 獲取樣本資料 (ID、時間戳記)
- [ ] 建立調查文件 (docs/knowledge/[feature-name]/brainstorming.md)

### Phase 2: Evidence Gathering
- [ ] 執行資料庫驗證查詢
- [ ] 記錄資料表/欄位的差異
- [ ] 識別資料矛盾

### Phase 3: Root Cause Analysis
- [ ] 描繪完整資料流向
- [ ] 搜尋關鍵變數 (使用 ripgrep/scripts)
- [ ] 識別分歧點/問題程式碼
- [ ] 記錄根本原因

### Phase 4: Knowledge Documentation
- [ ] 檢查現有知識庫
- [ ] 建立/更新功能知識文件
- [ ] 記錄資料流向 (data-flow.md)
- [ ] 列出關鍵 function 及檔案位置 (key-functions.md)
- [ ] 記錄相關資料表 (related-tables.md)

### Phase 5: Solution Proposal
- [ ] 提出 2-3 個解決方案選項
- [ ] 🔔 notify_user - 請用戶選擇方案
- [ ] 用戶選擇後，使用 openspec-proposal 技能建立規格
- [ ] 🔔 notify_user - 請用戶審核規格
- [ ] 審核通過後，使用 test-driven-development 技能開發
- [ ] 透過測試驗證修復
