---
name: zdpos-source-bound-verification
description: 來源綁定驗證（source-bound verification）。Use when 審查前將本地測試綁定至指定 checkout 與來源清單（check:record）、產出或核對 writer handoff（check:handoff／capture:baseline）、組裝或驗收 review packet（collect:review／verify:review），或處理 source drift／needsRecheck。
---

# 來源綁定驗證

先從目標 checkout 根目錄讀取 `.scratch/local-dev/docs/LOCAL_VERIFICATION.md` 對應章節；所有命令與輸出結構以該 checkout 的 `.scratch/local-dev/package.json` 與 runner 契約為準。

## 1. 固定來源與證據目錄

1. 記錄實體 Git 根目錄、HEAD 與 `git status --short`。
2. 列出本輪來源、測試與影響結果的所有輸入（含相關未追蹤、ignored 與外部相依輸入）。
3. 確認 runner 能涵蓋所列輸入，並揭露任何未納入雜湊的範圍（前後雜湊僅證明所列來源於兩次取樣時一致）。
4. 若並行 writer 仍改動必要輸入，待來源固定後再啟動驗證。
5. 每輪建立新的 evidence 目錄；保存前確認命令參數、raw 輸出與交接資料皆已去敏。

**完成條件**：實體 Git 根目錄、HEAD、`git status --short`、完整來源清單與未納雜湊揭露皆已記錄；來源已穩定；本輪獨立 evidence 目錄與去敏檢查完成。

## 2. 核對工具與 checkout 綁定

1. 一律從應用程式 Git 根目錄執行。
2. 若 `.scratch` 或 `local-dev` 經 symlink 指向外部工具包：
   - 確認 runner 決定應用程式根目錄的方式。
   - 執行 `check:handoff`、`capture:baseline`、`review:template`、`review:validate`、`collect:review`、`verify:review` 時，明確設定 `ZDPOS_HANDOFF_REPO_ROOT` 為應用程式根目錄的實體路徑。
   - 執行 handoff 時核對 stderr 輸出 `handoff root=<realpath>`。
3. `check:record` 依腳本位置決定根目錄，且拒絕來源路徑含 symlink；若實體工具根目錄落於另一個 checkout，將直接執行記為 `BLOCKED` 並停止執行。

**完成條件**：工具根目錄與目標應用程式 checkout 綁定已驗證（symlink 情境已設 `ZDPOS_HANDOFF_REPO_ROOT` 並核對 `handoff root=<realpath>`），或跨 checkout 時已記為 `BLOCKED`。

## 3. 依交付目標執行

依請求對應的目標執行並核對產物：

- **單一命令（`check:record`）**：依「並行工作時綁定檢查來源」執行。來源清單為非空 repo-relative 一般檔案路徑 JSON 陣列（排除清單自身與證據路徑）；PHP runner 依目標 checkout 的 `AGENTS.md` 選擇。核對 `result.json`、退出碼、raw 輸出與來源前後雜湊。
- **完整本地交接（`check:handoff`）**：依「Writer handoff」執行。傳入 `--files` 時提供頂層路徑陣列（縮小 `handoff.json` 的 `sourceScope`，完整七階段 worktree gate 仍全數執行）。逐項核對 `checks.stages`、`testInventory`、`sourceStability` 與 `completeHandoff`。納入容器內外部測試時，依 `--external-execution` 契約保存前後來源快照與 owned 環境座標，並先確認 JUnit 輸出目錄於容器內可寫且產物可供宿主機驗證。
- **編輯前 baseline（`capture:baseline`）**：依「Writer handoff」擷取指定檔案的當前工作樹，保留既有 WIP 與獨立 HEAD 快照；編輯完成後才擷取者標記為當下 checkpoint。`capture:baseline` 產出的 `source-files.json` 為 collector 使用的 `{"sourceFiles":[...]}` 物件；供 `check:handoff --files` 使用時，另存其中陣列並核對修改後的來源範圍。
- **Review packet（`collect:review` / `verify:review`）**：依「移交 packet 完整性檢查」產生並驗證 reviewer sidecar，再以 `collect:review` 組裝 manifest、命令結果、raw 證據與 sidecar；已有 receipt 時以 `verify:review` 核對，結果記於 `packet_integrity`。

**完成條件**：對應交付目標的 artifact、退出碼、raw 輸出與契約欄位皆已逐項核對。

## 4. 核對漂移與交付回報

1. 核對證據對應的來源範圍與 digest 仍符合目標 checkout。
2. 遇 `needsRecheck` 或來源漂移：保留原證據與命令原始結果，將現行來源驗證記為 `PARTIAL`；待新來源固定後補跑受影響檢查，並重取受影響的交接或 review。必要證據缺失時列明項目與原因。
3. 交付回報必備欄位（依本次請求列出各適用項目，未執行者記為 `NOT_RUN`）：
   - checkout 實體路徑與 HEAD
   - 來源清單與 digest
   - 執行命令、退出碼與證據路徑
   - 各項結果：本地檢查、完整交接與 packet 完整性各以對應 artifact 為準；DB-backed、DEV、裝置、provider 與部署驗收沿用各流程的環境、授權與證據條件

**完成條件**：每項適用驗證皆具對應 artifact 佐證，或明確標註 `PARTIAL`／`BLOCKED`／`NOT_RUN` 與缺失原因。
