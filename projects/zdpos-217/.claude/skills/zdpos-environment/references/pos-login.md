# POS UI Login (playwright-cli)

> zdpos-environment skill 子檔。觸發：「用 playwright-cli 跑 dev4 / dev / cpos218 登入測試」「總店/分店帳號」。
> 只支援 local / DEV / UAT(cpos218)。PROD (CPOS217 / ZCPOS217) **嚴禁** 由 AI 自動登入。

## POS UI Login (playwright-cli)

### Step 0 — Playwright-cli bootstrap（**第一次使用** machine setup）

dev4 / dev / cpos218 皆為自簽憑證（或 dev-only CA），playwright-cli 預設拒絕並印 `Error: net::ERR_CERT_AUTHORITY_INVALID`。MUST 兩步 setup（皆 idempotent-safe，可重跑）：

```bash
# 1. 安裝 chromium（Homebrew playwright-cli 不會預先帶 browser binary）
#    先用 --list 跳過已裝；無 chromium 才跑安裝（每次重跑成本 ~115 MB download）
playwright-cli install-browser --list | grep -q chromium || playwright-cli install-browser chromium

# 2. 建立 .playwright/cli.config.json（已 gitignored；若已存在則 -n 跳過避免覆寫使用者自訂）
mkdir -p .playwright
[ -f .playwright/cli.config.json ] || cat > .playwright/cli.config.json << 'EOF'
{
  "browser": {
    "browserName": "chromium",
    "contextOptions": { "ignoreHTTPSErrors": true }
  }
}
EOF
```

> `npx playwright test`（committed E2E）走 `playwright.config.js` 內 `use.ignoreHTTPSErrors: true`，**不**需要 `.playwright/cli.config.json` — 兩條路徑各自管自己。`.playwright/` 已在 `.gitignore`。

### Step 1 — 取得帳號

帳號明文 **不** 寫在本 skill；改放未追蹤檔：

```bash
cat .claude/artifacts/accounts.md
```

| 檔案存在 | 動作 |
|----------|------|
| 存在 | 從表格抓對應 env / 角色（總店 = HQ / 分店 = Branch）的 account / password |
| 不存在或內容缺該 env | 用 `AskUserQuestion` 向使用者索取，並提示「請補進 `.claude/artifacts/accounts.md`（已 .gitignore）以利下次自動使用」 |

**`accounts.md` 範本格式**（user 第一次填寫時參考）：

```markdown
| env | account | password | role | note |
|---|---|---|---|---|
| local | 116 | 0000 | Branch | 機號數量有限；--workers=1 |
| local | 888 | 888 | HQ | adminMode；不選機號 |
| dev | <ask user> | <ask user> | Branch | DEV server |
| cpos218 | <ask user> | <ask user> | Branch | UAT |
```

`role=Branch` 走前台 `/pos/index`（含機號選取）；`role=HQ` 走 adminMode，**不能**進前台（見 Step 2.5）。

### Step 2 — 登入流程 snippet

```bash
# 依需求換成 dev4 (local) / dev (DEV server) / demo218 (UAT) 的 base URL
BASE="https://www.posdev.test/dev4"
# 下方 ACCOUNT/PASSWORD 必須先執行 Step 1 取得；切勿直接寫死樣板值
ACCOUNT="<from-step-1>"
PASSWORD="<from-step-1>"

playwright-cli open "$BASE/site/login"
playwright-cli snapshot                       # 取得 account / password / 登入 button 的 ref
# 依 snapshot 結果替換 e1 / e2 / e3（POS 登入頁固定欄位：textbox "帳號 *" / textbox "密碼 *" / button "Submit"）
playwright-cli fill e1 "$ACCOUNT"
playwright-cli fill e2 "$PASSWORD"

# 必要：POS 登入頁有 keyboardDiv 軟鍵盤覆蓋 Submit 按鈕，不 hide 會 click timeout（pointer events intercepted）
playwright-cli eval "() => { var k=document.getElementById('keyboardDiv'); if(k){k.style.display='none';return 'hidden';} return 'no-keyboard'; }"

playwright-cli click e3                       # Submit；URL 應由 /site/login → /dev4/
playwright-cli snapshot                       # 驗證登入：title 變「位置:mysql 資料庫:zdpos_dev_2」、出現「總管理處 admin (權限：1)」或「<分店名> <user> (權限：N)」
```

### Step 2.5 — pos/index 必須是分店帳號 + 機號（local Docker）

`pos/index` 要進前台需要「綁機號的分店身分」。實測陷阱：

| 帳號類型 | 登入後行為 | 是否能進 `/pos/index` |
|---------|-----------|----------------------|
| 總店 (HQ) `888/888` | 進得了 `/dev4/` 後台，但會被攔在「您尚未選擇機號，無法使用前台功能」 banner | ❌ 不行 |
| 分店 (Branch) `116/0000` + 選機號 | 進 `/pos/index`，`window.POS` / `window.ItemRemarkDialog` 可用 | ✅ 必須走這條 |

**站點 (LoginForm[station]) 選機號流程**：

1. 填 `#LoginForm_username` 與 `#LoginForm_password`（fill 後 `base.js:reLoadstation()` 動態補機號選項）
2. `#LoginForm_station` 預設被 `$('#LoginForm_station').hide()` 隱藏 → `selectOption()` 會卡 `element is not visible` → **改用 DOM API 設值並 dispatch `change` event**：
   ```js
   var sel = document.getElementById('LoginForm_station');
   for (var i = 0; i < sel.options.length; i++) {
     var v = sel.options[i].value;
     if (v !== '0' && v !== '') { sel.value = v; sel.dispatchEvent(new Event('change', { bubbles: true })); break; }
   }
   ```
3. 機號被前次 session 佔用 → 表單顯示「機號重複！」並停留在 `/site/login`。隱藏的 `<input name="RepeatAction">` 是覆寫 flag：JS 設 `RepeatAction.value = '1'` 後再次 click submit 即可強制接管。
4. playwright (committed E2E) 必須在 `try { waitForURL(... !/\/site\/login/) } catch { 偵測「機號重複」→ RepeatAction=1 → 再 submit }`，否則跨 test 串接時必爆。

> Committed E2E 參考：`js/tests/e2e/item-remark-dialog-tablet-scroll.spec.js` 的 `loginPos()` helper（4 viewport 共用一個 page，避免多 session 同站點互踩）。

> 登出 (`/site/logout`) 會觸發 `beforeunload` confirmation dialog → 後續任何 playwright-cli 指令會回 `Tool ... does not handle the modal state`。必須立刻 `dialog-accept`：
>
> ```bash
> playwright-cli goto "$BASE/site/logout"
> playwright-cli dialog-accept                # 必接，否則下一個指令會卡 modal state
> ```

### Step 3 — Base URL 對照

| Env | Base URL |
|-----|----------|
| local Docker (dev4 entry → zdpos-217 working tree) | `https://www.posdev.test/dev4/` |
| DEV server | `https://www.zdpos.tw/dev/` |
| UAT (cpos218) | `https://cpos.zdn.tw/demo218/` |
| dev4 (remote) | `https://www.zdpos.tw/dev4/` |

### 遠端 dev4 前台登入（remote variant，非 local Docker）

對象：遠端部署 `https://www.zdpos.tw/dev4/`（**非** local Docker）。同類陷阱「虛擬鍵盤 overlay」「機號重複 RepeatAction」的 local Docker 變體見上方 **Step 2 — 登入流程 snippet**（`keyboardDiv` hide + `click e3`）與 **Step 2.5 — pos/index 必須是分店帳號 + 機號（local Docker）**。差異：local 走 hide-keyboard + click；remote dev4 走 `run-code` JS-submit 直接繞 overlay。

- 測試帳號：帳號 `888` / 密碼 `888` / 機號 `01`（dev4 dev 測試帳號）。
- SSH：`ssh dev`；程式碼部署路徑 `/var/www/www.zdpos.tw/zdpos_develop`。

**表單欄位（form id = `login-form`）**

- `input[name="LoginForm[username]"]`、`input[name="LoginForm[password]"]`
- `select[name="LoginForm[station]"]`（機號下拉，值如 `01`）
- `input[name=RepeatAction]`（hidden，踢舊 session 用）
- submit：`input[name=yt0]`

**陷阱 1：虛擬鍵盤 overlay 攔截 submit**

focus 欄位後會浮出 `#keyboardDiv` / `.keyboardClassTd` 數字鍵盤，**蓋住 Submit 鈕** → `playwright-cli click` timeout（"intercepts pointer events"）；force-click 還會誤打鍵盤把值改掉（如帳號變 `8881`）。
**解法**：別用 click/fill 填值送出，改用 `run-code` 以 JS 直接設值 + 送出：

```js
async (page) => {
  await page.evaluate(() => {
    document.querySelector('input[name="LoginForm[username]"]').value = '888';
    document.querySelector('input[name="LoginForm[password]"]').value = '888';
    document.querySelector('select[name="LoginForm[station]"]').value = '01';
    var ra = document.querySelector('input[name=RepeatAction]'); if (ra) ra.value = '1';
    document.getElementById('login-form').submit();
  });
  await page.waitForLoadState('networkidle').catch(()=>{});
  return page.url();
}
```

成功後 URL → `/dev4/pos/index`、`typeof window.POS === 'object'`。

**陷阱 2：「機號重複！」**

submit 後機號欄顯示「機號重複！」= 該店+機號在 `data_session` 表已被佔用（server-side `Yii::app()->session->checkStation()`）。login.php 會在 3 秒後跳 confirm「是否清除機號登入？」。
**解法**：直接設 hidden `RepeatAction=1` 再送出 → 觸發 `own_kick` 刪掉舊 `data_session` row 重登（即上方 snippet 已含）。登入會佔用機號；用完登出或下次重登再踢即可。

**陷阱 3：playwright-cli run-code 語法**

`run-code` 參數是「接收 page 的函式」，不是裸 await：用 `async (page) => { await page.locator(...)... }`，不能寫 `await page.locator(...)`（會 SyntaxError）。

**常用診斷指令**

- `playwright-cli console error` — 列 console 錯誤
- `playwright-cli eval "() => ({ POS: typeof window.POS, Vue: typeof window.Vue })"` — 驗全域
- `playwright-cli eval "() => Array.from(document.querySelectorAll('script[src]')).map(s=>s.src)"` — 列載入的 script（驗資產來源）

### 注意事項

- `dhpk:ui-ux-verifier` agent 的 policy 是「user 先登入、agent 不碰憑證」（`.claude/agents/dhpk:ui-ux-verifier.md`）— 與本段不衝突，那是稽核獨立性。本段僅供 ad-hoc playwright-cli / e2e 驗證。
- artifacts 路徑已在 `.gitignore`（`artifacts/`）；切勿把它移出該資料夾。
- 失敗 3 次（snapshot 找不到欄位 / 登入後仍在 /site/login）→ 停止並回報，照 `execution-policy.md` Anti-Loop。
