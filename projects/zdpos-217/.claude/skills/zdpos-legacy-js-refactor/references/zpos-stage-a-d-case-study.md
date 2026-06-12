# Case Study: zpos.js Stage A/B/C/D Modular Refactor (completed 2026-05-15)

> 本檔為 2026-05-15 完成的 zpos.js 拆分完整案例，供未來其他 legacy JS extraction 參考具體執行細節與數字。**通用方法論已升級至 SKILL.md §2-5，不在此重複**；本檔只留 zpos 專屬細節。

## 規模數字

- 原始檔：`js/zpos.js` **26,904 行 legacy fallback**
- 拆分結果：抽出至 `js/zpos/` 共 **37 個 leaf modules**
- Orchestrator：`js/zpos.v2.js` 收斂為 **146 行 boot script**

## 鎖死檔案 SSOT 對照

| 檔案 | 為何鎖死 |
|---|---|
| `js/zpos.js` | md5 永遠等於 develop；fallback 用 |
| `protected/views/layouts/pos.php` | 自 Stage A 收尾後僅含 partial `require` |
| `protected/tests/fixtures/golden-cart-pre-refactor.json` | Stage A PR0 凍結，4 階段全程重用做 fixture diff |

## Partial SSOT 實體

- `protected/views/layouts/_pos_modular_assets.php` 內 `$modularScripts` 陣列為唯一載入順序來源
- `js/zpos/pos.js` facade 為陣列最後一個 leaf URL

## 800 LOC 例外條款命中

| Leaf | 行數 | 例外原因 |
|---|---|---|
| Stage C Item | ~1,800 | closure private state + prototype 集中 |
| Stage C POS facade | ~2,577 | 多 prototype + ~30 公開方法集中 |
| Stage D List | ~14,724 | 主要 closure private state（cart items、selection state） |

## Stage 拆分粒度

| Stage | 主要拆出 | OpenSpec archive 路徑 |
|---|---|---|
| A | View layout 改 partial + facade 起步 | `openspec/changes/archive/2026-05-14-refactor-zpos-js-stage-a-*/` |
| B | paytype / voucher / allowance | `openspec/changes/archive/2026-05-14-refactor-zpos-js-stage-b-*/` |
| C | Item / POS facade（命中 800 LOC 例外） | `openspec/changes/archive/2026-05-14-refactor-zpos-js-stage-c-*/` |
| D | List（最大例外，主要 closure state） | `openspec/changes/archive/2026-05-14-refactor-zpos-js-stage-d-*/` |

## Stage D 規劃漏抽教訓（→ 升級為 SKILL.md §3 audit-grep）

Stage D design.md 漏抽 `async function ajaxQuery` 與 `getSysTem(...)` boot 呼叫，原因是只用 (a) 抓 `var|const|function` 而沒涵蓋 (a') `async function`，也沒跑 (b) top-level statements。事後補救成本大。

正因此教訓，SKILL.md §3 的 grep 範本擴成 (a)-(e) 共 5 條，覆蓋：
- async function（漏抽元兇）
- 非 declaration 的 top-level 執行碼（getSysTem 漏抽元兇）
- nested const within objects（避免類似 SelectionPackage 內含 PackageItem + Packages 結構被漏掉）
- window.X 命中數比對（驗證用）
- prototype / closure private state 偵測（800 LOC 例外觸發判斷）
