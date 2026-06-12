---
name: "OPSX: Validate Sync"
description: 驗證 delta spec 與 main spec 的 sync 相容性，預防 archive 時發生 header 比對失敗或內容遺失
category: Workflow
tags: [workflow, specs, validation, experimental]
argument-hint: "[change-name]"
---

驗證未 archive 的 change 中 delta spec 是否能正確 sync 到 main spec，預防以下問題：

1. **Header 不匹配**：MODIFIED requirement header 在 main spec 中找不到對應
2. **層級錯誤**：將 main spec 的 Scenario 誤當作獨立 Requirement
3. **內容遺失**：MODIFIED 取代時意外刪除 main spec 中的既有 scenario
4. **名稱衝突**：ADDED spec 的 capability name 已存在於 main specs

**Input**: 可選參數 `[change-name]`。若省略，驗證所有未 archive 的 change。

**Steps**

1. **決定驗證範圍**

   若有指定 `$ARGUMENTS`：
   - 驗證 `openspec/changes/$ARGUMENTS/specs/` 下的 delta specs

   若未指定：
   - 執行 `openspec list --json` 取得所有 active changes
   - 篩選出有 `specs/` 目錄的 changes（無 delta spec 的跳過）
   - 逐一驗證

2. **對每個 change 執行四項檢查**

   先收集 delta spec 清單：
   ```bash
   find openspec/changes/<name>/specs -name "spec.md" -type f
   ```

   對每個 delta spec 檔案 `openspec/changes/<name>/specs/<capability>/spec.md`：

   ### 檢查 A：ADDED capability 名稱衝突

   - 若 delta spec 包含 `## ADDED Requirements`
   - 檢查 `openspec/specs/<capability>/spec.md` 是否已存在
   - 若存在：這不是錯誤（sync 會追加），但檢查 delta 中的 requirement header 是否與 main spec 已有的 requirement 重複
   - 若重複：報 WARNING（sync 會覆蓋既有 requirement）

   ### 檢查 B：MODIFIED header 精確比對

   - 提取 delta spec 中 `## MODIFIED Requirements` 區塊下所有 `### Requirement: <name>` header
   - 提取對應 main spec `openspec/specs/<capability>/spec.md` 中所有 `### Requirement: <name>` header
   - 逐一比對（whitespace-insensitive）
   - 若 delta header 在 main spec 中找不到匹配：報 **CRITICAL**
   - 額外檢查：該 header 文字是否出現在 main spec 的 `#### Scenario:` 層級（層級錯誤）

   ### 檢查 C：MODIFIED 內容完整性

   - 對每個 MODIFIED requirement：
     - 讀取 main spec 中對應 requirement 的所有 `#### Scenario:` header
     - 讀取 delta spec 中對應 requirement 的所有 `#### Scenario:` header
     - 因為 sync 是 **intelligent merging**（非全量取代），此處僅報 INFO 列出差異
     - 但若 delta 的描述文字（requirement 首行）與 main 完全不同，報 WARNING：sync 後描述會被取代

   ### 檢查 D：REMOVED / RENAMED 驗證

   - 若有 `## REMOVED Requirements`：確認目標 requirement 存在於 main spec
   - 若有 `## RENAMED Requirements`：確認 FROM header 存在於 main spec，TO header 不存在

3. **產出驗證報告**

   ```
   ## Sync Validation Report

   ### <change-name>

   | Capability | Check | Status | Detail |
   |------------|-------|--------|--------|
   | ... | ... | ... | ... |

   #### CRITICAL (Must fix before archive)
   - ...

   #### WARNING (Review before archive)
   - ...

   #### INFO
   - ...

   **Result**: X critical, Y warnings, Z info
   ```

   若驗證多個 changes，每個 change 獨立一個區塊。

   **最終摘要**（多 change 時）：
   ```
   ## Summary
   | Change | Critical | Warning | Info | Verdict |
   |--------|----------|---------|------|---------|
   | ... | ... | ... | ... | PASS/FAIL |
   ```

4. **若有 CRITICAL 問題，提供修正建議**

   對每個 CRITICAL 問題，說明：
   - 問題原因（如「delta 中的 Requirement X 在 main spec 中是 Scenario 層級，非 Requirement 層級」）
   - 修正方式（如「改為 MODIFY 包含該 Scenario 的 Requirement Y，並在其中新增/修改 Scenario」）
   - 涉及的檔案路徑

**Output**

報告完成後：
- 全部 PASS：「All changes pass sync validation. Safe to archive.」
- 有 CRITICAL：「X critical issue(s) found. Fix before archiving.」並列出具體修正步驟
- 僅 WARNING：「No critical issues. Y warning(s) to review. Safe to archive with noted caveats.」

**Guardrails**
- 此指令為唯讀（Read-only），不修改任何檔案
- 不自動修正問題，僅報告和建議
- 若 main spec 不存在（新 capability），ADDED 不視為衝突
- 若 delta spec 無 MODIFIED/REMOVED/RENAMED 區塊，該 capability 自動 PASS
