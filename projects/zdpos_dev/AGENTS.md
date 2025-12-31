# AGENTS.md

本檔提供「程式代理人」在本儲存庫工作的精簡指引。完整規範請參考 `CLAUDE.md`。

<!-- OPENSPEC:START -->
## OpenSpec Instructions

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding
<!-- OPENSPEC:END -->

---

## 指令優先序
1. 系統/平台指令
2. `CLAUDE.md`
3. 本檔
4. 使用者需求
5. 其他專案文件

---

## 語言與溝通
- 回應語言：正體中文
- 程式註解：正體中文
- 專有名詞保留英文 (Controller, Model, View, Action)
- 先給結論或建議，再補必要細節；不要輸出內部推理

---

## 核心開發哲學
1. 單一真相來源 (SSOT)：每個概念只有一個權威實作，延展既有邏輯，不複製。
2. 先讀後寫：使用 `rg`/`fd` 研究既有模式，先規劃再動手。
3. 簡潔明瞭：清楚意圖 > 花俏程式。遵循 SOLID (尤其 SRP) 和 DRY。
4. 漸進執行：複雜任務拆解 (>3 步驟先寫計畫)，小步提交確保可編譯、可測試。
5. 測試驅動 (TDD)：Red → Green → Refactor。

---

## Anti-Loop Protocol (防卡死機制)
重要：同一問題連續失敗 3 次，立即停止：
1. 記錄：列出嘗試內容、錯誤訊息、假設
2. 研究：從文件或類似程式碼找 2-3 個替代方案
3. 轉向：簡化問題、改變抽象層級、換方法

---

## 專案語法規範

| 類別 | 規範 |
|------|------|
| PHP 陣列 | 使用 `[]` 語法，禁用 `array()` |
| 陣列操作 | 優先 `array_map`、`array_filter`，避免巢狀 `foreach` |
| POST 存取 | 使用 `Yii::app()->request->getPost()`，禁用 `$_POST` |
| JavaScript | 使用 ES6 語法 |
| PHP 版本 | 相容 PHP 5.6 |

---

## 工具選擇指南

| 任務 | 工具 | 說明 |
|------|------|------|
| 找檔案 | `fd` / Glob | 快速模式比對 |
| 搜程式碼 | `rg` (ripgrep) | 優化的正規搜尋 |
| 讀大檔案 | `head`/`tail` 或分段讀取 | 避免一次載入過多 |
| JSON/YAML | `jq` / `yq` | 結構化資料處理 |
| 程式結構 | `ast-grep` | AST 層級搜尋 |

---

## 規劃模式 (Planning Protocol)
當需求涉及多檔案修改、架構變更或複雜邏輯時：
1. Plan Phase：分析需求，輸出實作計畫
2. Confirmation：等待用戶確認「Go」
3. Execution Phase：用戶確認後才開始寫程式

---

## Docker 測試指令

```bash
# Windows Git Bash 相容格式
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit [Test_Path]

# 範例
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/unit/YosvipRedeemPointRequestTest.php
```

---

## 詳細參考
- `CLAUDE.md`：專案架構與背景資訊、PHP 5.6 限制、Yii 1.1 慣例、命名規範與 PHPDoc/JSDoc 要求
- 若本檔與 `CLAUDE.md` 有出入，以 `CLAUDE.md` 為準。
