---
name: zdpos-legacy-js-refactor
description: extraction：把 js/zpos、pos_core、mpos、main、jqPlug 巨檔拆成 leaf。Use when 規劃抽出或寫 design.md 邊界清單。Not for 已抽出 leaf 的 @ts-check（zdpos-js-static-check-strategy）或改 eslint tier（zdpos-js-lint-config）。
allowed-tools: Read, Bash(rg *), Bash(grep *), Bash(awk *), Bash(find *), Bash(wc *), Bash(ls *), Bash(git *)
---

# zdpos Legacy JS Refactor Playbook

## 1. 共通契約

這 5 條從 zpos.js Stage A-D（2026-05-15）萃取，任何新一輪抽出直接套用。

- **原始檔鎖死**：原始巨檔 md5 永遠等於 develop 版本；PR 不修改該檔。原始檔作為 fallback「未拆版本」常駐，leaf 出包可以一行 partial 切回。
- **Partial SSOT**：載入順序集中在唯一 PHP partial（e.g. `protected/views/layouts/partials/_pos_modular_assets.php` 之於 zpos），陣列就是 SSOT；facade 檔（e.g. `pos.js`）為陣列最後一個 leaf URL。對 mpos / pos_core / jqPlug：抽出 PR0 先確認或新建 `protected/views/layouts/partials/_<module>_modular_assets.php`，避免抽出過程回頭改 view layout。
- **IIFE + window.X re-export 模板**：所有 leaf 採以下骨架，不改寫為 ES6 class / arrow function / `'use strict';`：
  ```js
  ;(function (window, $) {
      var X = function () { /* ... */ };
      // X.prototype.method = function () { ... };
      window.X = X;
  })(window, jQuery);
  ```
- **保留看似 dead 的程式碼**：legacy JS 經常透過 `window.X` 隱式被 inline `<script>` 或 PHP 模板 callback；mechanical extraction 階段一律保留。
- **No build step**：leaf 由 `<script src>` 載入。不引入 import/export、TypeScript runtime、bundler 產物到 production load chain。靜態檢查契約見 [`.claude/rules/js/static-checks.md`](../../rules/js/static-checks.md)；新 leaf 的 `@ts-check` 節奏走 skill `zdpos-js-static-check-strategy`。

## 2. Audit-grep-first design

開新 OpenSpec change 規劃 extraction 時跑下列 audit。zpos Stage D 漏跑這步，才漏掉 `async function ajaxQuery` 與 `getSysTem(...)` boot 呼叫。

把 `<target.js>` 換成目標檔（`js/zpos.v2.js` / `js/pos_core.js` / `js/mpos.js` ...）：

```bash
# (a) Top-level declarations（含 async function、let、const、var、function）
rg -nE '^(async\s+)?(var|const|function|let)\s+\w+|^async\s+function\s+\w+' <target.js>

# (b) Top-level statements（非註解、非 declaration 的執行碼，常被漏抽）
awk '/^[a-zA-Z]/ && !/^\/\//' <target.js> | head -30

# (c) Nested const within objects/constructors（如 SelectionPackage 內含 PackageItem + Packages）
rg -nE '^\s+const\s+\w+\s*=\s*function' <target.js>

# (d) window.X 公開 API 命中數（抽出前 vs 抽出後必須相等）
rg -c 'window\.\w+\s*=' <target.js>

# (e) prototype 集中區塊 / closure private state
rg -nE 'prototype\.\w+\s*=' <target.js>
rg -nE '(^|\s)var\s+items\s*=|(^|\s)var\s+state\s*=' <target.js>

# (f) jQuery widget pattern（jqPlug 抽出時不可漏；widget 註冊本身就是 closure 公開 API）
rg -nE '\$\.widget\s*\(' <target.js>

# (g) IIFE / 既有模組邊界（未遵守本 skill 模板的會在拆出時暴露 'use strict' / arrow fn）
rg -nE ';\s*\(function\s*\(|use strict' <target.js>
```

完成條件：(a)–(g) 的輸出全部貼進 design.md，每一項都標了 leaf 歸屬。

## 3. Mechanical extraction 原則 + 800 LOC 例外條款

**原則**：純位移，零行為改動。不改寫變數命名、不重構函式、不刪看似 dead 的碼。理想 leaf 上限 800 LOC。

**例外條款**（單檔超過 800 LOC 為合法例外）：當抽出對象內含 closure 私有狀態（如 `var items = []`）或 prototype 集中區塊，切分必須改寫 closure 變數為 `this.X` → 違反「純位移」。為了維持零行為改動，整塊保留為單一 leaf。

PR description 三項齊備才算例外成立：

1. 明示「LOC 超過 800 但內含 closure private state / prototype 集中區塊」
2. 引用本條款（`zdpos-legacy-js-refactor` SKILL.md §3）
3. 附 grep 證據：closure 變數命中數 + `window.X` / `prototype.X` 公開方法命中數比對（原始檔 vs 新 leaf，必須完全相等）

zpos Stage C Item ~1,800 行、POS facade ~2,577 行、Stage D List ~14,724 行皆走此例外。具體成因 → `references/zpos-stage-a-d-case-study.md`。

## 4. Verification（leaf 切分後三段）

| 階段 | 動作 | 失敗訊號 |
|---|---|---|
| Golden fixtures 比對 | 鎖死 fixture（zpos 是 `protected/tests/fixtures/golden-cart-pre-refactor.json`）跑 leaf 與原始檔產出 JSON diff | 任何欄位不等 → 切分有行為改動 |
| Leaf 單元測試 | 直接呼叫 `window.X` 公開 API，斷言回傳值 / 狀態 | API 名稱反直覺（zpos.list 的 `setDiscount` / `setAllowance` / `removeItem` 等），grep 確認再寫 |
| E2E spec | 走 dispatch + rendering 雙斷言 | 偽綠：dialog 沒開但 `called=true` 仍 pass → 看 `references/e2e-antipatterns.md` |

完成條件：三段都跑過，golden diff 為空，E2E 沒有 probe-and-pass loop。

## 5. References

- 完整成功案例 → [references/zpos-stage-a-d-case-study.md](references/zpos-stage-a-d-case-study.md)
- E2E spec anti-patterns → [references/e2e-antipatterns.md](references/e2e-antipatterns.md)
- Worktree 跑 phpunit / E2E 前置 → skill `zdpos-git-worktree`
- per-leaf `@ts-check` → skill `zdpos-js-static-check-strategy`
