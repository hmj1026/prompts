# agent-browser 操作 POS（本機／DEV／UAT 瀏覽器測試）

> zdpos-environment skill 子檔。用 agent-browser 測 POS 前台或後台，或要派 QA／測試 subagent 時讀本檔。派工 prompt 不用重貼這裡的內容，寫一行「先讀 `zdpos-environment/references/agent-browser-pos.md`」即可。
> 完成條件：每個「操作沒反應」都已用下表排除過工具限制，才判 FAIL 或 BLOCKED。

## 指令

`<skill>` 指 `zdpos-environment` 的目錄。每個 agent-browser 指令都要單獨執行，不要用 `;` 或 `|` 串接（bash-guard 會擋，dhpk #1211）。本節的 `click`、`iframe-click`、`dismiss` 用於本機與 DEV；UAT／vm1 登入後改走下一節的 `pos-guard.sh`，`login`、`logout` 兩處都用 `pos-ab.sh`。

```bash
S=<session 名>
bash <skill>/scripts/pos-ab.sh $S login <vault-profile> https://www.zdpos.tw/dev 13      # 本機站台可加第 5 參數 kick
bash <skill>/scripts/pos-ab.sh $S iframe-click 第1廳                                     # 桌況 iframe 內的廳別分頁或桌位
bash <skill>/scripts/pos-ab.sh $S click 紅茶                                             # 商品格、功能鍵、數字鍵（本機／DEV；UAT／vm1 改用 pos-guard.sh，見下節）
bash <skill>/scripts/pos-ab.sh $S click 確定 last                                        # 同名按鈕取最後一個；第 3 參數只接受 first 或 last，預設 first
bash <skill>/scripts/pos-ab.sh $S dismiss                                                # 關掉 swal（按取消）與可見的 jQuery UI dialog
bash <skill>/scripts/pos-ab.sh $S logout https://www.zdpos.tw/dev
```

- 帳號：只用 vault profile，見 [`pos-login.md`](pos-login.md) Step 1。
- 在 DEV 或 UAT 遇到「機號重複」時停止並回報，**不要**加 `kick`，以免踢掉別人。
- 截圖存到 scratchpad，截完用 Read 看圖。等待用 `agent-browser --session $S wait <ms>`，不要用 bash `sleep`。

## UAT／vm1 前台：一律經 pos-guard

vm1 的發票輸出路徑是正式上傳佇列，測試開出的發票會被上傳。攔截器在瀏覽器內過濾請求，只放行允許範圍內的動作。

分工：

| 階段 | 用哪支 | 原因 |
|---|---|---|
| `login`、`logout` | `pos-ab.sh` | 登入前與登出後沒有可裝攔截器的頁面 |
| 登入後的 `guard`、`click`、`iframe-click`、`dismiss`、`ack`、`void-ok` | `pos-guard.sh` | 每次操作前後確認攔截器已武裝 |

登入後不用 `pos-ab.sh` 的 click／iframe-click／dismiss，也不自寫 eval。

```bash
G=<skill>/scripts/pos-guard.sh
bash $G $S guard                                                  # 登入後先跑；印出 invoice_flag、目前單號、擋下的請求
bash $G $S click 不印發票                                          # 功能鍵、數字鍵、label、分頁都用 click
bash $G $S iframe-click 第1廳                                      # 桌況 iframe
POS_GUARD_APPROVED=<核准清單檔> bash $G $S void-ok 0200000004       # 作廢前登記一次核准；清單一行一號
POS_GUARD_ISOLATED=<核准清單檔> bash $G $S isolated-ok sb84         # 隔離站放行拆帳與開票；清單一行一站；頁面重載後重跑
```

1. **挑機號**：以 `SELECT station_no, invoice_track, invoice_current, remain FROM <schema>.invoice_maintain WHERE store_name='<店號>' AND year=<民國年> AND month=<雙月期>` 查字軌；程式比對的是 `store_name`，不是 `store_no`。查得到就代表結帳會開票。
2. **記基準**：`invoice_record` 筆數、各機號字軌號碼、`sales_receipt` 與 `invalid_receipt` 筆數。
3. **每張單**：按「不印發票」，跑 `guard` 確認 `invoice_flag` 是 `false` 再結帳。新單與續單載回都會恢復 `true`。
4. **隔離站（目前只有 `sb84`）**：發票寫隔離目錄且字軌為 OO 的站，主控核准後以 `isolated-ok` 登記，該站的 `splitBill*` 動作（不含 `splitBillWriteOff`）與 ajax `checkOut` 開票放行；作廢、折讓、`/pos/checkOut` 路由、發票類頁面仍照原規則。`guard` 輸出的 `isolated` 顯示目前登記；頁面重載後為空，須重跑。新增隔離站要先讀回該站 `INVOICE_BASE_PATH` 與字軌，再改 `pos-guard.js` 的 `ISOLATED_SITES` 並跑測試。
5. **作廢**：先停下回報單號；主控核對 DB（是自己建的、沒有發票）後才寫入核准清單。核准以單號登記，只涵蓋一般作廢，送出一次即消耗；同單號再作廢須重新核准。「作廢單號」鍵要輸入完整 10 碼單號。
5. **擋下時**（exit 10）：停止並回報擋下紀錄（開頭是 action 或路徑名稱），之後的點擊會持續 exit 10。主控判斷後以 `ack` 清除紀錄（被擋的請求從未送出）；要放行新動作時，先讀該 case 確認不開票、不寫佇列，再加入 `pos-guard.js` 的允許清單並跑 `node --test <skill>/scripts/pos-guard.test.js`。
6. **收尾**：與基準比對，發票筆數與字軌不變，再登出釋放機號。

### 放行與擋下

- 放行：允許清單內的 doAjax 動作、`get*` 前綴、GET 頁面載入（含 `saleorderCheckout` 銷貨憑單，只渲染）、`site/login`、付款清單等明列路由，以及掃碼收單輪詢 `tableSeats/scanOrderProcess`（會更新暫存單與列印旗標，不開票）。
- 擋下：不在清單內的 ajax 動作；沒有 ajax 參數的非 GET 請求（預設擋）；`/pos/checkOut` 路由（伺服端 `invoice_flag` 寫死 `true`、`del_flag` 預設為作廢）；ajax `checkOut` 的 `invoice_flag` 不是 `false`；未核准的 `delReceipt`、`delOrder`；`window.open` 與表單送出到路徑含 `invoice`、`allowance`、`eiic` 的頁面。
- 擋下（未查證或會寫入，需要時由主控讀 case 後再放行）：換桌 `chgTable`、清桌 `clearTable`、`updateSelling`、`openCasher`、功能鍵密碼、`lookupTaxTitle`、掃碼開桌 `tableSeats/openTable`、貼紙 `sticker/*`。`CreditCard/*` 會動到實體刷卡機，維持擋下。
- 折讓事件（`MakeAllowances`、`VoidedAllowances`）與任何未知 `event` 一律擋，即使單號已核准；UAT 開折讓須另取使用者核准，不在本工具範圍。
- 作廢路由的判斷涵蓋 GET、`?r=`、Yii path 參數（`/pos/delReceipt/salno/<單號>`）、大小寫、尾斜線、完整 URL。
- `get*` 前綴放行但不保證純讀：`getSalesTemp` 會清桌並寫 `data_table`，`getSaleNo` 會清 `sales_temp` 的鎖欄；兩者不涉及發票與作廢。其餘 `get*` 未逐一查證。

### 流程約束

核准清單檔由主控提供，代理不得自行建立或改寫；`ack`、`void-ok`、`isolated-ok` 只在主控指示後執行。同一系統使用者可直接改檔或呼叫 `ack`，程式無法強制這條規範。

### 已知限制

- 攔截器涵蓋目前頁面與同源 iframe 內的 XHR、fetch、sendBeacon、window.open、表單送出。fetch 的 Request 物件會複製後讀 body；Blob、串流等讀不到內容的寫入請求一律擋。
- `window.open` 開出的新視窗、整頁導覽（連結、`location` 指派）、重載後到下一次 `pos-guard.sh` 之間的空窗不在保護內；載入後先跑 `guard`。
- 登入後到第一次 `guard` 之間沒有保護。
- 跨源 iframe 讀不到，`guard` 輸出的 `crossOriginFrames` 不為 0 時回報。
- 同一核准清單行可重複 `void-ok`（每次登記一次使用），靠流程約束。


## 操作沒反應時先查這張表（工具限制 vs 產品缺陷）

| 現象 | 真正原因 | 做法 |
|---|---|---|
| `click @ref` 或座標點擊回 Done，但畫面沒變 | POS 的 jQuery handler 要完整的 mousedown、mouseup、click 序列 | 本機／DEV 用 `pos-ab.sh click`；UAT／vm1 用 `pos-guard.sh click` |
| 桌況的廳別分頁或桌位點了沒反應 | 桌況是 iframe（`tableSeats/index`），點擊事件進不了 iframe | 本機／DEV 用 `pos-ab.sh iframe-click`；UAT／vm1 用 `pos-guard.sh iframe-click` |
| 後台頂部選單展不開 | 純 CSS `:hover` 選單，agent-browser 的 hover 不會觸發 `:hover` | 直接開該頁網址，例如 `/dev/record/sales` |
| 後台搜尋視窗的「查詢」按了沒查 | 該按鈕同樣要 mouse 事件序列 | `click 查詢`（腳本分工同上） |
| 報表店別多選後按查詢，跳「請選擇 地區 or 店別」 | multselect 要等清單收起，才會建立 `sStore[]` 隱藏欄位；清單一次只顯示 10 筆，其餘要捲動 | 點完店名，把滑鼠移出清單讓它收起，確認 `input[name="sStore[]"]` 有值後再查詢 |
| 補印或列印沒有開新分頁 | 列印頁載入後會自動 `window.print()` 再 `window.close()`；或補印前沒有輸入單號 | 先輸入單號；用 eval 攔截 `window.open` 記下網址，再讀那一頁 |
| UAT／正式站 `/record/*` 回 403 | nginx 對 HeadlessChrome 的刻意規則，不是權限或產品缺陷 | 記 BLOCKED 並回報；使用者同意後，每個指令前加 `AGENT_BROWSER_HEADED=1` 開真實瀏覽器（需要 `DISPLAY`），維持原本的 User-Agent |
| 匯出沒有下載 | 匯出是 `window.open`，headless 抓不到 | 在頁面內用同一網址 `fetch` 下載後計算列數 |
| 獨立開 `tableSeats/index`，`POS` 未定義 | 該頁要透過 `pos/index` 的 iframe 才有 `POS` | 從 `pos/index` 進入 |
| Console 出現紅字 | 可能是既有雜訊，見 [`pos-operations.md`](pos-operations.md)「已知 Console 雜訊」；`errors` 緩衝區會包含先前頁面的錯誤 | 開測前先記一次 `--json errors` 當基準，判定時只算新增的 |

## 判 FAIL 前

1. 觸發動作留下了痕跡：送出請求、元素狀態改變、出現新的分頁或彈窗。
2. 前置狀態齊全：必填欄位已輸入、清單已收起、機號與帳號正確。
3. 觀察對象正確：例如失效鎖指的是 `data_table.lock`，不是「鎖桌」按鈕寫入的 `lock_table_id`。
4. 錯誤不在已知雜訊清單裡，而且不在基準之中。

四項都成立才判 FAIL；任一項不成立，就是工具或前置問題，判 BLOCKED，並寫明是哪一項。
