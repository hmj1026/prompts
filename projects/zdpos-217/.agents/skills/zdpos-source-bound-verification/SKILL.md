---
name: zdpos-source-bound-verification
description: zdpos-217 來源綁定驗證。用於審查前需要將本地測試綁到指定 checkout 與來源清單、核對 writer handoff 或 review receipt，或處理 source drift／needsRecheck。
---

# 來源綁定驗證

從目標 checkout 根目錄讀取 `.scratch/local-dev/docs/LOCAL_VERIFICATION.md` 的對應章節。以該 checkout 的 `.scratch/local-dev/package.json` 與 runner 契約為準。

## 固定來源

記錄實體 Git 根目錄、HEAD 與 `git status --short`。列出本輪來源、測試及會影響結果的輸入，包含相關未追蹤、ignored 與外部相依輸入。確認 runner 能涵蓋這些輸入，並揭露任何未納入雜湊的範圍。前後雜湊只能證明所列來源在兩次取樣時一致。若並行 writer 仍會改動必要輸入，等來源固定後再驗證。每輪使用新的 evidence 目錄，保存前先確認命令參數、raw 輸出及交接資料已去敏。

## 核對工具與 checkout 的綁定

從應用程式 Git 根目錄執行。若 `.scratch` 或 `local-dev` 經由 symlink 指向外部工具包，確認 runner 如何決定應用程式根目錄，並對 `check:handoff`、`capture:baseline`、`review:template`、`review:validate`、`collect:review`、`verify:review` 明確設定 `ZDPOS_HANDOFF_REPO_ROOT` 為應用程式根目錄的實體路徑。執行 handoff 時核對 stderr 的 `handoff root=<realpath>`。`check:record` 由腳本位置決定根目錄，且會拒絕來源路徑中的 symlink。若實體工具根目錄落在另一個 checkout，將直接執行記為 `BLOCKED`。

## 依交付目標執行

- **單一命令**依「並行工作時綁定檢查來源」執行 `check:record`。來源清單使用非空的 repo-relative 一般檔案路徑 JSON 陣列，排除清單自身與證據路徑。核對 `result.json`、退出碼、raw 輸出及來源前後雜湊。PHP runner 依目標 checkout 的 `AGENTS.md` 選擇。
- **完整本地交接**依「Writer handoff」執行 `check:handoff`。使用 `--files` 時傳入頂層路徑陣列。它縮小 `handoff.json` 的 `sourceScope`，完整七階段 worktree gate 仍會執行。逐項核對 `checks.stages`、`testInventory`、`sourceStability` 和 `completeHandoff`。若納入容器內的外部測試，依 `--external-execution` 契約保存前後來源快照和 owned 環境座標，先確認 JUnit 輸出目錄在容器內可寫，且產物可供宿主機驗證。
- **編輯前 baseline**依「Writer handoff」先 capture 指定檔案的當前工作樹，保留既有 WIP 與獨立的 HEAD 快照。編輯完成後才取得的快照標為當下 checkpoint。`capture:baseline` 產出的 `source-files.json` 是 collector 使用的 `{"sourceFiles":[...]}` 物件。要供 handoff 的 `--files` 使用，另存其中的陣列並核對修改後的來源範圍。
- **Review packet**依「移交 packet 完整性檢查」產生並驗證 reviewer sidecar，再用 `collect:review` 組裝 manifest、命令結果、raw 證據與 sidecar。已有 receipt 時用 `verify:review` 核對，將結果記在 `packet_integrity`。

## 核對與回報

核對證據對應的來源範圍和 digest 是否仍符合目標 checkout。遇到 `needsRecheck` 或來源不符，保留原證據與命令的原始結果，將現行來源的驗證記為 `PARTIAL`。固定新來源後補跑受影響的檢查，並重取受影響的交接或 review。必要證據缺失時列明項目與原因。

交回 checkout／HEAD、來源清單與 digest、命令、退出碼及證據路徑。依本次請求回報各適用項目，未執行者記為 `NOT_RUN`。本地檢查、完整交接與 packet 完整性的結果各以對應 artifact 為準。DB-backed、DEV、裝置、provider 與部署的驗收沿用各流程的環境、授權與證據條件。
