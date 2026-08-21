# Plugin 與 Harness

Install / leftover hooks / `${CLAUDE_PLUGIN_ROOT}` 解析時讀本檔。常駐規範見根目錄 `CLAUDE.md`。

## 必裝 plugin

| Plugin | 用途 | 安裝 |
|---|---|---|
| **dhpk** | commands、role agents、stack-guidance modules、`rules/` | `claude plugin marketplace add hmj1026/dhpk && claude plugin install dhpk@dhpk` |
| **OpenSpec** | `/opsx:*` | 依 OpenSpec 文件另裝，不由 dhpk 管理 |

版本看 [`.claude/dhpk-versions.json`](../dhpk-versions.json) 驗證範圍；plugin 內建 `check-plugin-version.sh` 於 session-start 比對。勿手動釘版。

zdpos 建議 modules：`php-5.6, yii-1.1, phpunit-5.7, js`。

Commands：canonical `${CLAUDE_PLUGIN_ROOT}/commands/INDEX.md`；zdpos 本地見 [`.claude/commands/INDEX.md`](../commands/INDEX.md)。

Agents：canonical `${CLAUDE_PLUGIN_ROOT}/agents/INDEX.md`；zdpos chain mapping 見 [`.claude/agents/INDEX.md`](../agents/INDEX.md)。

## `${CLAUDE_PLUGIN_ROOT}`

Claude Code 執行期解析為 `~/.claude/plugins/cache/dhpk/dhpk/<version>/`。終端手動查看：

```bash
ls ~/.claude/plugins/cache/dhpk/dhpk/
```

## 本地殘留 hooks

sentinel 路由 / guard / lint 由 plugin `hooks.json` 自動接線（含 migration）。zdpos working copy 只留：

- pre-bash-guard（cs-fixer v2 + opcache 提醒）
- session-start
- post-edit-skill-index
- `reap-stale-sentinels.sh`
- statusline

## History

- 2026-06-12：zdpos-217 撤本地 fork hooks。舊制 `.claude/artifacts/dhpk-tidy/verified-versions.json` 與本地 `check-dhpk-version.sh` 已由 `dhpk-versions.json` 取代並移除。
