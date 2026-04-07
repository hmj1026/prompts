# Claude Code 執行策略

## 任務模式

預設直接執行使用者目標，不先過度規劃。
所有流程末段均為 `→ [dr*] → code-reviewer-zdpos_dev`（dr* 見腳注）。

| 任務規模 | 流程 |
|---------|------|
| **Small change（非 bug fix）** | inspect → patch |
| **Small change（根因已知的 bug fix）** | inspect → tdd-guide-zdpos_dev（寫測試）→ patch → tdd-guide-zdpos_dev（驗測試）|
| **Medium change** | inspect → brief plan¹ → tdd-guide-zdpos_dev → patch |
| **Bug fix（根因未知）** | bug-investigation → [OpenSpec?]² → tdd-guide-zdpos_dev → patch |
| **New feature** | [OpenSpec?]² → tdd-guide-zdpos_dev → patch |
| **Architecture change** | architect-zdpos_dev → [OpenSpec?]² → tdd-guide-zdpos_dev → patch |

¹ brief plan = 回覆中列出步驟清單，**不需 OpenSpec 文件**
² [OpenSpec?] = 可選步驟；create-dev 路由時主動詢問用戶（預設 n）：
　- **y** → `/opsx:new`，建立 `openspec/changes/<change-id>/` artifacts
　- **n** → brief plan（回覆中列步驟），不建立 artifact
**\* dr（domain reviewer）** = database-reviewer-mysql（SQL）+ security-reviewer-zdpos_dev（安全）

**鐵律：**
- OpenSpec 為可選步驟：create-dev 路由時主動詢問用戶；若用戶選 No，改用 brief plan，不建立 openspec/changes/ artifact
- tdd-guide-zdpos_dev 雙重角色：（1）規劃後先寫測試（RED），（2）patch 後驗測試（GREEN）；Small change bug fix 兩步都必含
- bug fix 分叉：根因已知 → Small change bug fix；根因未知 → Bug fix（根因未知）含 bug-investigation

## 任務分類對應表

execution-policy 的 6 分類 ↔ create-dev / adaptive-dev-workflow 的分類對照：

| execution-policy | create-dev | adaptive-dev-workflow |
|-----------------|------------|----------------------|
| Small change（非 bug fix）| Lightweight | Lightweight Maintenance |
| Small change（根因已知的 bug fix）| Bug Fix (known) | Lightweight Maintenance |
| Medium change | Medium change | Lightweight Maintenance |
| Bug fix（根因未知）| Bug Fix (unknown) | Bug Investigation & Fix |
| New feature | Feature Delivery (normal/cross-module) | Feature Delivery |
| Architecture change | Feature Delivery (cross-module/DDD) | Feature Delivery |

---

## Output Contract

- 回覆格式：`結論` → `變更檔案` → `驗證` → `風險/待確認`
- 受阻時回覆：`阻塞原因`、`已嘗試`、`下一個可行方案`

## OpenSpec Workflow

artifacts 目錄：`openspec/changes/<change-id>/`（proposal → specs → design → tasks）

**IMPORTANT：tasks.md 必須先建立才能開始實作；禁止先寫程式再補文件。**

## Anti-Loop Protocol

同一問題連續失敗 3 次，立即停止並回報：
1. `嘗試紀錄`：做了什麼、錯誤訊息
2. `替代方案`：至少 2 個可行路徑與代價
3. `建議決策`：推薦下一步與原因

## 強制後置步驟（無例外、無條件豁免）

### Agent 調用清單
<!-- SSOT: 以下為 Agent 正式名稱，其他檔案如有衝突以本清單為準 -->

| 觸發條件 | 必須啟動 | 執行時機 |
|---------|---------|---------|
| 任何 Edit/Write | code-reviewer-zdpos_dev | 最後一步 |
| bug fix 或新功能 | tdd-guide-zdpos_dev | code-reviewer-zdpos_dev 前 |
| SQL / 資料庫操作 | database-reviewer-mysql | code-reviewer-zdpos_dev 前 |
| 認證/授權/加密/金額 | security-reviewer-zdpos_dev | code-reviewer-zdpos_dev 前 |

**執行順序**（若多項觸發）：tdd-guide → database-reviewer-mysql → security-reviewer → code-reviewer-zdpos_dev

**豁免條款：** 無，任何理由（已手動驗證、計畫已批准、只改一行）都不豁免。**唯一例外**：patch 前沒有 Edit/Write（純研究/規劃）→ 不跑 code-reviewer-zdpos_dev。

### 自檢清單（每次任務回覆前）

1. **Edit/Write 後？** → code-reviewer-zdpos_dev 已跑？ YES/NO
2. **Bug fix/新功能？** → tdd-guide-zdpos_dev 已跑？ YES/NO
3. **涉及 SQL?** → database-reviewer-mysql 已跑？ YES/NO
4. **涉及安全/認證/金額?** → security-reviewer-zdpos_dev 已跑？ YES/NO
5. **有新陷阱記錄？** → MEMORY.md 已更新？ YES/NO
6. **回顧已記錄？** → skill-retrospective.md 已追加？（每 5 筆更新統計摘要） YES/NO

若任一答案為 NO（且該項適用），補跑對應 agent 後再回覆。

## Testing & Validation

**IMPORTANT：實作完成後必須主動執行相關測試，以驗證變更正確性。**

- 單元測試：Docker PHPUnit
- 瀏覽器驗證（任一方式）：
  - playwright-cli：`playwright-cli snapshot <url>`（可重複執行、留快照至 `.playwright-cli/`）
  - 手動瀏覽器：適用 playwright-cli 無法涵蓋的互動流程
  - 基準 URL：`https://www.posdev.test/dev3/controller/action`
- 日誌：`protected/runtime/application.log`

```bash
# Docker PHPUnit 指令完整變體見 .claude/rules/php/testing.md（SSOT）
```
