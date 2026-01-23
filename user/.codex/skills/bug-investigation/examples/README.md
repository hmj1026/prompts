# Bug Investigation 範例

此目錄包含使用 Bug Investigation Skill 進行調查的示範案例。

## 📌 重要說明

> **範例目的**: 這些範例展示如何應用 5 階段調查方法論，**不代表技能僅適用於這些場景**。
>
> Bug Investigation Skill 是**通用的調查方法論**，可應用於：
> - 🔧 API 整合問題
> - 💾 資料庫一致性問題  
> - ⚡ 效能瓶頸分析
> - 🔄 狀態管理 bug
> - 🌐 前後端資料同步問題
> - 📊 資料流向追蹤
> - 以及任何需要系統化調查的軟體問題

## 📁 範例清單

### state-inconsistency-example/

**場景**: 展示如何調查系統狀態不一致的問題

**適用於**: 任何涉及狀態管理、資料同步、前後端交互的系統

**展示的技能**:
- Phase 1: Problem Discovery - 問題描述與資訊收集
- Phase 2: Evidence Gathering - 資料庫驗證
- Phase 3: Root Cause Analysis - 資料流追蹤與根因定位
- Phase 4: Solution Proposal - 多方案設計與選擇
- Phase 5: Knowledge Documentation - 經驗總結

**關鍵要點**:
- ✅ 如何系統化追蹤資料流
- ✅ 如何識別前後端不一致的根源
- ✅ 如何使用 Mermaid 圖表輔助分析
- ✅ 如何設計驗證方案

## 🎯 如何使用這些範例

### 學習方法論

1. **閱讀範例** - 了解完整的調查流程
2. **理解結構** - 注意 5 個階段的劃分
3. **遷移應用** - 將方法套用到您的問題上

### 創建您自己的調查

使用相同的結構：

```markdown
# [您的問題] 調查

> **範例目的**: 示範方法論在 [領域] 的應用

## 問題描述
...

## 調查過程
### 階段 1: Problem Discovery
### 階段 2: Evidence Gathering  
### 階段 3: Root Cause Analysis
### 階段 4: Solution Proposal
### 階段 5: Knowledge Documentation
```

## 💡 範例特性

所有範例都：
- ✅ 展示完整的 5 階段方法論
- ✅ 包含實際的資料流追蹤過程
- ✅ 提供 Mermaid 圖表範例
- ✅ 記錄根因分析思路
- ✅ 提出多個解決方案選項

## 🤝 貢獻範例

歡迎提交不同領域的調查範例！

建議的範例方向：
- API 整合錯誤調查
- 效能問題根因分析
- 資料損壞調查
- 並發問題追蹤
- 記憶體洩漏分析

提交 PR 時請：
1. 遵循相同的 5 階段結構
2. 使用通用的術語（避免過於特定的業務邏輯）
3. 移除任何機敏資料
4. 提供清晰的 Mermaid 圖表
