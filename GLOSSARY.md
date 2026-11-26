# Prompts & Agent Configuration

集中管理跨專案 AI Agent 指示、規則與技能的單一來源儲存庫，將規範投影到各個目標開發專案與本機 Agent 運行環境。

## Language

**Skill**:
跨 Agent 按需觸發的完整工作流、工具包或高內聚領域手冊。不為單一條款建立獨立短項。
_Avoid_: 微型 skill、小規則包

**Rule**:
精簡的常駐底線規範，為自動載入型 Agent 提供最低限度的即時約束，並將細節委派給 **Skill** 或 **Guide**。
_Avoid_: 完整操作手冊

**Reference**:
隸屬於單一 **Skill** 內部、按需漸進載入的子文件或腳本，用來承載流程細節、案例與檢查清單。
_Avoid_: 獨立說明檔、附錄 README

**Guide**:
存在於目標專案文件庫中的跨功能長篇實作指南或 cookbook，由 **Context Router** 或 **Rule** 導流，而非包裝成 **Skill**。
_Avoid_: 規範檔

**Context Router**:
將任務主題映射到對應專案文件、**Rule** 與 **Guide** 的唯讀索引型 **Skill**，補足不自動載入專案規則的 Agent。

**Canonical Source**:
受版本控制追蹤的唯一實體定義位置，所有跨工具目錄與目標專案入口都指向此處。
_Avoid_: 主副本、原檔

**Projection**:
由 **Canonical Source** 透過符號連結映射到目標專案或本機 Agent 環境的執行期入口，本身不應被當作可獨立編輯的副本。
_Avoid_: 同步副本、部署備份

**Eval Workspace**:
技能評測或迭代調校過程產生的暫存實驗目錄，不屬於可部署的 **Skill**。
_Avoid_: 測試技能目錄
