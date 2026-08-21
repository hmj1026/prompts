# Settings Split

改 `.claude/settings.json`、gitignore、harness profile、Stop-hook 時讀本檔。常駐規範見根目錄 `CLAUDE.md`。

## 追蹤邊界

zdpos-217 working copy 的 `.gitignore` 排除整個 `.claude/`。不要在此 repo 內 `git add` / `git commit` settings 檔。

| 檔案 | 誰追蹤 | 用途 |
|---|---|---|
| `.claude/settings.json` | 僅 prompts monorepo `projects/zdpos-217/.claude/settings.json`（不是 `zdpos_dev/` 資料夾） | team-shared |
| `.claude/settings.local.json` | zdpos-217 working copy gitignored | 個人 SSH / curl / cx perms |
| `.claude/settings.local.json.example` | zdpos-217 可追蹤 | 範本 |

prompts monorepo 的 `projects/zdpos_dev/.claude/settings.local.json` 是被 git 追蹤的殘留舊檔，與 working copy「gitignored」現況不一致，屬 legacy cruft（2026-08-13 稽核發現，未決定是否清除）。

## Harness profile

`.claude/.harness-profile` 可寫一行 `minimal` / `standard` / `strict`，gitignored。範圍僅限直接讀此檔的本地 mirror hooks（statusline / session-start read-outs）。環境變數 `$ZDPOS_HOOK_PROFILE` 覆寫，預設 `standard`。

**此覆寫目前失效**：`.claude/settings.json` 的 `env` 區塊無條件寫死 `ZDPOS_HOOK_PROFILE=standard`，故建立 `.harness-profile` 也不會改變讀該變數的 hook（2026-08-13 稽核發現，尚未決定修復方向）。

關 plugin 擁有的 Stop-hook reminder：在 `settings.local.json` 設 `pluginConfigs."dhpk@dhpk".options.hook_profile`。本地 `.harness-profile` 檔本身不影響 dhpk plugin hooks。
