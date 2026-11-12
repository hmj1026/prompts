# `qa` 模式指引：QA 手動測試驗收手冊 (`docs/qa/<module>/QA-<slug>-manual.*`)

`qa`（或 `both`）模式的撰寫規範。案例筆法見 [`qa-case-guidelines.md`](qa-case-guidelines.md)，範本見 [`qa-doc-template.md`](qa-doc-template.md)。

---

## 1. 產出與定位

- **受眾**：執行驗收的 QA 測試人員，不是開發者。
- **產出**：
  1. `docs/qa/<module>/QA-<slug>-manual.md`（SSOT）
  2. `docs/qa/<module>/QA-<slug>-manual.html`（`compile` 產生）
  3. 登錄 [`docs/qa/README.md`](../../../../../../zdpos-217/docs/qa/README.md) 的模組分流表。
- **實機核對狀態**：metadata 要有 `ui-verified`：`none`（依程式碼推測，`compile` 加紅色橫幅）、`source`（字串已對照原始碼與選單表）、`browser`（實機逐條看過）。填完附日期與環境。

---

## 2. 三條寫作鐵律（QA 讀得懂、不增加負擔）

### 2.1 名詞必須與實際畫面一致

- 手冊裡每個 `「…」`（選單、欄位、按鈕、視窗標題、提示）都要從 [`ui-label-sources.md`](ui-label-sources.md) 的來源查到才寫；`compile` 會跑 `verify_labels.py` 列出找不到的字串。
- 用**畫面上的字**，不用程式或資料表名稱。頁面用「選單路徑」或「頁面標題」稱呼（例如「紀錄查詢 → 交易明細查詢」），不寫 `record/saleslist`、商家代號或 action 名。
- 查不到選單路徑的頁面，只寫頁面標題並註明「只有部分商家有，沒有就 N/A」，不要猜路徑。
- 程式會動態拼出的字（例如「最多 N 天」），引號只引固定的前段，其餘用白話描述，避免 `verify_labels.py` 誤報或寫成畫面沒有的句子。
- 版面位置、顏色沒用瀏覽器看過就不寫（寫「視窗內」即可）。

### 2.2 不使用程式面術語

QA 看不懂的詞一律換成白話，不得出現在手冊正文：

| 避免 | 改寫 |
|---|---|
| placeholder | 欄位空白時的灰色提示字 |
| 前綴比對、萬用字元、regex | 輸入前 7 碼、輸入 8 個 `%` 字元（直接講操作） |
| DevTools／Console／Network | 除非案例就是要看，否則不提；必要時寫「按 F12 看有沒有紅字」 |
| EXPLAIN、索引、SQL、row、CAS、交易鎖 | 不寫（屬開發驗證，見 2.3） |
| action／route／controller／商家代號（如 oklao） | 畫面頁面標題 |
| 單號例外、守門、攔截、豁免 | 描述使用者看到的結果（「可以不填日期」「會被擋」） |

### 2.3 資訊只放「需要測試的範疇」

- 手冊只放 QA **會動手做或會看到**的內容：這次改了什麼、準備什麼、案例、簽核、開單格式、看到不用開單的現象。
- **不放**：資料庫、索引、API、測試檔名、ADR／OpenSpec 編號、程式類別名、實作位置表、自動化測試紀錄附錄、與測試無關的歷史背景。這些放協作者手冊。
- 「本文不測清單」**預設不寫**；只有 QA 可能誤以為該測、而且會浪費時間時，才用一兩行說明（例如「直接送請求繞過畫面」），不列檔名。
- 「最重要的事」最多 3 條；案例能合併就合併（同頁同流程的小檢查放同一個 TC）；一個 TC 不超過約 5 步。
- 不寫 Mermaid 以外的長篇原理說明；流程圖只在判定分支多於兩個時才放，且一張為限。

---

## 3. 黑箱邊界

- 步驟一律是「畫面看得見、點得到」的操作。**嚴禁**要求 QA 改設定檔、下 SQL 或檢查資料庫欄位。
- 需要特定資料時：由 §2「開始前準備」註明「由開發提供」，或寫出在畫面上建立的步驟。
- 底層正確性（結果相同、併發、索引）若 QA 只能以「前後金額／筆數相同」驗證，就寫成與基準比對的案例，並在適用條件註明需要事先記下的基準。

---

## 4. 章節（與範本一致）

「先記住這幾件事」→「怎麼讀」→「畫面上的名稱」→ §1 要測什麼 → §2 準備（含容易測錯）→ §3 案例（`### TC-xx`，★核心）→ §4 簽核 → §5 缺陷回報 → §6 看到不用開單。其餘章節不加。

---

## 5. QA 專屬命令

```bash
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py scaffold --mode qa --module <module> --slug <slug> --title "<功能中文名稱>"
python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py compile --mode qa docs/qa/<module>/QA-<slug>-manual.md
```

交付前自查：把手冊讀一遍，任何一個詞若 QA 無法在畫面上找到或看不懂，就改掉或刪掉。
