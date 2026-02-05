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

## 優先序與衝突處理（通用）
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

### 1. Shell 與命令格式（跨平台）
* **首選 Shell**: POSIX Shell（`bash` 或 `zsh`）。文件中的範例命令以 POSIX 形式書寫。
* **建議包裝**: 若要在非互動環境中保持一致，使用 `bash -lc "..."`（login shell，環境更一致）。
* **例外（通用原則）**: 若環境無法使用 POSIX Shell，允許暫時使用「目前外層 Shell」執行 **單一可攜工具**（如 `rg`/`fd`/`jq`/`yq`/`php`/`python3`/`mysql`）做「讀取/定位」；避免 shell 專用管道與複雜語法。
* **嚴禁使用（可攜性）**: 以平台/殼層專用管道取代既定檢索流程（例如用 `Select-String`/`Get-ChildItem`/`findstr` 來取代 `rg`/`fd`）。

<!-- CODEX-ONLY:START -->
> **Codex 專用說明**：Codex CLI 的執行環境可能會限制 Bash 啟動（例如回傳 `E_ACCESSDENIED`），此時才套用上方「例外」做最小化讀取/定位；不要在此模式下做大規模改檔或重構。
<!-- CODEX-ONLY:END -->

### 2. 工具選用指南（跨平台優先序）
| 類別 | 推薦工具（依優先序） | 嚴禁使用 |
| :--- | :--- | :--- |
| **內容搜尋** | `rg`（首選，取代 `grep`） | `findstr`, `Select-String` |
| **檔名搜尋** | `fd`（首選，取代 `find` 進行檔名/副檔名查找） | `dir`, `Get-ChildItem`（用於檢索） |
| **結構化搜尋** | `ast-grep` / `sg`（JS/TS/部分語言的 AST 搜尋，選用） | 以正則硬做 AST refactor |
| **文本處理** | `sed`, `awk`（在 Bash 中） | `PowerShell` 管道做大量文字處理 |
| **JSON/YAML** | `jq`, `yq` | 手寫解析、臨時字串切割 |
| **互動式過濾** | `fzf`（選用） |  |
| **檔案操作** | `ls`, `cat`, `cp`, `rm`, `mkdir -p`（在 Bash 中） | `del`, `copy` |
| **複雜邏輯** | `python3`（必要時可搭配 `uv` 隔離環境） | 複雜多行 Shell、`.ps1` |
| **Git 操作** | `git status`, `git log`, `git commit` | 任何 GUI 工具或 PS-Git 模組 |

<!-- ENV-NOTE:START -->
### 3. 工具可用性（環境相關）
> 不同機器工具可能不同；請以實際 PATH 為準。
* 檢查工具是否存在（跨平台）：`command -v rg fd jq yq fzf python3 php mysql git`
* 常用工具（範例）：`rg`, `fd`, `jq`, `yq`, `fzf`, `ast-grep`/`sg`, `curl`, `wget`, `php`, `mysql`, `python3`, `uv`
<!-- ENV-NOTE:END -->

---

## 📂 路徑格式規範（跨平台）
* **預設**: 文件與指令範例優先使用相對路徑（例如 `./protected/...`、`./js/...`），減少平台差異。
* **POSIX Shell 中**: 一律用 `/` 作為分隔符；避免在 POSIX 指令中出現 `\`。
* **家目錄**: 優先使用 `~`（例如 `~/projects/...`）。
* **Python 路徑**: Python 多能同時接受 `\` 與 `/`；但同一段流程請保持一致，避免混用。

<!-- WINDOWS-ONLY:START -->
### Windows（Git Bash / Scoop）
* **POSIX 路徑（Git Bash）**: 使用 `/c/Users/<USER>/...`、`/e/projects/...` 或 `~`。
* **Windows → POSIX 轉換（選用）**: `cygpath -u 'E:\projects\zdpos_dev'`。
* **工具安裝/來源（範例）**: Scoop；工具 shims 位置常見於 `~/scoop/shims`。
* **cmd 例外**: 僅在需要執行 `.bat` / `.cmd` 或 `setx` 時才使用 `cmd /c`。
<!-- WINDOWS-ONLY:END -->

<!-- MACOS-ONLY:START -->
### macOS（zsh/bash / Homebrew）
* **POSIX 路徑**: `/Users/<user>/...` 或 `~`。
* **工具安裝/來源（範例）**: Homebrew（`brew install ripgrep fd jq yq fzf` 等）。
<!-- MACOS-ONLY:END -->

---

## 🛠️ 指令執行範本 (Best Practices)

### 檔案檢索與內容分析
> **任務**: 尋找專案中所有包含 "Yii" 字串的檔案並列出權限。
>
> **正確執行**: 
> `bash -lc "rg -l 'Yii' . | xargs -I{} ls -l {}"`

### 複雜邏輯處理 (Python 優先策略)
> **任務**: 批次分析日誌檔案並生成 Markdown 摘要。
>
> **正確執行**: 
> 1. 撰寫 `temp_analyzer.py` 利用 Python 的強大文本處理能力。
> 2. 執行 `python temp_analyzer.py`。
> 3. 獲取結果後刪除該臨時腳本。

### Git 效能維護 (解決 git status 慢)
> **任務**: 確保 Git 在 Windows 環境下保持高效。
>
> **正確執行**: 
> `bash -lc "git config --global core.fsmonitor true && git config --global core.untrackedCache true"`

---

## ⚠️ 啟動前環境自檢 (Self-Diagnostic)
Agent 在每個對話階段開始前，應進行以下檢查：
1. **優先工具可用性**: 確認 `rg --version`、`fd --version`、`jq --version` 能正常執行。
2. **語言版本確認**: `php -v`、`python3 --version`（避免誤用不相容版本）。
3. **I/O 優化**: 檢查 Git 配置（`core.fsmonitor` / `core.untrackedCache`）是否已開啟。
