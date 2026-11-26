---
name: zdpos-js-modernization
description: 前端 JS 現代化與靜態檢查（ESLint tier、@ts-check、legacy extraction）。Use when 修改 eslint.config.js／tsconfig.json 或調整 tier 與全域白名單、撰寫／驗收 per-leaf @ts-check PR、或規劃／執行 legacy JS 巨檔（zpos／pos_core／mpos／main／jqPlug）抽出與 POS E2E spec。
---

# zdpos 前端 JS 現代化與靜態檢查

## 分支路由

依任務類型直接載入對應分支參考檔：

| 任務類型 | 觸發情境 | 參考文件 |
| :--- | :--- | :--- |
| **ESLint Tier 與全域白名單** | 修改 `eslint.config.js`／`tsconfig.json`、判定新路徑或 vendor 所屬 tier（Tier 1／1A／1.5／1.6／1.7／2／ignores）、確認 AJAX 禁令形狀或 `zdposLegacyGlobals` 分類 | [`references/lint-tiers.md`](references/lint-tiers.md) |
| **per-leaf `@ts-check` Cleanup** | 撰寫或驗收單支 leaf 的 `@ts-check` PR、判定檔案走 strict 或 `tsconfig.json` `exclude`、引入新全域執行三檔同步 | [`references/ts-check-cleanup.md`](references/ts-check-cleanup.md) |
| **Legacy 巨檔抽出（Extraction）** | 將 `js/zpos`、`pos_core`、`mpos`、`main`、`jqPlug` 拆為 IIFE leaf、執行 audit-grep 編寫 `design.md` 邊界清單、引用 800 LOC 例外條款、執行三段驗證 | [`references/legacy-extraction.md`](references/legacy-extraction.md) |

Legacy extraction 補充參考：

- `zpos.js` Stage A–D 完整拆分紀錄與數據 → [`references/zpos-stage-a-d-case-study.md`](references/zpos-stage-a-d-case-study.md)
- POS 公開 API E2E spec 硬規則（dispatch + rendering 雙斷言；禁止 probe-and-pass）→ [`references/e2e-antipatterns.md`](references/e2e-antipatterns.md)

## 跨分支共通原則

以下三條跨全部任務適用：

- **Static checks SSOT**：靜態檢查規範與 gate 以 `.claude/rules/js/static-checks.md` 為單一真實來源；業務邏輯改動遵循 `.claude/rules/frontend.md`。
- **No build step**：所有 leaf 以 `<script src>` 直接載入瀏覽器；禁止於 production load chain 引入 ES module `import`／`export`、TypeScript runtime 或 bundler 產物。
- **Worktree 測試前置**：在 linked worktree 執行 PHPUnit、precommit／Jest 或 Playwright E2E 前，先依 skill `zdpos-git-worktree` 完成環境 setup。

- **完成條件**：已載入並套用任務所屬分支參考檔之全部規則與驗證步驟、維持 no-build-step 與 SSOT 一致性，且 linked worktree 測試前置就緒。
