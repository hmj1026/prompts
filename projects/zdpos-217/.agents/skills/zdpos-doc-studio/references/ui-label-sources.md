# 畫面字串來源對照（QA 手冊引號字串的查證處）

手冊裡每個 `「…」` 字串（選單、按鈕、欄位、提示）都要在下列來源找到。找不到就是臆測，改查或刪掉。`compile` 會用 `scripts/verify_labels.py` 列出找不到的字串。

| 要寫的字串 | 查證處 |
|---|---|
| 後台選單名稱與路徑 | DEV 庫 `zdn_menu`：`SELECT c.menu_id, c.name, p.name FROM zdpos_dev.zdn_menu c LEFT JOIN zdpos_dev.zdn_menu p ON p.menu_id=c.parent_id WHERE c.name LIKE '%關鍵字%'`。查到後寫進手冊同目錄 `.verified-labels.txt` |
| 後台列表欄位 | `RecordController` 等 `new Column('欄位', ['name'=>…])`。`notShow => true` 的欄位不在列表上，只能當搜尋條件 |
| 後台搜尋視窗 | `Column` 的 `forSearch`；`searhRelated`／`relateColumn` 成對時，被連動的條件預設隱藏，主條件選「是」才出現。工具列按鈕「搜尋」，視窗按鈕「清除」「查詢」（`Ztable.php`、`ztable.251215.js`） |
| 列表預設範圍 | `calldefaultSeacher`：以 `cdate` 等時間欄為預設時，剛開頁只列當日。帳號有店別限制時只列授權店別 |
| 整列變色 | `DataTable.php` 的 `fBlue`／`fRed` 條件 |
| POS 前台視窗按鈕與提示 | `protected/extensions/zpos/views/dialog.php`（取貨作業 `#dialogPickGoods`、取貨日期輸入 `#dialogPickupInput`）、`_PlaceAnOrder.php`、`_PlaceAnOrderList.php`；`z_alert`／`z_confirm` 的文字在呼叫處 |
| 功能鍵名稱 | `data_button`（每個商家可改名），以該商家 DB 為準 |
| 庫存異動原因 | `RecordController::actionInventory` 的 `$aRemark`，寫入處在 `PosController::changeInventoryBy*` |

## 位置與顏色
「右上角」「左下方」「紅字」這類版面描述，只有用瀏覽器看過才寫；沒看過就寫「視窗內」。

## 分支
手冊功能不在目前 checkout 時，`git show <分支>:<檔案>` 讀檔，`compile` 加 `--ref <分支>`。

## 搜尋
用 `git grep`。`rg` 遞迴搜尋會被 bash-guard 擋下。
