---
name: zdpos-legacy-js-refactor
description: zdpos legacy POS JS 巨檔抽出 / leaf module 拆解的共通契約 — 原始檔鎖死、IIFE + `window.X` re-export 模板（不改 ES6 class）、audit-grep-first design.md、Mechanical extraction 800 LOC closure 例外、leaf 切分後三段驗證 (golden fixture / 單元 / E2E)。Use when 規劃把 js/zpos · pos_core · mpos · main · jqPlug 等巨檔拆成 leaf、寫 extraction 的 design.md 邊界清單、code-reviewer 把關 leaf 切分品質。Not for：對已抽好的 leaf 加 `// @ts-check` 或量進度（→ skill `zdpos-js-static-check-strategy`）、改 eslint / tsconfig 設定或 tier 歸屬（→ skill `zdpos-js-lint-config`）、一般 frontend / leaf 內部業務邏輯編輯（→ `.claude/rules/frontend.md`）。
allowed-tools: Read, Bash(rg *), Bash(grep *), Bash(awk *), Bash(find *), Bash(wc *), Bash(ls *), Bash(git *)
---

# zdpos Legacy JS Refactor Playbook

> 觸發：規劃任何 zdpos legacy POS JS 模組抽出（zpos / pos_core / mpos / main / jqPlug）、寫 design.md audit grep、closure / prototype 例外處理、leaf 切分後三段驗證。

## 1. 適用情境

| 訊號 | Skill 適用嗎 |
|---|---|
| 「我要拆 `js/<big-file>.js`」「規劃下一個 leaf module」 | ✓ 強相關 |
| 「OpenSpec change 的 design.md 怎麼寫」 + 對象是 JS 重構 | ✓ 強相關 |
| 「leaf module 內含 closure private state，能不能改 this.X？」 | ✓ §4 例外條款 |
| 「寫新 `*.spec.js` 測 leaf API」 | ✓ → `references/e2e-antipatterns.md` |
| 「想看 zpos 是怎麼拆完的」 | ✓ → `references/zpos-stage-a-d-case-study.md` |
| 純改 leaf module 內部 1-2 行 bug | ✗ 不需要 |
| 改 view-layer PHP 或 AJAX wrapper | ✗ 用 `.claude/rules/frontend.md` |

## 2. 共通契約（任何 zdpos legacy JS extraction MUST 遵守）

> 這 5 條從 zpos.js Stage A-D（2026-05-15 完成）成功經驗萃取，是純位移、零行為改動策略的支柱。任何新一輪抽出（pos_core / mpos / jqPlug...）都直接套用，不需要再爭論。

- **原始檔鎖死**：原始巨檔 md5 永遠等於 develop 版本；任何 PR MUST 不修改該檔。原始檔作為 fallback「未拆版本」常駐，上線後若 leaf 出包可以一行 partial 切回原始檔。
- **Partial SSOT**：載入順序集中在唯一 PHP partial（e.g. `protected/views/layouts/_pos_modular_assets.php` 之於 zpos），陣列就是 SSOT；facade 檔（e.g. `pos.js`）MUST 為陣列最後一個 leaf URL 確保所有 leaf 已就緒。**對 mpos / pos_core / jqPlug 等其他 module 抽出**：先確認對應的 `_<module>_modular_assets.php` 是否已存在；不存在就在抽出 PR0 先建一個 SSOT partial，避免在抽出過程中還要回頭改 view layout 影響 diff 純淨度。
- **IIFE + window.X re-export 模板**：所有 leaf module MUST 採以下骨架，禁止改寫為 ES6 class / arrow function / 加 `'use strict';`：
  ```js
  ;(function (window, $) {
      var X = function () { /* ... */ };
      // X.prototype.method = function () { ... };
      window.X = X;
  })(window, jQuery);
  ```
- **禁刪看似 dead 的程式碼**：legacy JS 經常透過 `window.X` 隱式被 inline `<script>` 或 PHP 模板 callback；單純 grep 不會抓到所有 caller。Mechanical extraction 階段一律保留，等專案有獨立的 dead-code audit 再說。
- **No build step**：專案無 webpack / babel / npm script；leaf module 直接由 `<script src>` 載入。禁止引入 import/export、TypeScript runtime、bundler 產物到 production load chain。
  - 2026-05-21 補充：靜態檢查（ESLint + `// @ts-check` + TS noEmit）已落地為機器化契約 — 詳見 [`.claude/rules/js/static-checks.md`](../../rules/js/static-checks.md)。本 skill 的 mechanical 契約**不變**；新增 leaf 抽出時 SSOT lint config 與 tier 結構照走，per-leaf PR 漸進加 `// @ts-check`（卡住的 leaf 可用 `// @ts-nocheck` + TODO 暫遞延）。
  - 大方向：新功能以 IIFE leaf + `<script src>` 載入；不採 hybrid bundle / ESM 共存。未來時機成熟可考慮獨立 OpenSpec change 一次性把全部 leaf 重構為 ESM 並走單一 bundle。

## 3. Audit-grep-first design（design.md 必跑）

開新 OpenSpec change 規劃 extraction 時，design.md MUST 跑下列 audit 列出完整邊界清單。zpos Stage D 規劃時就是漏跑這步，才漏掉 `async function ajaxQuery` 與 `getSysTem(...)` boot 呼叫，事後補救成本大。

把 `<target.js>` 換成你的目標檔案（`js/zpos.v2.js` / `js/pos_core.js` / `js/mpos.js` ...）：

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

# (g) IIFE / 既有模組邊界（確認原檔已遵守本 skill 模板，未遵守的會在拆出時暴露 'use strict' / arrow fn 等）
rg -nE ';\s*\(function\s*\(|use strict' <target.js>
```

把 (a)-(e) 的結果直接貼進 design.md 作為「邊界清單」，逐項對應 leaf 歸屬。

## 4. Mechanical extraction 原則 + 800 LOC 例外條款

**原則**：純位移，零行為改動。不改寫變數命名、不重構函式、不刪看似 dead 的碼。理想 leaf 上限 800 LOC。

**例外條款**（單檔超過 800 LOC 為合法例外）：當抽出對象內含 closure 私有狀態（如 `var items = []`）或 prototype 集中區塊，**切分必須改寫 closure 變數為 `this.X`** → 違反「純位移」原則。為了維持零行為改動，整塊保留為單一 leaf 是更安全的選擇。

例外條件（PR description MUST 三項齊備）：
1. 明示「LOC 超過 800 但內含 closure private state / prototype 集中區塊」
2. 引用本條款（`zdpos-legacy-js-refactor` SKILL.md §4）
3. 附 grep 證據：closure 變數命中數 + `window.X` / `prototype.X` 公開方法命中數比對（原始檔 vs 新 leaf，**必須完全相等**）

zpos Stage C Item ~1,800 行、POS facade ~2,577 行、Stage D List ~14,724 行皆走此例外。具體成因 → `references/zpos-stage-a-d-case-study.md`。

## 5. Verification（leaf 切分後三段）

| 階段 | 動作 | 失敗訊號 |
|---|---|---|
| Golden fixtures 比對 | 鎖死 fixture（zpos 是 `protected/tests/fixtures/golden-cart-pre-refactor.json`）跑 leaf 與原始檔產出 JSON diff | 任何欄位不等 → 切分有行為改動 |
| Leaf 單元測試 | 直接呼叫 `window.X` 公開 API，斷言回傳值 / 狀態 | API 名稱反直覺（zpos.list 的 `setDiscount` / `setAllowance` / `removeItem` 等），grep 確認再寫 |
| E2E spec | 走 dispatch + rendering 雙斷言（禁 probe-and-pass loop） | 偽綠：dialog 沒開但 `called=true` 仍 pass → 看 `references/e2e-antipatterns.md` §3 |

## 6. References

- 完整成功案例（具體數字、Stage A-D archive 路徑）→ [references/zpos-stage-a-d-case-study.md](references/zpos-stage-a-d-case-study.md)
- E2E spec anti-patterns（probe-and-pass 禁則、行為-渲染對齊、條件斷言禁則、MUST click UI 等價路徑）→ [references/e2e-antipatterns.md](references/e2e-antipatterns.md)
- Worktree 跑 phpunit / E2E 前置 → skill `zdpos-git-worktree`
- modular zpos 重新上線契約（kill-switch、jQuery 1.9.1 lock、dialog 相容防線；38 leaf + `zpos.v2.js` orchestrator）→ active OpenSpec change `openspec/changes/relaunch-modular-zpos`
