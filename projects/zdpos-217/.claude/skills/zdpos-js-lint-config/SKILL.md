---
name: zdpos-js-lint-config
description: eslint tier：為何有 Tier 1 / 1.5 / 1.6 / 1.7，新檔或新全域該落哪一層。Use when 改 eslint.config.js 或 tsconfig.json，或判斷新路徑的 tier。Not for per-leaf @ts-check（zdpos-js-static-check-strategy）或巨檔抽出（zdpos-legacy-js-refactor）。
---

# zdpos JS 靜態檢查 — 為何有這些 tier

檔案名單與規則值以 `eslint.config.js` 為準。本檔只回答「為什麼這樣分」。

## Tiers

### Tier 1 — 嚴格 IIFE leaf

`js/zpos/**`、`js/components/**` 走 `no-undef` + 禁 `$.ajax` / `fetch` / `axios`。這是 POS 載入鏈上的目標態。

### Tier 1A — `jsdoc-globals.js`

該檔必須 script-top（無 IIFE），view 才能覆寫 lexical binding，所以關 `no-implicit-globals`。override 必須寫在 Tier 1 之後。

### Tier 1.5 — core / late-init 根源

monolith（`zpos.js` / `zpos.v2.js` 等）與從 v2 抽出的 helpers 是跨 leaf 全域的來源。開 `no-undef` 會被 polyfill / late-init 淹沒，真實 bug 反而看不見。名單見 config。

收斂完成條件：helpers 內 `$.ajax` 改 POS wrapper 後，該檔不在 Tier 1.5 `files` 陣列。

### Tier 1.6 — admin

admin 不載入 POS facade，沒有 wrapper 可改；採 script-top `window` 模式。保留 `no-undef` 抓打錯名，不套 AJAX 禁令與 `no-implicit-globals`。

### Tier 1.7 — 遺留 `$.ajax` 待遷

mechanical extraction 留下的既有 callsite，分 PR 改 wrapper。保留 `no-undef` + `no-implicit-globals`。

收斂完成條件：該檔 `$.ajax` / `axios` 清完，且不在 Tier 1.7 `files` 陣列。

### Tier 2 — tests

`js/tests/**` 是 jest + commonjs；不套 AJAX 禁令。

### Global ignores

vendor、`list.js`（抽出小檔才進 Tier 1）、既有 ES2022 技術債。名單見 config 頂部 `ignores`。

新增 vendor 路徑的完成條件：`eslint.config.js` ignores 與 dhpk `js-tier-detect.sh`（zdpos `js_vendor_globs` / `js_core_files`）同一 glob 都加上。

## 禁哪些呼叫形狀

攔截 jQuery `$.ajax` / `.post` / `.get`、`window.fetch` / `globalThis.fetch`、`axios` 的 CallExpression 與 ImportDeclaration。精確 selector 以 `eslint.config.js` 的 `restrictedAjaxSyntax` 為準。

## 全域白名單分類

識別名以 `eslint.config.js` 的 `zdposLegacyGlobals` 為準。新全域先對上類再標 `readonly` / `writable`：

- POS namespace
- PHP polyfill
- 跨 leaf re-export
- vendor lib
- UI helper
- POS state runtime（writable）
- Admin DataTables editor

新全域同步步驟 → skill `zdpos-js-static-check-strategy`。

## 相關

- SSOT rule：`.claude/rules/js/static-checks.md`
- per-leaf `@ts-check` 執行：skill `zdpos-js-static-check-strategy`
