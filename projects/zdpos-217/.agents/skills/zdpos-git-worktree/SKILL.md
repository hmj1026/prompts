---
name: zdpos-git-worktree
description: 'linked-worktree writer fence 與測試 setup。Use when subAgent 在 linked worktree 執行 edit/port/copy、跑 PHPUnit／precommit／Jest／Playwright，或排查 host-absolute `.git` pointer、`yii_framework`、`TracyBootstrap`、Jest／Playwright dependency failure。'
allowed-tools: Read, Bash(ls *), Bash(cat *), Bash(ln *), Bash(cp *), Bash(mkdir *), Bash(chmod *), Bash(npm *), Bash(git *), Bash(bash *), Bash(test *), Bash(node *), Bash(readlink *), Bash(realpath *), Bash(diff *), Bash(pwd *), Bash(stat *), Bash(unlink *), Bash(docker exec *)
---

# Linked Worktree Writer Fence + Test Setup

在 linked worktree 執行寫入或測試時，依序通過 `setup lease`、`writer lease` 與 host／container identity preflight，確保 writer、受保護 checkout、host／container 與實際輸出路徑皆可由 receipt 獨立核對。worktree 的 `.git` 可能指向 host absolute metadata，container 一律改讀對應的 main `.git/worktrees/<name>` mapping，且 preflight 與 runner 全程維持既有 `.git` 唯讀。

## 參考文件路由

| 情境 | 先讀檔案 | 涵蓋內容 |
|---|---|---|
| 第一個 edit／port／copy 前後驗收 receipt，或處理 host-absolute `.git` pointer／container identity mismatch | [references/writer-fence.md](./references/writer-fence.md) | task packet env vars、`worktree_state_oid` 腳本、fail-closed `INVALID_CHECKOUT` 與 post-write receipt、Setup lease 規則、Preflight 0 與 worktree root 檢查 |
| 準備跑 PHPUnit、precommit／Jest、Playwright，或排查 `yii_framework`、`TracyBootstrap`、`protected/runtime`、`node_modules`、E2E `POS_ACCOUNT` 錯誤 | [references/setup-traps.md](./references/setup-traps.md) | Traps 1–5 根因與指令（`protected/config` 必須 `cp -a`、web user permission probe、`node_modules` 暫時連結與清理、E2E credentials 注入）及 PHP／JS prerequisites 一條龍 |

## 角色權限邊界

| 角色 | 權限與單一職責 |
|---|---|
| **Orchestrator** | 掌握 ignored inventory、序列化派發 setup lease、計算 dispatch 前 `worktree_state_oid`，並在收尾獨立重查 before／after receipt（缺任一 receipt 即 GREEN 不成立）。 |
| **Setup lease owner**（orchestrator 或具名 setup worker） | 同一 shared／ignored path 一次只持一個 setup lease；唯一可執行 Trap 1–4 write blocks、prerequisites 一條龍與 gate 後暫時 symlink 清理的角色。 |
| **Implementation worker** | 僅在 writer root 的 allowlist 路徑寫入（allowlist 排除 setup paths）；第一個 write 前先過 writer fence，失敗即 fail-closed 停止並回報 `INVALID_CHECKOUT`（保持 zero-write，受保護 checkout 留給 orchestrator）；對 Trap 1–4 僅做 read-only 驗證，缺失即回報 `BLOCKED` 交由 setup lease owner。 |

## 執行流程與完成條件

### 1. Setup lease 與 baseline（Orchestrator／Setup lease owner）

依 documentation governance 完成 ignored inventory，並依下方套件矩陣序列化完成 Trap 1–4 setup lease，之後才計算 writer／protected `worktree_state_oid` 並派發 task packet（規格見 [references/writer-fence.md](./references/writer-fence.md)）。

**完成條件**：每個 setup path 皆記錄 exact output paths、before identity／absence、expected target、mode 與 cleanup owner，且 writer／protected baseline OID 已寫入 task packet。

### 2. Writer fence（Implementation worker，第一個 write 前）

執行 [references/writer-fence.md](./references/writer-fence.md) 的 pre-write 檢查並產出 before receipt；任一檢查失敗立即停止並回報 `INVALID_CHECKOUT`。

**完成條件**：before receipt 確認 `ACTUAL_ROOT == WRITER_ROOT != PROTECTED_ROOT`、branch／HEAD 符合，且 writer 與 protected `worktree_state_oid` 皆與 task packet 一致。

### 3. Linked-worktree 測試前置（Apply order 0–5）

依測試套件執行對應步驟；container runner 先過 Step 0，implementation worker 對 Trap 1–4 只執行 read-only 驗證（指令見 [references/writer-fence.md](./references/writer-fence.md) 與 [references/setup-traps.md](./references/setup-traps.md)）。

| Step | Action | 適用 |
|---|---|---|
| 0 | linked-worktree identity preflight：驗證 host common gitdir、safe basename、container mapped gitdir、雙側 root／HEAD／`HEAD^{tree}`；browser／E2E 另核對 thin-entry target config；native pointer failure 先歸類為 metadata portability failure 並改用 mapped `--git-dir` 驗證 | 所有 container runner；browser／E2E 需 route guard |
| 1 | read-only 驗證 orchestrator 以 shared-setup lease 建立的 `yii_framework` symlink | fast suite 起步 |
| 2 | `cp -a` 實體複製 `protected/config`（非 symlink，避免 `TracyBootstrap` redeclare） | fast suite + full suite |
| 3 | setup lease 建立 `protected/runtime/tracy`，並以實際 web user 執行 read-only permission probe 驗證可寫 | full PHP integration + E2E |
| 4 | 暫時連結 main checkout 的完整 `node_modules`，gate 完成後依 target 驗證再清理 | JS precommit／unit + E2E |
| 5 | 透過 skill `zdpos-environment`（POS UI Login）取得當次環境座標與 `POS_ACCOUNT`／`POS_PASSWORD` 並由本地環境變數注入 | E2E only |

**測試套件對應矩陣**：
- **PHP fast unit suite**：1 + 2
- **Full PHP integration suite**：1 + 2 + 3
- **Repository precommit／JS unit**：4
- **E2E (Playwright)**：container runner 先過 Step 0，依測試 bootstrap 套用 1–4，再以 5 注入 credentials

**完成條件**：Step 0 雙側 mapped `--git-dir`、root、HEAD 與 `HEAD^{tree}` 一致且既有 `.git` 未被寫入；對應套件矩陣之 Trap 1–5 檢查全數通過。

### 4. Post-write 收尾與獨立重查

1. **Implementation worker**：重跑 root／branch／HEAD 與 protected state 檢查，回報 writer current `worktree_state_oid`、allowlist delta 與實際 test output path。
2. **Setup lease owner**：JS／E2E gate 結束後驗證 `node_modules` symlink 指向 main checkout 再 `unlink`。
3. **Orchestrator**：獨立重查 before／after receipt 與 protected state OID。

**完成條件**：before／after receipt 完整、protected state OID 未變、變更全數落在 allowlist 內、`node_modules` 暫時 symlink 已清理且 package manifests 未異動，並經 orchestrator 獨立重查確認 GREEN。

## 資產邊界與交付聲明

- 不另放共用 script（worktree 只含 tracked files）。
- local agent skill 以 prompts repo 為 tracked canonical，透過 project symlink 投影至 consuming project；branch delivery SSOT 為 `<consuming-project-root>/docs/workflow/execution-policy.md`。
- deploy 與 review 須分別驗證 projected skill symlink 解析回本 canonical path，且該 consuming-project pointer 可由 fresh checkout 取得。
- local projection 僅供本機執行，不得作為 target branch 已 commit 或 branch delivery complete 的依據。

## Related

- skill `zdpos-environment`（POS UI Login）— 取得當次環境座標、登入流程與 credentials；本 skill 不保存帳密。
