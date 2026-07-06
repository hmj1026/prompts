# MCP Server Inventory (zdpos_dev)

## Scope

zdpos_dev 沒有 `.mcp.json`、`.claude/settings.json` 也沒有 `mcp` 區段。session 中可見的 MCP namespace **全部由 user-level plugins 注入**，跨專案共用。本文件列出每個 namespace 的來源 plugin、用途、與 zdpos 工作流的對應入口。

> **已知風險（另案追蹤，本文件不重述細節）**：本專案 `mysql-dev-ro` / `mysql-dev-remote` 兩個 project-scoped MCP server（見 `~/.claude.json` `projects["/home/paul/projects/zdpos-217"].mcpServers`）的資料庫密碼為明文儲存，已於 2026-07-03 確認排除在本 harness-doc change 外、獨立追蹤處理。

## Active MCP Namespaces

> 來源類型分三類：(1) `.claude.json` user-level `mcpServers`、(2) plugin 注入、(3) claude.ai 內建 remote MCP（透過 oauth 啟用）。

### Local / Plugin MCP

| Namespace | Source | 主要用途 | zdpos 入口 |
|---|---|---|---|
| `mcp__gitnexus__*` | `.claude.json` user-level (`gitnexus mcp` binary) | Code intelligence: impact / context / query / rename / detect_changes | `.claude/rules/tool-routing.md`、各 `gitnexus-*` skill |
| `mcp__codex__codex`, `codex-reply` | codex@openai-codex (user scope v1.0.5) | Codex MCP delegation: review / architect / implement | `.claude/skills/codex-*`、agent `codex-rescue` |
| `mcp__plugin_claude-mem_mcp-search__*` | claude-mem@thedotmack v13.9.2 | Cross-session memory: smart_search / search / get_observations / timeline | skill `claude-mem:mem-search`、SessionStart hook auto-context |
| `mcp__plugin_context7_context7__*` | context7@claude-plugins-official (npm `@upstash/context7-mcp`) | Library / framework / API docs lookup（local fallback） | skill `docs-lookup`、agent `docs-lookup` |

### claude.ai Built-in Remote MCP

由 claude.ai oauth 啟用、跨專案共用；於 zdpos_dev session 內 `claude mcp list` 顯示 ✓ Connected。

| Namespace | Endpoint | 用途 |
|---|---|---|
| `mcp__claude_ai_Context7__*` | `https://mcp.context7.com/mcp` | Context7 官方 remote（與本地 plugin namespace `mcp__plugin_context7_context7__*` **雙佈署**，效果相同） |
| `mcp__claude_ai_Canva__*` | `https://mcp.canva.com/mcp` | Canva 設計檔操作（zdpos 不主動用） |
| `mcp__claude_ai_Google_Drive__*` | `https://drivemcp.googleapis.com/mcp/v1` | Google Drive 檔案存取（zdpos 不主動用） |
| `mcp__claude_ai_Gmail__*` | `https://gmailmcp.googleapis.com/mcp/v1` | Gmail 讀寫（zdpos 不主動用） |
| `mcp__claude_ai_Google_Calendar__*` | `https://calendarmcp.googleapis.com/mcp/v1` | Calendar 讀寫（zdpos 不主動用） |

**Context7 雙佈署註記**：tool 命名前綴混用是 Claude Code 的 namespacing 細節。優先用 remote（穩定度高、版本由 Upstash 管），plugin 版作為 offline fallback；如要單一路徑可在 `~/.claude/settings.json` `permissions.deny` 屏蔽其中一邊，但目前共存無實害。

## Codex Model Configuration

`mcp__codex__codex` / `codex-reply` 與 codex plugin 自己的 agent/skill（`codex:rescue`、`/codex-review*` 等）走**兩條互不相關的路徑**，各自的 model/effort 設定位置不同、不需要同步：

| 路徑 | 設定位置 | 現況 | 影響範圍 |
|---|---|---|---|
| MCP server（`mcp__codex__codex`） | `~/.claude.json` 全域 `mcpServers.codex.args`（`-c model=… -c model_reasoning_effort=…`） | `model=gpt-5.3-codex`、`model_reasoning_effort=high` | **全域**，影響所有專案，非 per-project |
| codex plugin agent/skill（`codex:rescue` 等，經 `codex app-server`） | `~/.codex/config.toml`（`model` / `model_reasoning_effort` 頂層鍵） | `model=gpt-5.5`、`model_reasoning_effort=xhigh` | 僅影響未帶 `--model`/`--effort` 明確覆寫的 app-server 呼叫 |

換 MCP server 的模型：編輯 `~/.claude.json` 的 `mcpServers.codex.args` 字串值。換 plugin agent/skill 的預設模型：編輯 `~/.codex/config.toml` 頂層 `model` / `model_reasoning_effort`。兩者刻意分離，換一邊不會影響另一邊。

## Installation Status

```
~/.claude/plugins/installed_plugins.json     ← 全域 plugin registry
~/.claude/plugins/cache/<marketplace>/...    ← versioned plugin payload
```

zdpos_dev 本身 **沒有** `.claude/plugins/` 目錄、也沒有 plugin manifest。所有 MCP 工具都是「project 借用 user-level plugin」。

## Indirect Dependency Note: everything-claude-code

`everything-claude-code@everything-claude-code` (v1.9.0) plugin scope=local 綁定在 `~/projects/ccas`，**不**屬於 zdpos_dev。但 zdpos_dev 透過以下方式間接引用：

- `.claude/docs/ecc-portability-plan.md` — port `gemini-adapt-agents.js` / `harness-adapter-compliance.js` 到本地 `.claude/scripts/`
- `.claude/scripts/codemaps/generate.ts` — header 註明源自 ECC
- `.claude/scripts/harness-audit.js` — 含「若本專案就是 ECC plugin」的判定分支（generic logic）
- `.claude/skills/skill-scout/SKILL.md` — 將 `everything-claude-code` 列為 marketplace 搜尋關鍵字

不是 plugin 依賴、是**源碼參考**。ccas 的 plugin install 與 zdpos_dev 無耦合。

## Why No `.mcp.json`

MCP servers 由 plugins 自動注入時，**不需要**在專案再寫一份 `.mcp.json`。重複定義反而會產生衝突。若日後需要 zdpos 專屬的 MCP server（例如本地 dev MySQL 的 SQL inspector），才用 `.mcp.json` 宣告。

## Pruning Considerations

`claude-mem` 暴露 20+ deferred MCP tools，功能重疊度高（`smart_search` / `search` / `memory_search` / `observation_search` / `query_corpus` / `build_corpus` 等）。**目前不建議裁剪**，根據 2026-05-25 調查結果：

1. **Plugin 結構**：`~/.claude/plugins/marketplaces/thedotmack/plugin/.mcp.json` 用單一 MCP server `mcp-search` 包所有 tool；**沒有** per-tool disable 設定。
2. **唯一槓桿是 Claude Code permission deny**：在 settings.json `permissions.deny` 列出 `mcp__plugin_claude-mem_mcp-search__<name>`，但要逐一列舉 12+ 條，且 user-level 影響跨專案。
3. **誤關風險**：主力入口 `smart_search` 一旦誤關，SessionStart hook 的 auto-context 與 `claude-mem:mem-search` skill 就會失效。

→ 結論：**不在 local override 裁剪**；若要結構性解決，請走 [claude-mem upstream issue](https://github.com/thedotmack/claude-mem/issues) 要求 plugin 支援 `MCP_DISABLED_TOOLS` env var 或 manifest-level tool toggle。

目前 project allowlist（`.claude/settings.json`）已挑出 8 個高頻 tool（list_corpora / build_corpus / get_observations / timeline / search / smart_search / smart_outline / smart_unfold），這是合理的「白名單方向減噪」，無需再縮。

## Update Discipline

新增 MCP plugin → 更新本表 → CLAUDE.md `Key references` 表也加一行對應 skill 入口。

## Maintenance / Troubleshooting

### 連線健康度

```bash
claude mcp list                                        # 全部 ✓ Connected 為通
cat /home/paul/.claude/mcp-health-cache.json           # persistent probe cache
```

`mcp-health-cache.json` 只記 user-level `.claude.json` 內 `mcpServers` 的 server（目前是 `gitnexus` / `codex`）；plugin 與 claude.ai remote 的健康度走 on-demand probe，不入 cache。失準時直接 `echo '{"version":1,"servers":{}}' > ~/.claude/mcp-health-cache.json` reset。

**`claude mcp list` 不等於「目前 session 實際啟用狀態」**：這個指令對「全部已設定的 server」做即時連線探測，**不檢查** `disabledMcpServers`。若手動停用某個 server（例如 claude.ai remote connector），只要該服務帳號層仍可連通，`claude mcp list` 依然會顯示 `✔ Connected`——這不代表停用失效，只代表這個指令衡量的是「可連線」而非「本專案是否載入其工具」。要驗證真實停用狀態：

```bash
jq -r '.projects["/home/paul/projects/zdpos-217"].disabledMcpServers' ~/.claude.json   # 真實停用清單
```

或在 session 內開 `` `/mcp` `` 面板——面板會正確反映停用狀態並停止載入該 server 的工具；`claude mcp list` 不會。

### 多版本 cache 漂移

Plugin 升級會留下舊版 cache：

```bash
ls /home/paul/.claude/plugins/cache/<vendor>/<plugin>/
# 預期只剩 installed_plugins.json 標示的版本；多版本並存代表舊版未清
```

清理（**先確認沒有 CLI session 還掛載該版本的 MCP child**）：

```bash
find /home/paul/.claude/plugins/cache/<vendor>/<plugin>/<old_version> -type f -delete \
  && find /home/paul/.claude/plugins/cache/<vendor>/<plugin>/<old_version> -depth -type d -empty -delete
```

注意 `pre-bash-guard.sh` 會 block `rm -rf` 對 plugins 目錄，必須用 `find … -delete`。

### MCP child process 「重複」≠ 殭屍

每個 `claude` / `codex` CLI session 都會 spawn 自己的 MCP children。session 數 × MCP server 數 看起來像殭屍，但通常都有活的 parent。判定是否真孤兒**必須**走 ppid：

```bash
ps -eo pid,ppid,etime,cmd | grep -E "mcp-server.cjs|codex.*mcp-server|context7-mcp|chroma-mcp" | grep -v grep \
  | awk '{print $1, $2}' | while read pid ppid; do
      pcmd=$(ps -p $ppid -o comm= 2>/dev/null || echo "ORPHAN")
      echo "pid=$pid ppid=$ppid parent=$pcmd"
    done
```

- `parent=claude` / `parent=codex` / `parent=bun`（worker-service daemon）→ 合法、**勿殺**
- `parent=ORPHAN` → 真孤兒，可 `kill <pid>`

**禁止** 不分 ppid 的 `pkill -f mcp-server.cjs`，會中斷其他活著的 CLI session。詳見 memory `trap_mcp_zombie_processes.md`。

### 文件對齊 SOP

plugin 增刪或 claude.ai remote MCP 開關後：

1. `jq -r '.plugins | keys[]' ~/.claude/plugins/installed_plugins.json` 列出實際安裝
2. `claude mcp list` 列出實際連線中
3. 與本文件 `Active MCP Namespaces` 表交叉比對，差異即 doc drift
