# AGENTS.md

本檔只補充 Codex CLI 在本專案需要知道的入口與差異；全域常駐規範以 `CLAUDE.md` 為準。

## Scope
- 適用整個 repo，但僅處理 Codex 專屬補充與導覽。
- 若與 `CLAUDE.md` 衝突，以 `CLAUDE.md` 為準。
- 若更深層目錄另有 `AGENTS.md`，以最近一層補充在地差異。

## Read This When
- 你正用 Codex CLI 從 repo root 開始工作。
- 你需要找專案內 Codex assets 或下一個該讀的在地文件。

## Codex Local Truths
- 專案內 Codex assets 入口：`.codex/skills/`、`.codex/agents/`、`.codex/docs/`。
- 專案內 Codex 設定優先於 user-level `~/.codex/` 同名資源。
- repo 內 `.agents/skills/` 目前是空目錄，Codex 不會讀取此路徑。
- `CLAUDE.md` 是全域主規範；此檔不重述跨工具常駐規則。

## Directory Index
- `protected/AGENTS.md`：Yii MVC 主體、測試與模組入口。
- `domain/AGENTS.md`：Domain layer 邊界、命名與責任。
- `infrastructure/AGENTS.md`：Repository、HTTP、Utility 與資料存取責任。
- `js/AGENTS.md`：Legacy POS 前端、共享狀態與高風險腳本區域。

## Related Files
- `CLAUDE.md`
- `.codex/docs/spark-profile.zh-TW.md`
- `protected/AGENTS.md`
