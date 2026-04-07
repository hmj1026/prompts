# Frontend Rules

## Hard Limits

- 新功能程式碼禁止直接使用原生 HTTP API（`$.ajax`、`$.post`、`$.get`、`fetch`、`axios`）
- 應優先使用專案既有 AJAX 封裝（見下表），避免重造輪子
- 全域 `POS` 物件為單一真相來源（SSOT）—— 禁止繞過或平行建立替代物件
- 核心 JS 檔案（zpos.js, mpos.js, pos_core.js, main.js）是封裝定義處，不受此限

### 既有 AJAX 封裝

| 方法 | 物件 | 模式 | 適用場景 |
|------|------|------|---------|
| `ajaxPromise(name, data, fn)` | POS.list | Promise | 新功能首選 |
| `ajaxQuery(name, data, fn)` | POS.list | Callback | Legacy 相容 |
| `ajaxQuery(name, data, one_do, err)` | ItemPanel | Callback+Error | 商品查詢 |
| `postData(name, data, fn)` | POS | Callback | 基礎封裝 |
| `post(action, data, fn)` | POS | Callback | 廣泛使用 |

## Stack

- Legacy POS（Raw ES6, no build step）
- 無 npm/webpack/babel；直接操作 DOM 與 `POS.*` API

## View-layer JS 資料傳遞（PHP → JS）

PHP 變數注入 JS 時遵循以下模式：

```js
// 1. 頂部集中注入：用 CJSON::encode() 序列化，一次宣告
const recordPageConfig = <?php echo CJSON::encode([
    'page'         => isset($page) ? $page : null,
    'searchConfig' => isset($searchConfig) ? $searchConfig : null,
]); ?>;

// 2. 緊接解構賦值，減少後續 recordPageConfig.xxx 重複存取
const { page, searchConfig } = recordPageConfig;
```

規則：
- **集中一處**：所有 PHP→JS 資料傳遞置於 script 區塊頂部的單一 `const pageConfig = CJSON::encode(...)` 宣告
- **禁止散落 echo**：不在 script 區塊內多處使用 `<?php echo ?>`
- **用 `CJSON::encode()`**（Yii 內建，安全跳脫）而非手動拼接 JSON 字串
- **PHP 側防 notice**：變數可能不存在時用 `isset($x) ? $x : null`

## Related

- View-layer patterns（utils、冪等 guard、IIFE）→ `protected/views/CLAUDE.md`
- Page Service 開發指南 → `docs/page-service-pattern.md`
