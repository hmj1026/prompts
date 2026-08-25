---
name: zdpos-js-static-check-strategy
description: "@ts-check：單支 leaf 的 cleanup playbook。Use when 寫或驗收 per-leaf @ts-check PR，或判斷該檔走 strict 還是 tsconfig exclude。Not for eslint tier（zdpos-js-lint-config）或巨檔抽出（zdpos-legacy-js-refactor）。"
---

# zdpos-js-static-check-strategy

> Capability：`zpos-static-check-gate`。SSOT rule：[`.claude/rules/js/static-checks.md`](../../rules/js/static-checks.md)

## 1. 先分類再動手

完成條件：能指出該檔走哪一條 exit path，再開始改。

| 判準 | Exit path |
|---|---|
| 檔在 `tsconfig.json` `exclude`（現況：`list.js`、`pos-init-helpers.js`、`pos-runtime-helpers.js`；以實檔為準） | 永久 exclude，不是 cleanup PR |
| 檔首已是恰好一行 `// @ts-check` | 本 skill 不適用；改業務邏輯走 `.claude/rules/frontend.md` |
| 其餘 `js/zpos/**/*.js`（含 `features/`） | per-leaf cleanup，目標檔首恰好 `// @ts-check` |

`exclude` 內的 helpers 是跨 leaf late-init 根源，typedef 拓寬解決不了；`list.js` 走抽出小檔（抽出檔受 Tier 1），不是翻回 strict。

## 2. 三檔同步（新全域）

新增 leaf 引入新全域時，三處一起改（無自動 derivation）：

1. `eslint.config.js` 的 `zdposLegacyGlobals`（lint 端 `readonly` / `writable`）
2. `js/zpos/zdpos-ambient.d.ts` 的 `declare var X: any`（TS 端 bare identifier）
3. `js/zpos/jsdoc-globals.js` 的 `@typedef` — **僅當**該全域型別不是 `any` 需要精煉；ambient `.d.ts` 已兜底

完成條件：該識別名在 (1)(2) 都出現；若跳過 (3)，理由是型別為 `any`。`npm run lint` 與 `npm run typecheck` 不因該全域報 `no-undef` / TS2304。

## 3. per-leaf cleanup PR

每個 leaf 一個 PR：檔首改為 `// @ts-check` + 修齊 JSDoc + 跑該 leaf 的 Jest contract。

卡住時可暫用 `// @ts-nocheck` 並加 TODO，但 TODO 內的 `@ts-check` token **不算**已啟用。

進度用行首 anchor，避免註解內 token 偽綠：

```bash
# 未啟用 strict 的 leaf（對照 §1 exclude 後，其餘即 cleanup 佇列）
find js/zpos -name '*.js' -exec grep -L '^\s*//\s*@ts-check\s*$' {} \;

# 仍 @ts-nocheck 過渡（應只剩 exclude 內的檔）
find js/zpos -name '*.js' -exec grep -l '^\s*//\s*@ts-nocheck' {} \;
```

單支 PR 完成條件：

- 該 leaf 檔首為 `// @ts-check`
- 若引入新全域：§2 三檔同步完成
- `npm run typecheck` 與該 leaf 的 Jest contract 綠

Campaign 完成條件：第一條 find 在扣掉 `tsconfig.json` `exclude` 之後為空；第二條 find 只列出 exclude 內的檔。全檔型別錯誤另跑 `npm run typecheck`。

弱 `grep -L '@ts-check'` 會把 `// @ts-nocheck` + TODO 內的 token 當成已啟用。MUST 用 `^\s*//\s*@ts-check\s*$`。

## 4. tsconfig / JSDoc

實檔請讀 repo root `tsconfig.json`。`checkJs` 維持 `false`（per-leaf opt-in）；非 exclude leaf 都加上 `// @ts-check` 之後才改 `true`。

Ambient typedef 在 `js/zpos/jsdoc-globals.js`。leaf 用 JSDoc `@type` / `@param` / `@returns` 接上。

## 相關

- SSOT rule：`.claude/rules/js/static-checks.md`
- eslint tier 為何這樣分：skill `zdpos-js-lint-config`
