---
name: zdpos-anchor-review
description: anchor 審查：feature 分支合併前的四模組（anchor、doc、style、refactor）盤點、批次修正與驗證。Use when 盤點或補齊分支 anchor（含貼上「日期 作者 [主題]」字串）、整理分支 phpDoc／jsDoc、或執行合併前 coding style 與命名合規修正。Not for 功能實作、bug 修正，或一般邏輯 code review。
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(git *), Bash(rg *), Bash(grep *), Bash(cx *), Bash(php -l *), Bash(docker exec *)
---

# Anchor Review（分支合規盤點）

feature 分支合併前單一站點完成 `anchor`、`doc`、`style`、`refactor` 盤點、使用者確認後批次修正與驗證。§4 規則完整自包含於 [`references/coding-style-rules.md`](references/coding-style-rules.md)，判定不依賴目標分支是否存在 `CODING_STANDARDS.md` 等規範檔（僅查閱細節時參考）。全程以正體中文回覆；程式註釋寫正體中文，技術術語保留 English。

## 執行流程（兩階段強制）

### Step 0：前置確認（參數與模組）

1. **取得本次分支 anchor**（全字串比對，格式為日期＋作者＋`[主題]`＋描述）：
   - 優先採用技能參數傳入值。
   - 參數為空時，先讀本分支 OpenSpec change 的 `tasks.md` 開頭 `> Anchor：` 行，提出供使用者確認；無此行時停下來請使用者提供，以明確回覆為準（不自行臆測）。
2. **確認比對基準**：預設 `origin/master`，可用 `BASE` 參數覆寫。新物件定義為基準分支不存在、本分支以 `diff-filter=A` 新增的檔案。
3. **確認執行模組**：先請使用者勾選本次要跑的模組（`anchor`、`doc`、`style`、`refactor`，預設全選，可只選子集如僅 `anchor` 或僅語法檢測）。僅盤點並修正選定模組，未選模組維持原狀。

- **完成條件**：已取得使用者確認的完整 anchor 字串、比對基準（預設 `origin/master` 或 `BASE`）與本次選定模組清單。

### Phase A：盤點（唯讀，不改碼）

1. **執行掃描腳本**（勾選 `anchor` 或 `doc` 時先跑，清單完整寫檔）：
   ```bash
   python3 <本技能目錄>/scripts/anchor_scan.py --anchor '<anchor>' --out .scratch/anchor-review-<日期>
   ```
   - `--base` 可覆寫基準；工作樹含未提交 WIP 且帶子題 anchor 時加 `--wip-anchor '<子題 anchor>'`（以 `HEAD` 為基準檢查 WIP，結果寫入 `anchor_wip.tsv`，此模式分支主 anchor 不算其他功能）。
   - 腳本已內建排除與範圍處理：純 docblock／註解／括號 hunk、`develop` 帶入 hunk、帶其他功能 anchor 的 hunk、同檔多個 helper class 各算一次、namespace／script 層獨立函式、字串 fixture、`git mv` 搬移檔以舊路徑比對基準、未追蹤目錄內新檔逐檔納入 scope。
   - 腳本輸出檔與處置：
     - `anchor_mod.tsv`：標「（新方法缺 anchor）」者為基準無且方法範圍與 docblock 上方 3 行皆無 anchor 的新方法（不受 diff 位移影響）。
     - `anchor_dup.tsv`：修改檔同一方法帶本次 anchor 超過一次（§2.3）；保留第一個，其餘去掉 anchor 前綴並保留說明文字。
     - `anchor_foreign.tsv`：新增註解中同作者、文字不同的 anchor；開發期佔位 anchor 換成正式 anchor，刻意獨立的 anchor（如測試基建）於盤點表註明後保留。
     - `anchor_wip.tsv`：`--wip-anchor` 模式之 WIP 檢查結果。
     - 逐行掃描輸出（新檔全部行、修改檔 diff 新增行，含測試檔）：`doc_jargon.tsv`（流程代號）、`doc_terms.tsv`（英文術語與建議中文，來源 `CONTEXT.md` 實作術語對照）、`style_vars.tsv`（變數命名，§4 第 5 條，啟發式）、`style_tests.tsv`（測試名非三段式，§4 第 16 條）。`style` 類以此兩份為起點，人工補查啟發式抓不到的參數與條件式賦值。
2. **完整覆核**：讀腳本輸出一律完整讀取整檔（不用 `head` 或截斷取樣）；逐筆確認結果，誤判於盤點表註明理由後剔除，腳本盲區人工補列。
3. **執行 style 補充盤點**（勾選 `style` 時）：載入 [`references/coding-style-rules.md`](references/coding-style-rules.md)，並依 §1 執行 view 三項偵測（差異含 `protected/views/**` 時）與新增方法命名檢查（§4 第 11、13、20 條與 §4.2）。
4. **輸出盤點表並暫停待確認**：每列含檔案與行號、類型、現況、預計調整＋內容範例；改名類另列呼叫端數量、涉及檔案與其他未合併分支的呼叫情形。結尾請使用者審核後停下等待，待明確確認再進 Phase B。

- **完成條件**：選定模組均已覆核且腳本輸出整檔讀畢；盤點表筆數＋剔除筆數＝`summary.txt` 各類筆數；工作樹零改動；已向使用者提出盤點表並等待確認。

### Phase B：修正與驗證（使用者明確確認後）

1. **一次套用全部核准項目**：含改名的所有呼叫端與測試；anchor 行原樣插入並保留既有 anchor 不變；新方法預設放檔案最下端（同領域可依 §4 第 10 條就近內聚），遵守 PHP 5.6 語法。
2. **五關驗證**（任一失敗即修正後重跑，全數通過才收尾）：
   1. **PHP 語法檢查**：每個變更 PHP 檔跑 `php -l`（host 的 `php` 為 5.6.40，只證明 5.6）。檢查 8.4 前先跑 `docker image inspect zdpos-php84-test:local`；映像存在時在 8.4 容器確認 `php -v` 印出 8.4 後執行：
      ```bash
      docker run --rm -i -v /home/paul/projects:/home/paul/projects -w "$PWD" zdpos-php84-test:local \
        sh -c 'while read f; do php -l "$f" | grep -v "^No syntax"; done' < 檔案清單
      ```
      （檔案清單須位於掛載目錄內或經 stdin 傳入。）映像不存在時，8.4 lint 與測試一律回報 `NOT_RUN（本機無 8.4 映像）`（建置來源不在任何 repo，2026-11-10 確認 `~/.local/state/zdpos-php84/` 下 Dockerfile 已不在，重建須另案）。
   2. **重跑掃描腳本**：核准修正項目全數消失，剩餘筆數僅為盤點表標記保留或剔除的項目。
   3. **View 偵測歸零**：差異含 view 變更時重跑 §1 三項偵測，結果為 0。
   4. **舊方法名清零**：以 `rg` 確認舊方法名於程式碼與測試均無殘留。
   5. **容器內測試（依分支選 runner）**：
      - 分支有 `protected/tests/scripts/run-php84-tests.sh`（PHP 8.4 checkout）：`bash protected/tests/scripts/run-php84-tests.sh fast <測試路徑>`。
      - 無此腳本（PHP 5.6 legacy checkout）：`bash protected/tests/scripts/run-tests.sh`（5.6 fast）；動到 Controller、Repository 或拆帳流程時加跑 `run-tests.sh integration`。本機 DB 帶 `ZDPOS_MYSQL_USER=root ZDPOS_MYSQL_PASSWORD=''`（預設 `develop` 帳號會建庫失敗）。此類分支 vendor PHPUnit 5.7 無法在 8.4 執行，8.4 測試回報 `NOT_RUN`（不得標為通過）。
      - 與本次無關的既有失敗須以基準分支或 commit 歷史舉證後列出。
3. **收尾回報**：列出差異統計摘要、五關驗證結果與未處理項目。保留工作樹變更由使用者手動 commit（建議改名類調整另立獨立 `refactor:` commit）。

- **完成條件**：全部核准項目已套用、五關驗證全數通過（或依規則如實回報 `NOT_RUN`／已舉證之既有失敗）、差異摘要已回報且未自動 commit。

## 判定參考（§1–§5）

### §1 盤點範圍（僅限本分支差異）

- 檢查本分支差異的 `php`、`js`、`html`、`vue` 變更，並以 `diff-filter=A` 列出新物件；未更動的既有程式維持不動；搬遷或重新命名檔案視為既有物件（跟隨 rename 偵測）。
- **View 三項偵測**（勾選 `style` 且差異含 `protected/views/**` 時執行，結果歸 `style` 類，判定見 §4 第 8 條）：
  1. HTML 本體或 `<script>` 新增行含 PHP 流程控制（`<?php if`、`<?php elseif`、`<?php else`、`<?php foreach`、`<?php }` 或三元輸出）；僅比對 PHP 標籤內關鍵字，JS 的 `if`/`else` 與檔頭 PHP 區不計。
  2. 本次新增的 PHP→JS 注入與同一 `<script>` 內其他 `<?php echo`／`<?=` 疊加。
  3. `<script>` 內新增的 `<?php echo`／`<?=` 未經 `CJSON::encode` 或 `CJavaScript::encode`。
- **新增方法命名檢查**（勾選 `style` 時）：列出本分支新增方法（新檔全部方法；既有檔 diff 新增的方法宣告），逐一對照 §4 第 11、13、20 條判定，改名依 §4.2 程序。

### §2 Anchor 規則

anchor 由日期、作者、`[主題]`、描述組成，前後可用 `//`、`#`、`*` 或 HTML 註釋。view 檔（新增檔、新增區段、修改段落）依位置選註釋形式：HTML 區用 `<!-- anchor -->`、`<script>` 與檔頭／其他 PHP 區用 `// anchor`（HTML 區採 HTML 註釋，不用 PHP 註釋包 HTML）。

- **§2.1 新增物件**（基準分支無、本分支新增檔案）：物件註釋放 anchor 恰一次，類別內各方法不再重複；新 Service 的 class docblock 採「功能描述 → 空行 → anchor 行 → 空行 → 補充說明」。
- **§2.2 既有物件＋新增方法**：新增方法 docblock 放 anchor 一次（PHP：功能描述＋anchor 行＋`@param` 描述；JS：功能描述＋anchor 行）；既有物件新增的 `use` 引用行屬本次變更，多行 `use` 於區段開頭放一行 anchor。
- **§2.3 既有物件＋既有方法（修改段落）**：修改段落首行放 anchor 行註釋（先寫 anchor 行註釋，再寫程式碼）；同一方法內連續多個同次修改 hunk 僅於首個 hunk 開頭放一次；view 檔註釋形式見 §2 開頭。

### §3 phpDoc／jsDoc 規則

- 對象為本分支所有新增或修改的方法與物件註釋；保留既有 anchor 行不變（不調整、不刪除）。
- 其餘 doc 文字以 `writing-for-agents` 風格精簡，去除重複與難讀術語，採用 `CONTEXT.md` 實作術語對照表中文（例如：歸零前快照、寫後回讀、來源綁定、回應內容、門市鎖、權限閘、失敗即中止）；英文對照僅供對照既有討論，不寫進註釋。

### §4 Coding Style（只判新增或修改區塊，測試檔一併適用）

勾選 `style` 模組時**必讀** [`references/coding-style-rules.md`](references/coding-style-rules.md)（完整自包含，不依賴目標分支是否存在 `CODING_STANDARDS.md`）：

- **§4（第 1–20 條）**：調用階梯、短陣列、枚舉常數、持久層、變數命名、DDD 與介面收斂、Controller 瘦身、無邏輯視圖與 PHP→JS 注入、前端 JS／AJAX、方法放置、Policy 形狀、catch 慣例、方法名長度、PHP 5.6 語法、測試檔、魔術值、Repository 細則、AJAX／API 回應契約、命名對齊 Laravel。
- **§4.1 條件式檢查**：diff 含 Migration、FormRequest、Event、View 輸出與 SQL、`components`／`modules` 時的額外判定。
- **§4.2 命名調整程序**：可改／不可改範圍、呼叫端與其他未合併分支查找、一次改齊與拆帳分支 receipt 注意事項。
- **§4.3 職責邊界**：轉交 `code-reviewer`、`security-reviewer` 或 `zdpos-js-modernization` 的項目。

### §5 Refactor 規則

檔案搬遷與重構維持既有樣式與註釋，僅做目標搬遷，保持無關段落原樣。
