---
name: zdpos-feature-doc
description: "[薄轉發入口 -> zdpos-doc-studio (feature 模式)] 為 zdpos-217 系統產出協作者技術手冊 (docs/collaborators/<slug>/README.md 與 index.html) 及既有客戶導入 SOP。本技能已整併至 zdpos-doc-studio，呼叫時自動轉發至 zdpos-doc-studio 的 feature 模式。"
---

# ZDPOS 協作者技術手冊 (`zdpos-feature-doc` → 薄轉發至 `zdpos-doc-studio`)

> [!IMPORTANT]
> **本技能已與 `zdpos-qa-doc` 統一整併為單一技能 [`zdpos-doc-studio`](../zdpos-doc-studio/SKILL.md)（`--mode feature`）！**
> 所有編譯器、Mermaid 防裁切預渲染引擎、HTML 互動樣板與 Playwright 無頭瀏覽器驗證器皆由 `zdpos-doc-studio` 單一來源（SSOT）維護。

---

## 執行步驟（請立即轉發讀取）

1. **讀取主技能與 `feature` 模式專屬規範**：
   - 主技能路由與共用八大鐵律：[`../zdpos-doc-studio/SKILL.md`](../zdpos-doc-studio/SKILL.md)
   - 協作者手冊 8 大章節與舊客導入 SOP 指引：[`../zdpos-doc-studio/references/mode-feature-guidelines.md`](../zdpos-doc-studio/references/mode-feature-guidelines.md)
   - 標準範本：[`../zdpos-doc-studio/references/doc-template.md`](../zdpos-doc-studio/references/doc-template.md)

2. **使用統一 CLI 執行範圍盤點、腳手架、無損編譯與雙重驗證**：
   ```bash
   # 1. 盤點 Git 分支或 Anchor 影響範圍
   python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py inspect --anchor "<anchor_string>"

   # 2. 建立協作者手冊草稿並自動註冊 docs/collaborators/index.html
   python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py scaffold \
     --mode feature --slug <slug> --title "<功能中文名稱>" --anchor "<anchor_string>" [--migration]

   # 3. 撰寫完 README.md 後執行無損編譯與 Playwright Headless 驗收
   python3 .agent/skills/zdpos-doc-studio/scripts/doc_studio.py compile \
     --mode feature docs/collaborators/<slug>/README.md
   ```
   *(註：本目錄下之 `scripts/`、`references/`、`resources/` 已透過相對軟連結指向 `../zdpos-doc-studio/`，舊版指令路徑完全相容。)*
