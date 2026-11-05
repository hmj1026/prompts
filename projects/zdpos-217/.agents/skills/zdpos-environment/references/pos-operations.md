# POS 前台操作：功能鍵查詢與桌位流程

> zdpos-environment skill 子檔。給使用者或 QA 寫 POS 操作步驟前讀本檔。
> 完成條件：寫出的每個按鈕名稱、所在分頁、按下後會看到什麼，都已用下方查詢與實際畫面對照過。

## 功能鍵：先查再寫

功能鍵依機號配置（`data_button.station_id`），同名按鈕在不同機號的位置不同，按鈕實際做什麼由 `data_action.action_method` 決定。

1. 由門市／機號取得 `station_id`：
   ```sql
   SELECT station_id, store_no, station_no, need_table
   FROM <schema>.data_station WHERE store_no = '113' AND station_no = '13';
   ```
2. 列出該機號的功能鍵與實際動作：
   ```sql
   SELECT b.page, b.`index`, b.name, b.arg, a.action_method, a.action_remark
   FROM <schema>.data_button b
   JOIN <schema>.data_action a ON a.action_id = b.action_id
   WHERE b.station_id = 120
   ORDER BY b.page, b.`index`;
   ```
3. 對照畫面：
   - `page` 的 `fn_p1`～`fn_p4` 依序對應功能鍵左下的「常用／資料／備份／系統」分頁。
   - 每頁 5 欄 × 4 列，`index` 由左到右、由上到下排列。
   - 截圖確認按鈕文字和位置後，才寫進步驟。
4. 寫步驟時用「分頁名稱＋按鈕名稱」（例如「系統」分頁的「收單」），不要寫「第 N 頁」。

同名按鈕依 `arg` 可能開不同視窗，見 memory `trap-same-function-key-opens-different-dialog-by-arg`。

## 桌位模式（`data_station.need_table = 1`）

| 目的 | 操作 | 畫面應該看到 |
|---|---|---|
| 開桌並存單 | 桌況點空桌 → 點商品（有「連動備註」就每組必選各選一個 → 確定）→ 按「收單」（action 12 `list.storeReciept`） | 跳「列印銷貨憑單 要列印價格嗎？」，測試時按取消；其他分頁的桌況顯示「開始」時間 |
| 載入暫存單（續單） | 桌況點已使用的桌 | 商品載回點餐畫面，`POS.isOld = true` |
| 清掉暫存單 | 先續單 → 按「作廢」（action 15 `list.delReciept`）→ 確認上方「銷售」單號 → 按大的「確定」 | 先顯示「確定作廢此單?」；確定後回到桌況，該桌變回空桌 |

- 大的「確定」鍵只確認輸入，**不會**把單存到桌上；存單一定按「收單」。
- DEV 測試機沒有列印程式：收單後會再跳「列印貼紙錯誤」，並另開一個 `pos/saleorder/...` 分頁，都與功能無關，關掉即可。
- 作廢後驗證：`sales_temp.sale_no`（欄名是 `sale_no`）與 `sales_temp_detail.sales_no` 都查不到該單號。單號已被取用，下一張會跳號，屬正常。

DEV 有桌位的機號（2026-11-03）：113-13、113-15（113 店 12 張桌）。

## 已知 Console 雜訊與既有提示（看到不用開單）

QA 手冊的 §6「已知狀況」直接指向本節，不要在各手冊重複列出。

| 現象 | 出處 | 說明 |
|---|---|---|
| `SyntaxError: Unexpected token '<' ... is not valid JSON` | `js/jqPlug/base.js:143` | 登入頁本身的錯誤。agent-browser 的 `errors` 緩衝區會把它帶到之後的頁面 |
| `TypeError: Cannot read properties of null (reading 'addEventListener')` | `js/modules.polyfill.js` | `pos/index` 載入時就有的既有錯誤 |
| `SweetAlert2: Unknown parameter "message"`（warning） | 收單流程 | 既有 |
| `ws error ... Stock Status: 1006`、「列印貼紙錯誤」 | 列印 WebSocket | 測試機沒有列印程式 |
| 「請關閉新分頁，避免造成資料錯誤！」 | `js/main.js:235` | 手動開新分頁時，sessionStorage 沒有 `session_flag` 就會跳出 |
| 「已無可用發票編號，請前往發票維護設定」 | `EI::isSettingOK` → `EI_check::canInvoice` | 該機號缺當期（雙月期）發票字軌。關掉提示，**不要**按「確定」（會跳到發票維護頁）；這個提示只影響開立發票，補印不受影響。登入時，過期期別的字軌會被標成 `used=3` |

## 本機環境前置

- 瀏覽器 QA 開始前，先跑 `scripts/migration-drift.sh list`。收單、作廢會寫入新欄位（例如 `social_payment_amount`）；對應的 migration 沒跑時，作廢會回 500，並在 `invalid_receipt` 留下沒有明細的表頭，之後重試就變成「重複單號」。
- 要補跑時，用 `migration-drift.sh apply <version>` 一次只跑一支。已經留下殘留表頭的話，先備份、刪除該表頭，再從畫面重新作廢。
