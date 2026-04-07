# Common Patterns

## Skeleton Projects

新功能實作時：先搜尋 battle-tested skeleton → 平行 agent 評估 → clone 最佳匹配 → 迭代。

## Design Patterns

| Pattern | 核心原則 | 規則 |
|---------|---------|------|
| **Repository** | 資料存取封裝（findAll, findById, create, update, delete） | 業務邏輯依賴抽象介面，非 storage |
| **Fluent Interface** | Return `this`/new instance，terminal method 產生結果 | 每個 chained method 做一件事 |
| **Pipeline** | 線性序列取代巢狀呼叫 | 每步是 pure function (input→output) |
| **Options Object** | 3+ 參數或 boolean flags 改用 options object | 提供 sensible defaults |
| **Lazy Evaluation** | 建構描述不執行，terminal method 才執行 | 明確區分 lazy/terminal methods |
| **API Response** | 統一信封：success + data + message + metadata | 所有端點一致格式 |

> 完整 code examples 見 `.claude/docs/pattern-examples.md`
