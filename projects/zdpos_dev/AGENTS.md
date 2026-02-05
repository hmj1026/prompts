# AGENTS.md

本檔為程式代理人入口與索引；所有規範與優先序以 `CLAUDE.md` 為準。本檔僅保留必要指引與指向。

<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

---

## 指引
- 規範：請以 `CLAUDE.md` 為唯一權威來源。
- 架構與背景：請參考 `GEMINI.md`（僅供背景說明，不作為規範）。
- 若需提案或規劃，先開啟 `@/openspec/AGENTS.md`。
- 角色定位：本代理以 **Codex** 角色執行；命令、編碼與工具規範請依「平台支援與命令慣例」及「文本分析與編碼（UTF-8）」段落。

## 提示詞最佳實務（Best Practices）
- 精簡清楚：只提供必要上下文，明確指定目標、輸出格式與步驟順序。
- 逐步與失敗回復：先做最小可行查找；遇到工具/權限/編碼錯誤時停止重試並回報具體錯誤與替代路徑。

## 優先序與衝突處理

若指令/規範彼此衝突，依序採用（由高到低）：
1. 系統與平台限制（Sandbox/權限/網路/OS 限制）
2. 使用者當次明確要求（本回合）
3. `CLAUDE.md`（本專案唯一權威規範）
4. 本檔 `AGENTS.md`（輔助指引與索引）
5. 其他專案文件（例如 `GEMINI.md`，僅供背景）

補充約定：
- `<!-- OPENSPEC:START -->...<!-- OPENSPEC:END -->` 為 managed 區塊，非必要勿手動修改。
- `<!-- CODEX-ONLY:START -->...<!-- CODEX-ONLY:END -->` 僅 Codex CLI 參考；其他 CLI/Agent 可忽略，不視為通用規範。
- `<!-- ENV-NOTE:START -->...<!-- ENV-NOTE:END -->` 為環境差異說明，不保證跨機器一致；請以實際環境為準。

## 平台支援與命令慣例（Windows / macOS）
本專案可在 Windows 與 macOS 同時開發；以下規範以「跨平台可重現」為原則，並把平台特有事項分段標示。

### 1. Shell 與命令格式
* **首選 Shell**: 一律以 POSIX Shell（`bash`）為主。
  - Windows: 優先使用 Git Bash 或 WSL。
  - macOS/Linux: 直接使用預設終端機。
* **建議包裝**: 非互動環境建議使用 `bash -lc "..."` 以確保環境變數載入。
* **PowerShell 處理**: 
  - 僅在無法啟動 `bash` 時作為 fallback。
  - 執行前請務必設定編碼：`$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()`。

### 1.1 Docker / Runtime 環境
若專案使用 Docker，請勿假設本機具有 runtime (php, python, node 等)。

* **檢查容器**: 使用 `docker ps` 確認運行中的容器名稱 (如 `php_app`, `node_service`)。
* **執行命令**:
  - `docker exec -it <container_name> <command>`
  - 範例：`docker exec -it pos_php php -v` 或 `docker exec -it node_app npm test`

### 2. 工具選用指南
| 類別 | 推薦工具（依優先序） | 說明 |
| :--- | :--- | :--- |
| **內容搜尋** | `rg` (ripgrep) | 取代 `grep`/`findstr`，支援 .gitignore |
| **檔名搜尋** | `fd` (fd-find) | 取代 `find`，更直覺快速 (Ubuntu 上可能為 `fdfind`) |
| **結構化搜尋** | `ast-grep` / `sg` | 用於程式碼結構搜尋 (選用) |
| **JSON/YAML** | `jq`, `yq` | 解析設定檔與 API 回應 |
| **文本處理** | `sed`, `awk`, `python3` | 避免使用平台專屬的複雜管道處理 |

### 2.1 文本分析與編碼
* **優先工具**: 使用 `rg`, `fd`, `jq`, `python3` 等跨平台工具。
* **編碼**: 嚴格要求 **UTF-8**。
  - Windows 下若遇到編碼問題，優先嘗試在 `bash` 環境操作，或在 Python 腳本中指定 `encoding='utf-8'`.
  - PowerShell 讀取檔案時，必須明確指定 UTF-8，例如：`Get-Content -Encoding UTF8 -Path <file>`。

---

## 📂 路徑格式規範

* **相對路徑**: 文件與指令優先使用相對路徑 (如 `./src/...`)。
* **分隔符**: 統一使用 `/` (Forward Slash)，Windows 系統亦多數支援。
* **跨平台注意事項**:
  - **Windows (Git Bash)**: 絕對路徑使用 `/c/Users/...` 格式。
  - **macOS/Linux**: 使用標準 `/Users/...` 或 `/home/...`。
* **Git 操作**: 建議開啟 `core.fsmonitor` 與 `core.untrackedCache` 以優化大型專案效能。

---

## ⚠️ 強制前置檢查 (MUST DO)

執行任何複雜任務前，請先確認環境能力：

1. **檢查工具**: `command -v rg fd jq git` (Bash) 或 `Get-Command rg, fd, jq, git` (PowerShell)。
2. **檢查 Runtime**: `php -v`, `node -v`, `python3 --version` (或確認對應 Docker 容器)。
3. **回報缺漏**: 若缺少必要工具，請明確提示使用者安裝。
   - Windows (Scoop): `scoop install ripgrep fd jq git`
   - macOS (Brew): `brew install ripgrep fd jq git`
   - Debian/Ubuntu: `apt install ripgrep fd-find jq git`
