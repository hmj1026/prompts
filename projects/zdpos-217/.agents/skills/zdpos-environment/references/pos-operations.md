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
