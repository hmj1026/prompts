---
name: zdpos-js-static-check-strategy
description: zdpos `// @ts-check` per-leaf 漸進清理的執行 playbook（capability `zpos-static-check-gate`）— 寫單支 leaf 的 @ts-check cleanup PR、三檔同步程序 (eslint.config.js / js/zpos/zdpos-ambient.d.ts / jsdoc-globals.js)、19 leaf 過渡分類、tsconfig exclude vs 翻回 strict 的判斷、line-anchored 進度量測與 Phase 2 exit gate 驗收。Use when 你正在做或驗收一支 per-leaf cleanup PR、判讀 @ts-check / `npm run typecheck` 進度、決定某 leaf 該 strict 還是 @ts-nocheck。Not for：ESLint tier 結構 / AST selector / 白名單分類等 config 設定（→ skill `zdpos-js-lint-config`）、把巨檔抽成 leaf module（→ skill `zdpos-legacy-js-refactor`）、一般 lint 規則查詢（→ `.claude/rules/js/static-checks.md`）。
---

# zdpos-js-static-check-strategy

> Capability：`zpos-static-check-gate`（OpenSpec change `modernize-zpos-js-static-checks` Phase 2）
> SSOT rule：[`.claude/rules/js/static-checks.md`](../../rules/js/static-checks.md)

本 skill 承載 rule 中過長的執行細節，避免 always-loaded rule 過胖。

## 全域白名單三處同步（`zdposLegacyGlobals`）

新增 leaf 引入新全域時，**MUST** 三處同步更新（漂移風險來源 — 三份清單獨立維護，無自動 derivation）：

1. **`eslint.config.js`** 的 `zdposLegacyGlobals` 常數（lint 端 `readonly` / `writable` 標註）— SSOT for `no-undef`
2. **`js/zpos/zdpos-ambient.d.ts`** 的 `declare var X: any` 段（TS 端 bare identifier resolution）— SSOT for `tsc --noEmit`
3. **`js/zpos/jsdoc-globals.js`** 的 `@typedef`（**僅當該全域型別非 `any` 需要精煉時**；ambient `.d.ts` 已兜底）— optional refinement

per-leaf cleanup PR 漏更新任一處 → 後續 PR 會 surface 為 `no-undef` 或 TS2304；CI 會擋住 merge，但 reviewer 需主動檢查三檔同步。

## `// @ts-check` 漸進策略（Phase 2）

- 每個 leaf 一個 PR：加 `// @ts-check` + 修齊 JSDoc + 跑 Jest contract 確認無 regression
- 沿用 Stage A-D 的 mechanical extraction 節奏
- 卡住的 leaf 可用 `// @ts-nocheck` 暫時跳過並加 TODO

進度衡量（二步驗證，line-anchored 避免被註解內 token 欺騙）：

```bash
# Step 1：所有 leaf 已啟用 strict `// @ts-check`（line-anchored，攔截 `// @ts-nocheck`）
#   弱版本 `grep -L '@ts-check'` 會接受 `// @ts-nocheck` + TODO 註解內含 token 的 false-green；
#   嚴格版本以行首為 anchor，註解內 token 不匹配
find js/zpos -maxdepth 1 -name '*.js' -exec grep -L '^\s*//\s*@ts-check\s*$' {} \;   # MUST empty

# Step 2：尚在 `// @ts-nocheck` 過渡（per-leaf cleanup PR 收斂指標）
find js/zpos -maxdepth 1 -name '*.js' -exec grep -l '^\s*//\s*@ts-nocheck' {} \;     # 觀察數量遞減
```

全檔型別錯誤（非 opt-in 分佈）另跑 `npm run typecheck`。

Phase 2 exit gate = Step 1 輸出為空。Step 2 為 governance 指標。

### 19 leaf 過渡分類（2026-05-21 baseline）

分兩類 exit path：

- **17 個 regular leaf**（含 `Paytype` / `Item` / `Customer` / `Booking` / `Display` / `Thread` / `Remark` / `ItemPanel` / `TableSeats` / `VirtualKey` / `Zprinter` / `Control` / `ProcessControlSwitch` / `Book` / `SelectionPackage` / `new-alert` / `pos.js`）
  - blocker：jsdoc-globals.js narrow `@typedef` 與 constructor pattern inference 衝突
  - exit path：per-leaf cleanup PR 拓寬 typedef 或精煉 JSDoc 後翻回 strict `// @ts-check`
- **2 個 Tier 1.5 core-adjacent helper**（`pos-init-helpers.js` / `pos-runtime-helpers.js`）
  - blocker：跨 leaf 全域 late-init state（與 `js/zpos.js` / `js/zpos.v2.js` 共享 polyfill / runtime global），typedef 拓寬解決不了
  - exit path：**`tsconfig.json` 的 `exclude` 永久排除**（與 `js/zpos/list.js` 同類處理），而非翻回 strict。預期長期維持 `// @ts-nocheck`

per-leaf cleanup PR 動態時 MUST 先看 leaf 屬於哪一類；若 misjudge 把 Tier 1.5 helper 算進「典型 leaf cleanup」會浪費 effort。

### 歷史教訓：grep gameable

⚠️ 原 `grep -L '@ts-check'` 為 substring 比對 — 過渡時期若以 `// @ts-nocheck` 為主指令、TODO 註解內提及 `@ts-check`（如「TODO: enable @ts-check after typedef widening」），會被 grep 視為「該檔已含 @ts-check」而 false-green。MUST 用 `^\s*//\s*@ts-check\s*$` 嚴格行首 anchor 才能反映真實 strict opt-in 狀態。詳見 memory `trap_tscheck_grep_gameable.md`。

## `tsconfig.json` 配置（Phase 2）

> 實檔請直接讀 repo root `tsconfig.json`（本處不複製全文，避免漂移）。關鍵欄位：`allowJs:true` / `noEmit:true` / `strict:false` / `target:ES2017` / `module:CommonJS`；`include` 只收 `js/zpos/**`；`exclude` 排除 core 巨檔（`js/zpos.js` / `zpos.v2.js` / `mpos.js` / `pos_core.js` / `main.js`）、`list.js`、兩支 Tier 1.5 helper、`node_modules`、`build`。

**`checkJs` 設計選擇**：spec D4 文字寫 `checkJs: true`，但 D3「per-leaf opt-in」要求每個 leaf PR 加 `// @ts-check` 後才檢查。兩者邏輯衝突；以 D3 per-leaf 為準採 `checkJs: false`。全 37 leaf 加完 `// @ts-check` 後才翻回 `true`（spec task 5.8 exit gate）。

## `jsdoc-globals.js` ambient typedef 標準（Phase 2）

集中於 `js/zpos/jsdoc-globals.js`：

- `@typedef` for `POS`、`POS.list`、`POS.list.ajaxPromise`、`POS.post`、`POS.postData`
- `@typedef` for 主要模組 `Thread`、`Display`、`Customer`、`Booking`、`Item`

Phase 2 leaf PR 時透過 JSDoc `@type` / `@param` / `@returns` 標註，TS 透過 ambient typedef 解析跨 leaf 類型。

## 後續清理 / 規則演進

| 工作 | 觸發時機 |
|---|---|
| pos-init-helpers.js / pos-runtime-helpers.js 內 $.ajax 改 POS wrapper | per-PR 後從 Tier 1.5 移出回 Tier 1 |
| Tier 1.7 deferred-migration 檔案內 $.ajax / axios 改 wrapper | per-PR 後從 Tier 1.7 移出回 Tier 1 |
| list.js 14.7K 行分多 PR 拆 section | 抽出的小檔不在 ignores 內，受 Tier 1 約束 |
| 89 view inline `<script>` 納入 lint | Phase 2 task 6.5（前 20 個含 `pageConfigs` SSOT 的 view 優先） |

## 相關規範

- SSOT rule：`.claude/rules/js/static-checks.md`（工具鏈 + enforce 點 + skill 路標）
- 姊妹 skill：`zdpos-js-lint-config`（ESLint tier 結構 / AST selector / `zdposLegacyGlobals` 分類清單）
- Capability `zpos-static-check-gate`：OpenSpec change `modernize-zpos-js-static-checks` 已落地（Phase 1 ESLint + Phase 2 TS noEmit），change dir 已隨歸檔移除；現況防線以上述 SSOT rule 為準。
- 未來路徑：modular 穩定後一次性全 ESM 重構（屆時開獨立 OpenSpec change，本 capability 範圍外）
