---
name: zdpos-js-lint-config
description: ESLint 9 flat config tier 結構 (Tier 1 / 1A / 1.5 / 1.6 / 1.7 / 2 + Global ignores)、自定 AST selector、`zdposLegacyGlobals` 三檔同步、TypeScript noEmit gate 設計。Use when 規劃 per-leaf cleanup、改 eslint.config.js / tsconfig.json / ambient.d.ts、frontend-reviewer 審 tier 一致性、新檔該落哪 tier 拿不定。Not for 日常寫 JS 業務邏輯（用 .claude/rules/frontend.md 即可）。
---

# zdpos JS 靜態檢查 config 內結構（Tier + Selector + 白名單）

`.claude/rules/js/static-checks.md` 的細節版。Rule 內僅保留工具表 + skill 路標；本 skill 載入完整 tier 設計、AST selector、`zdposLegacyGlobals` 白名單分類、進度衡量 grep。

> SSOT 仍是 `eslint.config.js`。本 skill 是「對映文件」，避免直接讀 1000+ 行 config 才能理解設計。

---

## ESLint config 結構（`eslint.config.js`）

### Tier 1：嚴格規則（`js/zpos/**/*.js` Stage A-D 37 leaf + `js/components/**`）

- `no-undef: error` — 偵測未宣告全域引用
- `no-implicit-globals: error` — 禁止 script-top 隱式全域（IIFE 不受影響）
- `no-restricted-syntax: error` — 禁止 `$.ajax` / `$.post` / `$.get` / `fetch` / `axios`
- `no-restricted-globals: error` — 補 `MemberExpression` 形式（`window.fetch` 等）

### Tier 1A：`js/zpos/jsdoc-globals.js`（ambient typedef SSOT）

- `no-implicit-globals: off` — spec design 要求保持 script-top SSOT，無法 IIFE 包覆

### Tier 1.5：core 檔豁免

| 檔案 | 角色 |
|---|---|
| `js/zpos.js` | legacy monolith |
| `js/zpos.v2.js` | orchestrator |
| `js/mpos.js` | mobile POS wrapper |
| `js/pos_core.js` | core utilities |
| `js/main.js` | startup script |
| `js/zpos/pos-init-helpers.js` | 2026/05/15 mechanical 從 v2.js 抽取 |
| `js/zpos/pos-runtime-helpers.js` | 2026/05/15 mechanical 從 v2.js 抽取 |

豁免 4 條規則（`no-undef` / `no-implicit-globals` / `no-restricted-syntax` / `no-restricted-globals`）。

**理由**：這幾檔為跨 leaf 全域狀態的根源，`no-undef` 會誤觸發上百筆「cross-leaf 引用」、「PHP-style polyfill」、「late-init runtime global」；維持 `no-undef` 反而會干擾真實 bug 發現。

### Tier 1.6：`js/admin/**` 豁免

| 規則 | 設定 |
|---|---|
| `no-restricted-syntax` | off |
| `no-restricted-globals` | off |
| `no-implicit-globals` | off |
| `no-undef` | error（保留） |

**理由**：admin 頁面不載入 POS facade，無 `POS.list.ajaxPromise` / `POS.postData` 可用；`.claude/rules/frontend.md` 的「POS 為 SSOT，禁用 $.ajax」對 admin scope 自然不適用。admin 採 script-top globals 直接掛 `window` 的傳統模式，不需 IIFE。

### Tier 1.7：deferred-migration（Stage C/D 含遺留 $.ajax/axios）

| 檔案 | 行數 | Stage | 待清理 |
|---|---|---|---|
| `js/zpos/pos.js` | 2.6K | C | 5 個 $.ajax callsite |
| `js/zpos/itempanel.js` | 中型 | B | 3 個 $.ajax callsite |
| `js/zpos/tableseats.js` | 中型 | B | 2 個 $.ajax callsite |
| `js/components/item-remark-dialog.js` | - | components | 2 個 axios callsite |

豁免 `no-restricted-syntax` + `no-restricted-globals`，但保留 `no-undef` + `no-implicit-globals`（真實 bug 仍會被攔截）。

**收斂目標**：每個 per-leaf PR 把對應檔的 `$.ajax` 改寫成 `POS.list.ajaxPromise` / `POS.postData`，並從本 tier 移出。

### Tier 2：`js/tests/**/*.js`（jest 環境）

- `sourceType: 'commonjs'` + `globals.jest` + `globals.node`
- `no-undef: error`、`no-implicit-globals: off`（CommonJS module scope）

### Global ignores

- 第三方 vendor（`ckeditor` / `ckfinder` / `jquery-*` / `dataTables.*` / `paho-mqtt` / `js/jqPlug/**` / `js/ubereats*/**` / `js/ueditor/**` / `js/utils/**` / `js/service*/**` / `js/omniorder/**` / `js/oss/**` / `js/modules/**` / `js/async/**` / `js/dashboard/**`）
- 既存技術債：`js/admin/core/RecordTable.js`（ES2022 class field）
- spec task 2.7「最費工」分多 PR 收斂：`js/zpos/list.js`（14.7K 行最大 leaf）— 後續清理路徑：抽出 section 至獨立小檔（如 `list-receipt.js` / `list-shopping.js`），獨立小檔受 Tier 1 嚴格規則約束

> **Hook 端的 vendor 判定** SSOT 在 dhpk js module 的 `modules/js/hooks/_lib/js-tier-detect.sh`（`detect_js_tier()`），zdpos 的 core/vendor 清單經 settings.local.json `js_core_files` / `js_vendor_globs` userConfig 覆寫（2026-06-12 de-fork，原本地 `.claude/hooks/_lib/js-tier-detect.sh` 已刪）。需與 ESLint Global ignores 保持一致：新增 vendor 路徑時 config 與 ESLint 兩處同步。

---

## 自定 `no-restricted-syntax` AST selector

`eslint.config.js` 內 `restrictedAjaxSyntax`：

| Selector | 目的 |
|---|---|
| `CallExpression[callee.object.name="$"][callee.property.name=/^(ajax\|post\|get)$/]` | $.ajax / $.post / $.get |
| `CallExpression[callee.object.name="jQuery"][callee.property.name=/^(ajax\|post\|get)$/]` | jQuery.ajax / .post / .get |
| `CallExpression[callee.name="fetch"]` | bare `fetch(...)` |
| `CallExpression[callee.type="MemberExpression"][callee.object.name=/^(window\|globalThis)$/][callee.property.name="fetch"]` | `window.fetch` / `globalThis.fetch` |
| `ImportDeclaration[source.value="axios"]` | axios ESM import |
| `CallExpression[callee.name="axios"]` | bare `axios(...)` |
| `CallExpression[callee.object.name="axios"]` | `axios.get(...)` |

---

## 全域白名單（`zdposLegacyGlobals`）

集中於 `eslint.config.js` 內 `zdposLegacyGlobals` 常數。分類：

- **POS namespace**：`POS` / `Display` / `Customer` / `Booking` / `Thread` / `Item` / `List` / `ClassPanel` / `ItemPanel` 等
- **PHP polyfill**：`isset` / `is_array` / `number_format` / `implode` / `array` / `global`
- **跨 leaf re-export**：`VirtualKey` / `ButtonAction` / `AccAction` / `SplitAcc` / `Status` / `FlowHandler` / `ResponsedEventHandler` 等
- **vendor lib**：`_` (lodash) / `moment` / `sprintf` / `async` / `Swal` / `QRCode` / `Vue` / `CKEDITOR` / `html2canvas` / `Loader` / `DateTime` / `eTable` / `Column` / `DataProvider` / `validators` / `axios`
- **UI helper**：`z_alert` / `z_confirm` / `z_input` / `confirmDialog` / `new_alert` / `setInputKeyboard` / `hideLoading` / `showLoading`
- **POS state runtime globals (writable)**：`socket` / `SaveData_timer` / `readCard_timer` / `aPayments` / `oldLiffCouponAmt` / `NfullnGift` / `employee_name` / `pointLimit` / `serviceType` / `storeType` / `priceType` / `paytype` / `payment` / `arc_flag` / `lock` / `flag` / `gpnm` 等
- **Admin DataTables editor**：`editText` / `editOption`

**新增 leaf 引入新全域時 MUST 三處同步**：

1. `eslint.config.js` — `zdposLegacyGlobals` 加入
2. `js/zdpos-ambient.d.ts` — TypeScript 型別宣告同步
3. `js/zpos/jsdoc-globals.js` — JSDoc 型別 SSOT

任一不同步 → ESLint 或 tsc 報 `no-undef` / 型別錯誤。

> 詳細規則、19 leaf 過渡分類、漸進策略、tsconfig 配置決策、grep gameable 歷史教訓全部進度細節 → skill `zdpos-js-static-check-strategy`。

---

## 進度衡量速查

```bash
# 看當前 strict / nocheck / unmarked 分佈
/ts-check-status

# 手動版（exit gate = 兩個 find 都輸出空才達成）
find js/zpos -maxdepth 1 -name '*.js' -exec grep -L '^\s*//\s*@ts-check\s*$' {} \;
find js/zpos -maxdepth 1 -name '*.js' -exec grep -l '^\s*//\s*@ts-nocheck' {} \;
```

> **重要 trap**：`@ts-check` / `@ts-nocheck` 行錨點偽通過陷阱 — 弱 `grep -L '@ts-check'` 會被 `// TODO: @ts-check` 或 `// see @ts-check` 註解假裝啟用。必用 line-anchored regex `^\s*//\s*@ts-check\s*$`，且只認單一獨立行。詳見 `MEMORY.md::trap_tscheck_grep_gameable.md`。

---

## 相關 spec

- `openspec/changes/modernize-zpos-js-static-checks/proposal.md`
- `openspec/changes/modernize-zpos-js-static-checks/design.md`（D1-D4 ESLint + TypeScript 靜態檢查決策）
- `openspec/changes/modernize-zpos-js-static-checks/specs/zpos-static-check-gate/spec.md`
- `openspec/changes/modernize-zpos-js-static-checks/tasks.md`
