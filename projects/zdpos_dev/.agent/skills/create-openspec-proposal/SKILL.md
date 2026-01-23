---
name: create-openspec-proposal
description: SDD (Spec-Driven Development) workflow for creating OpenSpec proposals
---

# OpenSpec SDD Workflow

此 workflow 遵循 OpenSpec 的 **三階段工作流程 (Three-Stage Workflow)**。

---

## 🚦 Decision Gate: 是否需要提案？

```
新需求?
├─ Bug fix (恢復預期行為)? → 直接修復，不需提案
├─ Typo/格式/註解? → 直接修復
├─ 依賴更新 (non-breaking)? → 直接修復
├─ 新功能/能力? → 建立提案
├─ Breaking change? → 建立提案
├─ 架構變更? → 建立提案
└─ 不確定? → 建立提案 (較安全)
```

---

## Stage 1: Creating Changes (建立變更)

### 1.1 Context Discovery (上下文探索)

執行前必須完成 Context Checklist:
- [ ] 讀取 `openspec/project.md` 了解專案慣例
- [ ] 讀取 `openspec/AGENTS.md` 了解 SDD 規範
- [ ] 執行 `openspec list` 查看進行中的變更，避免衝突
- [ ] 執行 `openspec list --specs` 查看現有規格
- [ ] 若有相關規格，使用 `openspec show [spec]` 檢視

### 1.2 Plan and Scaffold (規劃與建立結構)

1. 選擇唯一的 `change-id`:
   - 格式: `YYYY-MM-DD-verb-noun` (kebab-case)
   - 動詞前綴: `add-`, `update-`, `remove-`, `refactor-`, `fix-`

2. 建立目錄結構:
   ```bash
   mkdir -p openspec/changes/<change-id>/specs/<capability>
   ```

3. 建立必要檔案:
   - `proposal.md` - Why, What Changes, Impact
   - `tasks.md` - 實作任務清單
   - `specs/<capability>/spec.md` - 規格差異
   - `design.md` (選用) - 跨模組、架構變更、有風險時建立

### 1.3 Draft Specification (撰寫規格)

在 `spec.md` 中使用:
- `## ADDED Requirements` - 新增功能
- `## MODIFIED Requirements` - 修改行為
- `## REMOVED Requirements` - 移除功能
- `## RENAMED Requirements` - 重新命名

**重要**: 每個 Requirement **必須**包含至少一個 `#### Scenario:`

### 1.4 Validate (驗證)

```bash
openspec validate <change-id> --strict
```

修復所有錯誤後再進行下一步。

### 1.5 ⛔ APPROVAL GATE (審核關卡)

此為 **強制停止點**:

1. 使用 `notify_user` 通知用戶審核
2. **必須**設置 `ShouldAutoProceed: false`
3. **必須**設置 `BlockedOnUser: true`
4. 等待用戶明確回覆以下任一詞彙才能繼續，使用技能 `test-driven-development`:
   - "Approve"
   - "同意"
   - "批准"

⚠️ 以下 **不視為批准**:
- "LGTM"
- 檔案評論
- 任何其他非明確批准的回應

---

## Stage 2: Implementing Changes (實作變更)

**前提**: Stage 1 已獲得明確批准

### 2.1 理解需求
- 讀取 `proposal.md` 理解目標
- 讀取 `design.md` (如有) 理解技術決策
- 讀取 `tasks.md` 獲取實作清單

### 2.2 依序實作
- 按照 `tasks.md` 順序完成任務
- 每完成一項更新為 `- [x]`
- 遵循 TDD: 紅 → 綠 → 重構

### 2.3 完成確認
- 確保 `tasks.md` 所有項目都已完成
- 驗證功能正常運作

---

## Stage 3: Archiving Changes (歸檔變更)

部署後執行:

```bash
openspec archive <change-id> --yes
```

這會:
- 將 `changes/<id>/` 移動到 `changes/archive/YYYY-MM-DD-<id>/`
- 更新 `specs/` (如有規格變更)

---

## 📋 Quick Reference

| CLI 指令 | 用途 |
|---------|------|
| `openspec list` | 查看進行中的變更 |
| `openspec list --specs` | 查看現有規格 |
| `openspec show [item]` | 檢視詳細內容 |
| `openspec validate [item] --strict` | 驗證規格 |
| `openspec archive <id> --yes` | 歸檔已完成變更 |
