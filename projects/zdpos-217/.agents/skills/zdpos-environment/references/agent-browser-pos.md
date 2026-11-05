# agent-browser 操作 POS（DEV／本機瀏覽器測試）

> zdpos-environment skill 子檔。用 agent-browser 測 POS 前台或後台，或要派 QA／測試 subagent 時讀本檔。派工 prompt 不用重貼這裡的內容，寫一行「先讀 `zdpos-environment/references/agent-browser-pos.md`」即可。
> 完成條件：每個「操作沒反應」都已用下表排除過工具限制，才判 FAIL 或 BLOCKED。

## 指令

`<skill>` 指 `zdpos-environment` 的目錄。每個 agent-browser 指令都要單獨執行，不要用 `;` 或 `|` 串接（bash-guard 會擋，dhpk #1211）。

```bash
S=<session 名>
bash <skill>/scripts/pos-ab.sh $S login <vault-profile> https://www.zdpos.tw/dev 13      # 本機站台可加第 5 參數 kick
bash <skill>/scripts/pos-ab.sh $S iframe-click 第1廳                                     # 桌況 iframe 內的廳別分頁或桌位
bash <skill>/scripts/pos-ab.sh $S click 紅茶                                             # 商品格、功能鍵、數字鍵
bash <skill>/scripts/pos-ab.sh $S click 確定 last                                        # 對話框內的同名按鈕取最後一個
bash <skill>/scripts/pos-ab.sh $S dismiss                                                # 關掉 swal（按取消）與可見的 jQuery UI dialog
bash <skill>/scripts/pos-ab.sh $S logout https://www.zdpos.tw/dev
```

- 帳號：只用 vault profile，見 [`pos-login.md`](pos-login.md) Step 1。
- 在 DEV 或 UAT 遇到「機號重複」時停止並回報，**不要**加 `kick`，以免踢掉別人。
- 截圖存到 scratchpad，截完用 Read 看圖。等待用 `agent-browser --session $S wait <ms>`，不要用 bash `sleep`。

## 操作沒反應時先查這張表（工具限制 vs 產品缺陷）

| 現象 | 真正原因 | 做法 |
|---|---|---|
| `click @ref` 或座標點擊回 Done，但畫面沒變 | POS 的 jQuery handler 要完整的 mousedown、mouseup、click 序列 | `pos-ab.sh click` |
| 桌況的廳別分頁或桌位點了沒反應 | 桌況是 iframe（`tableSeats/index`），點擊事件進不了 iframe | `pos-ab.sh iframe-click` |
| 後台頂部選單展不開 | 純 CSS `:hover` 選單，agent-browser 的 hover 不會觸發 `:hover` | 直接開該頁網址，例如 `/dev/record/sales` |
| 後台搜尋視窗的「查詢」按了沒查 | 該按鈕同樣要 mouse 事件序列 | `pos-ab.sh click 查詢` |
| 報表店別多選後按查詢，跳「請選擇 地區 or 店別」 | multselect 要等清單收起，才會建立 `sStore[]` 隱藏欄位；清單一次只顯示 10 筆，其餘要捲動 | 點完店名，把滑鼠移出清單讓它收起，確認 `input[name="sStore[]"]` 有值後再查詢 |
| 補印或列印沒有開新分頁 | 列印頁載入後會自動 `window.print()` 再 `window.close()`；或補印前沒有輸入單號 | 先輸入單號；用 eval 攔截 `window.open` 記下網址，再讀那一頁 |
| 匯出沒有下載 | 匯出是 `window.open`，headless 抓不到 | 在頁面內用同一網址 `fetch` 下載後計算列數 |
| 獨立開 `tableSeats/index`，`POS` 未定義 | 該頁要透過 `pos/index` 的 iframe 才有 `POS` | 從 `pos/index` 進入 |
| Console 出現紅字 | 可能是既有雜訊，見 [`pos-operations.md`](pos-operations.md)「已知 Console 雜訊」；`errors` 緩衝區會包含先前頁面的錯誤 | 開測前先記一次 `--json errors` 當基準，判定時只算新增的 |

## 判 FAIL 前

1. 觸發動作留下了痕跡：送出請求、元素狀態改變、出現新的分頁或彈窗。
2. 前置狀態齊全：必填欄位已輸入、清單已收起、機號與帳號正確。
3. 觀察對象正確：例如失效鎖指的是 `data_table.lock`，不是「鎖桌」按鈕寫入的 `lock_table_id`。
4. 錯誤不在已知雜訊清單裡，而且不在基準之中。

四項都成立才判 FAIL；任一項不成立，就是工具或前置問題，判 BLOCKED，並寫明是哪一項。
