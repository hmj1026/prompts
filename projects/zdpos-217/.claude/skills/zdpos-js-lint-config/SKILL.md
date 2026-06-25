---
name: zdpos-js-lint-config
description: zdpos JS 靜態檢查的 config 結構 SSOT 對映 — ESLint 9 flat config tier 結構 (Tier 1 / 1A / 1.5 / 1.6 / 1.7 / 2 + Global ignores)、自定 `restrictedAjaxSyntax` AST selector、`zdposLegacyGlobals` 白名單分類、tsconfig noEmit gate 設計。Use when 改 eslint.config.js / tsconfig.json / js/zpos/zdpos-ambient.d.ts 的設定本身、判斷新檔或新全域該落哪個 tier / 哪一類白名單、frontend-reviewer 審 tier 一致性、新增 vendor 路徑要 config 與 hook 兩處同步。Not for：跑 per-leaf `// @ts-check` PR 的執行流程與進度量測（→ skill `zdpos-js-static-check-strategy`）、把巨檔拆成 leaf module（→ skill `zdpos-legacy-js-refactor`）、日常 JS 業務邏輯（→ `.claude/rules/frontend.md`）。
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

**新增 leaf 引入新全域 → 三檔同步**（`eslint.config.js` / `js/zpos/zdpos-ambient.d.ts` / `js/zpos/jsdoc-globals.js`），任一漏更 → ESLint 報 `no-undef` 或 tsc 報 TS2304。

> 同步程序（readonly/writable 標註、漂移防線）、`// @ts-check` 漸進策略、19 leaf 過渡分類、tsconfig 配置決策、grep-gameable 歷史教訓 → SSOT skill `zdpos-js-static-check-strategy`。

---

## 進度衡量速查

```bash
# 全檔型別檢查（noEmit gate）
npm run typecheck

# strict opt-in 分佈（exit gate = 兩個 find 都輸出空才達成）
find js/zpos -maxdepth 1 -name '*.js' -exec grep -L '^\s*//\s*@ts-check\s*$' {} \;   # 未啟用 strict 的 leaf
find js/zpos -maxdepth 1 -name '*.js' -exec grep -l '^\s*//\s*@ts-nocheck' {} \;     # 仍 @ts-nocheck 過渡
```

> ⚠️ 必用上面的 **line-anchored** regex；弱 `grep -L '@ts-check'` 會被註解內 token（`// TODO: @ts-check`）騙成偽綠。完整 grep-gameable 教訓 → skill `zdpos-js-static-check-strategy` + memory `trap_tscheck_grep_gameable.md`。

---

## 相關規範

- SSOT rule：`.claude/rules/js/static-checks.md`（工具鏈 + enforce 點 + skill 路標）
- 姊妹 skill：`zdpos-js-static-check-strategy`（per-leaf 執行 / 三檔同步程序 / Phase 2 exit gate）
- Capability `zpos-static-check-gate`：OpenSpec change `modernize-zpos-js-static-checks` 已落地（Phase 1 ESLint + Phase 2 TS noEmit），change dir 已隨歸檔移除；現況防線以上述 SSOT rule 為準。
