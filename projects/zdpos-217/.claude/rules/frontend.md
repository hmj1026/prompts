# Frontend Rules

Legacy POS, **no build step**; direct DOM + `POS.*` global.

## Hard Limits

- New features **forbidden** to use `$.ajax` / `$.post` / `$.get` / `fetch` / `axios` — must use existing AJAX wrappers
- `POS` global is SSOT — no bypassing or parallel constructions
- Exception: core JS files (`zpos.js` / `mpos.js` / `pos_core.js` / `main.js`) define the wrappers and are exempt
- **Lint enforcement**：上列 hard limit 由 `npm run lint` (ESLint 9 flat config) 強制；config 結構 / tier 設計 / 自定 selector / 全域白名單 SSOT 詳見 [`.claude/rules/js/static-checks.md`](js/static-checks.md)

## Existing AJAX Wrappers

| Method | Object | Mode | Use case |
|--------|--------|------|----------|
| `ajaxPromise(name, data, fn)` | POS.list | Promise | New features (preferred) |
| `ajaxQuery(name, data, fn)` | POS.list | Callback | Legacy |
| `ajaxQuery(name, data, one_do, err)` | ItemPanel | Callback+Error | Item lookup |
| `postData(name, data, fn)` | POS | Callback | Baseline |
| `post(action, data, fn)` | POS | Callback | Broadly used |

## View-layer PHP → JS Data Passing

- **Centralize at top of script block**: single `const xxxConfig = <?php echo CJSON::encode([...]) ?>;` + destructuring
- **No scattered** `<?php echo ?>` inside script body
- Use `CJSON::encode()` (Yii built-in, safe escaping)
- PHP side: `isset($x) ? $x : null` to suppress notice

```js
const recordPageConfig = <?php echo CJSON::encode([
    'page'         => isset($page) ? $page : null,
    'searchConfig' => isset($searchConfig) ? $searchConfig : null,
]); ?>;
const { page, searchConfig } = recordPageConfig;
```

## E2E (Playwright) 執行慣例

> Trigger: 跑 `js/tests/e2e/*.spec.js` / `npx playwright test` / smoke spec / item-remark spec。

- **帳密一律從 env vars 讀**：`POS_ACCOUNT` + `POS_PASSWORD`（必填，spec 用 `test.skip(!POS_ACCOUNT || !POS_PASSWORD, ...)`），帳密不寫入 repo。local Docker 分店帳號從 gitignored `.claude/artifacts/accounts.md` 取得；總店帳號（HQ）會卡「未選機號」，必須用分店（Branch）帳號。
- **必用 `--workers=1`（已在 `playwright.config.js` 固定）**：POS 分店帳號機號數量有限，並行 worker 會被 server 視為機號重複佔用導致 timeout。
- **共用 login helper**：`js/tests/e2e/_helpers/login.js` 的 `loginPos(page, opts?)`；新 spec MUST `var { loginPos, BASE_URL } = require('./_helpers/login');`，禁止複製內嵌 `loginPos`。
- **pageerror 統計時機**：`page.on('pageerror', ...)` listener 應在 `loginPos(page)` 完成後才掛上，避免捕捉 login flow 裡 `js/jqPlug/base.js` 對 dev 環境 ajax 端點（回 HTML 404 而非 JSON）的 pre-existing SyntaxError。
- **跑法樣板**：
  ```bash
  POS_ACCOUNT=<分店帳號> POS_PASSWORD=<分店密碼> npx playwright test
  ```

## Progressive-loaded references

| 場景 | Skill / Reference |
|---|---|
| 規劃任何 legacy POS JS 抽出（zpos / pos_core / mpos / main / jqPlug）、改 `js/zpos/*.js` leaf | skill `zdpos-legacy-js-refactor` (共通契約、Mechanical extraction 例外、audit grep 範本、zpos Stage A-D 完成案例) |
| 寫 / review `js/tests/e2e/*.spec.js` | skill `zdpos-legacy-js-refactor` → references/e2e-antipatterns.md (probe-and-pass 禁則、行為-渲染雙斷言、條件斷言禁則) |
| Worktree 跑 E2E 前置 setup | skill `zdpos-git-worktree` (五件套 trap：yii_framework / config / runtime / node_modules / accounts) |

## Refs

- View-layer patterns (utils / idempotent guard / IIFE) → `protected/views/CLAUDE.md`
- Page Service → `docs/guides/page-service-pattern.md`
