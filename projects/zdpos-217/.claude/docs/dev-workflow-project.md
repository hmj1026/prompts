# Dev Workflow — Project Override (zdpos_dev)

Project pack for `dhpk:adaptive-dev-workflow` / `/dhpk:create-dev`. The generic skill ships
in the dhpk plugin; this file (read as `@rules/dev-workflow-project.md`) supplies zdpos_dev's
prefills, shortcut, path→test hints, and examples. Only read it when the generic workflow needs
repo-specific values; otherwise stay on the plugin's generic guidance.

## Repo Overrides

先以 `CLAUDE.md` 為準。`zdpos_dev` 已宣告：

- `language/runtime`
- `architecture_style`
- `test_strategy`
- `work_item_system`

因此 `profile.yaml` 通常只需補：

- `target_upgrade_version`
- `dependency_policy`

## Profile Shortcut

```bash
SCRIPTS="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}/skills/adaptive-dev-workflow/scripts"
python3 "$SCRIPTS/prepare_workflow_profile.py" \
  --language "PHP" \
  --runtime "5.6.40" \
  --current-version "5.6" \
  --target-version "8.3" \
  --architecture "DDD-like (Yii 1.1)" \
  --test-strategy "test-first (PHPUnit 5.7)" \
  --style "PSR-2, PHPDoc, no type hints" \
  --dependency-policy "built-in first, existing vendors, no new deps without ROI" \
  --work-item-system "openspec"
```

OpenSpec apply-ready 後，handoff 目標是 `/opsx:apply`。

## Path → Test Hints

`prepare_dev_scope.py` 的通用版本不內建路徑啟發式；在 zdpos_dev，依異動路徑套用下列 test hints：

- `protected/controllers/` → run affected controller/unit tests
- `domain/` → run domain unit tests
- `infrastructure/` → run repository + integration-related tests
- `js/` → run manual smoke for impacted pages

## Examples

### Example 1: New Refund API
- 情境：Yii 1.1 / PHP 5.6 新增第三方支付退款 API
- workflow：`Feature Delivery`
- 重點：先補 profile / scope / OpenSpec gate / RED，再 hand off 到 `/opsx:apply`

### Example 2: Duplicate Charge Bug
- 情境：POS 結帳偶發重複扣款，根因未明
- workflow：`Bug Investigation & Fix`
- 重點：缺 profile 不單獨擋住流程；先收斂證據、work-item、legacy、regression path

### Example 3: Constant Extraction
- 情境：`js/checkout/helpers.js` 抽常數，不改行為
- workflow：`Lightweight Maintenance`
- 重點：跳過 heavy artifacts，保留 targeted verification 與 `dhpk:code-reviewer`
