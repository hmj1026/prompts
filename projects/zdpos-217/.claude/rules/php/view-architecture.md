---
paths:
  - "protected/controllers/**/*.php"
  - "protected/views/**/*.php"
---

# View Architecture (zdpos-specific)

Controller action + View + asset 註冊的現代化範式。**範圍依 `php/coding-style.md` §Scope Rule**：新增 / 實質改寫的 action+view 才 MUST 遵循；未觸碰的 legacy view 維持原樣。

> Canonical reference（皆在 develop）：`MaintainController::actionStore()`（`protected/controllers/MaintainController.php`）+ `protected/views/maintain/store.php` + `protected/helpers/AssetHelper.php`（`application\helpers`）。

## Controller action

- **PHPDoc 必備**：一行用途 + `@return void` + `@throws`（至少 `CException`；用到 query toolkit 再加 `\Infrastructure\Database\Query\QueryException`）。
- **頁面設定在 controller**：`$this->setPageTitle(...)` 與 `$this->breadcrumbs = [...]` 放 action 內。**禁止**在 view 設 `$this->pageTitle = ...` / `$this->breadcrumbs = ...`。
- **權限優先**：`$this->checkPermission("...")` 置於 action 開頭（AJAX 分支判斷之前）。
- **資料以具名 `configs` 群組傳入**：`$this->render('store', ['model' => $model, 'configs' => [...]])`；相關旗標 / URL / 子設定收斂進 `configs`，不散落成 8+ 個扁平鍵。

## Asset 註冊（SSOT = AssetHelper）

所有 JS/CSS 一律透過 `AssetHelper` 在 **controller** 註冊。**禁止**在 view 內 inline `<script src>` / `<link rel="stylesheet">` / `<style>`，或散落 `Yii::app()->clientScript->registerScriptFile()` / `registerCssFile()`。

| 需求 | API |
|---|---|
| 頁面專屬資源（依 controllerID/actionID 推導路徑） | `AssetHelper::registerPageAsset($this, 'js'\|'css', $subDir = 'admin')` |
| 命名 bundle（CSS+JS 群組、可組合） | `AssetHelper::registerBundle('report-common')` |
| 單一 library 檔（自動推副檔名） | `AssetHelper::registerLibraryAsset($file, $ext = null, $subDir = null)` |
| 發布資源目錄取 URL（供 CSS 相對路徑） | `AssetHelper::publishAssetDirectory($dir)` |

新 bundle 在 `AssetHelper::$bundles` 宣告，不在 view 自行 register 一串檔。

## View

- **File-head PHPDoc**：`@var` 逐一宣告 controller 傳入變數（型別 + 用途），至少涵蓋本次新增 / 依賴的變數。
- **單一 PHP→JS 注入點**：`const configs = <?php echo CJavaScript::encode($configs); ?>;`（`CJavaScript::encode` 或 `CJSON::encode` 皆可，Yii 內建安全轉義），再 destructure。**禁止**散落多個 `<?php echo ?>` 於 script body，或 heredoc 內直接內插變數（XSS / 轉義風險）。
- **HTML body 不夾 PHP 流程控制**：見 `protected/views/CLAUDE.md` View hygiene baseline。
- **View 為 SQL 禁區**：見 `php/patterns.md` DB Query Layering item 2。

## Anti-pattern 對照（勿仿）

`protected/views/maintain/{class,items,invoice}.php`：view 內設 pageTitle、inline `<style>`、多個 `registerScriptFile`、view-local function 定義、heredoc 直接內插。

## Refs

- View hygiene（PHPDoc head、單一注入點、IIFE、idempotent guard）→ `protected/views/CLAUDE.md`
- 前端 AJAX wrapper SSOT / ES6-native → `.claude/rules/frontend.md`
- Magic value / enum 常數化 → `.claude/rules/php/coding-style.md` "Magic Values"
