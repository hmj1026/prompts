---
name: zdpos-qa-doc
description: "[薄轉發入口 -> zdpos-doc-studio (qa 模式)] 為 zdpos-217 系統產出高對比離線互動式 QA 手動測試手冊 (docs/qa/<module>/QA-<slug>-manual.md 與 .html)。本技能已整併至 zdpos-doc-studio，呼叫時自動轉發至 zdpos-doc-studio 的 qa 模式。"
---

# ZDPOS QA 手動測試手冊 (`zdpos-qa-doc` → 薄轉發至 `zdpos-doc-studio`)

> [!IMPORTANT]
> **本技能已與 `zdpos-feature-doc` 統一整併為單一技能 [`zdpos-doc-studio`](../zdpos-doc-studio/SKILL.md)（`--mode qa`）！**
> 所有編譯器、Mermaid 防裁切預渲染引擎、HTML 互動樣板與 Playwright 無頭瀏覽器驗證器皆由 `zdpos-doc-studio` 單一來源（SSOT）維護。

---

## 執行步驟（請立即轉發讀取）

1. **讀取主技能與 `qa` 模式專屬規範**：
   - 主技能路由與共用八大鐵律：[`../zdpos-doc-studio/SKILL.md`](../zdpos-doc-studio/SKILL.md)
   - QA 黑箱邊界、本文不測清單與四段式 `TC-xx` 指引：[`../zdpos-doc-studio/references/mode-qa-guidelines.md`](../zdpos-doc-studio/references/mode-qa-guidelines.md)
   - 案例撰寫準則與範本：[`../zdpos-doc-studio/references/qa-case-guidelines.md`](../zdpos-doc-studio/references/qa-case-guidelines.md)、[`../zdpos-doc-studio/references/qa-doc-template.md`](../zdpos-doc-studio/references/qa-doc-template.md)

2. **使用統一 CLI 執行範圍盤點、腳手架、無損編譯與雙重驗證**：
   ```bash
   # 1. 盤點 Git 分支或 Anchor 影響範圍
   python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py inspect --anchor "<anchor_string>"

   # 2. 建立 QA 手冊 Markdown SSOT 草稿
   python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py scaffold \
     --mode qa --module <module> --slug <slug> --title "<功能中文名稱>"

   # 3. 撰寫完 QA-<slug>-manual.md 後執行無損編譯與 Playwright Headless 驗收
   python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py compile \
     --mode qa docs/qa/<module>/QA-<slug>-manual.md
   ```
   *(註：本目錄下之 `scripts/`、`references/`、`resources/` 已透過相對軟連結指向 `../zdpos-doc-studio/`，舊版指令路徑完全相容。)*
