# E2E 測試 anti-patterns（hard rule）

> 適用於任何 POS 公開 API（`POS.list.*` / `Paytype` / `Item` / `Item.ItemRemarkDialog` / dialog 系列；不限 zpos，未來 mpos / pos_core 抽出後的 leaf API 也適用）的 `*.spec.js` 寫作。
> 2026-05-16 verify-zpos-modular-refactor retrospective 抽出：自寫 14 spec 直接綠率 64%，code-reviewer 抓出 4 個 spec 內含 probe-and-pass anti-pattern。

## 1. spec 寫作前置：先 grep 真實 method 名稱（非協商項）

寫任何觸碰 `POS.list.X` / `POS.X` / leaf module method 的斷言前，先用以下指令確認真實簽名：

```bash
grep -nE "^\s*self\.\w+\s*=\s*function" js/zpos/list.js | grep -i <hint>
grep -nE "self\.\w+\s*=\s*function" js/zpos/pos.js
grep -nE "window\.\w+\s*=" js/zpos/<module>.js
```

直覺命名（`delItem` / `addDiscount` / `addAllow`）多半錯。常見正確命名對照 →
`[[memory:trap-zpos-list-public-api]]`（`setDiscount` / `setAllowance` / `setFocus+removeItem` / `addVoucher`）。

## 2. 禁用 probe-and-pass loop

```js
// ✗ Anti-pattern：method 改名靜默通過
var methods = ['setDiscount', 'addDiscount', 'setAccDiscount'];
for (var i = 0; i < methods.length; i++) {
    if (typeof list[methods[i]] === 'function') {
        list[methods[i]](0.1);
        return { method: methods[i] };
    }
}
return { method: null };
// ... expect(result).toBeDefined();  // ← 永遠 true
```

正解：grep 確認後**單一 method 名稱**直呼，並用 `hasMethod` 顯式斷言：

```js
// ✓ Correct
if (typeof list.setDiscount !== 'function') return { hasMethod: false };
try { list.setDiscount(0.1); return { hasMethod: true, error: null }; }
catch (e) { return { hasMethod: true, error: String(e && e.message || e) }; }
// ... expect(result.hasMethod).toBe(true);  expect(result.error).toBeNull();
```

## 3. 行為-渲染對齊：dispatch + rendering 雙斷言

走 `POS.list.X()` 真實 API 路徑取代 UI click 是 acceptable（dev3 商家 selectors 不穩定，
button onclick 委派最終都進這條 API），但**必須**補 DOM rendering 斷言：

| 動作類型 | dispatch 斷言（必）| rendering 斷言（必）|
|---------|------------------|-------------------|
| 開 dialog | `dialogState.called === true` | `$('#dialogX').dialog('isOpen') === true` |
| list 改動 | method 不丟例外 | `getItems().length` / `getListObj().list.X` 數值對比 before/after |
| voucher / allowance | API 不丟例外 | `getVoucher().length` 增加 / `list.allowance > 0` |

只測 dispatch 不測 rendering = F4 checkout-cash 在 R1 review 被標 HIGH 的偽綠來源（dialog 沒開但 `called=true` 仍 pass）。

## 4. 條件性斷言禁則

```js
// ✗ Anti-pattern：method 不存在或失敗時 spec 不 fail
if (deleted.applied) {
    expect(after.length).toBeLessThan(before);
}

// ✓ Correct：contract 破壞 = spec fail
expect(deleted.hasMethod).toBe(true);
expect(deleted.error).toBeNull();
expect(after.length).toBeLessThan(before);
```

同類禁則：
- `expect(x === a || x === b).toBe(true)` → 永遠 truthy
- `expect(result).toBeDefined()` 當 result 是 `{method: null}` → 永遠 pass
- `if (await btn.count() > 0) await btn.click()` 沒 fallback 斷言 → button 消失靜默通過

## 5. 「MUST click UI」OpenSpec 條款的等價路徑

OpenSpec 寫「MUST 點實際 UI 元件，MUST NOT 只 stub」時，下列等價組合可滿足驗證精神：

1. **加品這類 selector 穩定的入口** → 必用 UI click（`#item_list td`）
2. **流程性動作（折扣 / 折讓 / 取消 / voucher）**→ 走 `POS.list.X()`（onclick 委派目標）+ **必補 §3 rendering 斷言**
3. **負面驗證（F6 dialog-init regression 類）**→ cold-cart `page.evaluate(() => POS.list.openTotalPaymentDialog())` + 監聽 pageerror

純 evaluate 沒 DOM 斷言 = reduced verification value（reviewer 標）。

## 6. Worktree 跑 E2E 前置

進 worktree 寫/跑 spec 前先跑 setup script：

```bash
bash scripts/worktree-setup-e2e.sh
```

涵蓋 yii_framework / config / runtime / node_modules / accounts 五件套 → 詳細 trap 解析請載入 skill `zdpos-git-worktree`。
