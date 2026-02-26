# Prompt Reference: zdpos_dev

本檔為「參考資料主目錄索引」，依需求載入子文件。  
常駐規範請看 `CLAUDE.md`；本索引不作為優先規範來源。

## 使用方式（按需載入）
1. 先讀 `CLAUDE.md`（權威規範）。
2. 依任務類型只載入需要的子文件（避免一次載入全部）。
3. 若新增長篇主題，建立新子檔並在此索引登記。

## 目錄索引
- 架構與分層：`docs/prompt-reference/architecture.md`
- Yii 內建優先策略（含 Context7 摘要）：`docs/prompt-reference/yii-builtins-priority.md`
- 專案常見改寫方法對照表：`docs/prompt-reference/project-overrides-map.md`
- PHP 5.6 / 專案限制範例：`docs/prompt-reference/examples-php56.md`

## 快速導引
- 要看系統入口、責任邊界、修改路由：讀 `docs/prompt-reference/architecture.md`
- 要決定「先用 Yii 內建還是改寫封裝」：讀 `docs/prompt-reference/yii-builtins-priority.md`
- 要查詢現成封裝避免重複實作：讀 `docs/prompt-reference/project-overrides-map.md`
- 要直接抄用符合限制的樣板：讀 `docs/prompt-reference/examples-php56.md`
