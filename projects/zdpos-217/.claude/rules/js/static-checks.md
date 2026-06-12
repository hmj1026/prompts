# JS 靜態檢查防線 SSOT (index)

OpenSpec change: `modernize-zpos-js-static-checks`（Phase 1 ESLint + Phase 2 TypeScript noEmit 已落地；未來時機成熟後一次性全 ESM 重構為獨立 change）
Capability: `zpos-static-check-gate`

## 工具鏈

| 工具 | 設定檔 | npm script | CI gate |
|---|---|---|---|
| ESLint 9 flat config | `eslint.config.js` | `npm run lint` | `.github/workflows/ci.yml:eslint` (block on error) |
| TypeScript（noEmit） | `tsconfig.json` | `npm run typecheck` | `.github/workflows/ci.yml:eslint` 同 step (block on error) |

## Edit-time feedback

JS/TS edit 後由 `.claude/hooks/post-edit-js-lint.sh`（async PostToolUse）即時跑 ESLint，發現問題 stderr 提示；commit time 由 `.claude/hooks/pre-commit-js-validation.sh` 把關。

## Hook 端 vendor / core 判定

SSOT 在 `.claude/hooks/_lib/js-tier-detect.sh` 的 `detect_js_tier()`；需與 ESLint Global ignores 與 Tier 1.5 core 白名單保持一致（新增 vendor 路徑 / 新加 core 檔，兩處同步）。

## Progressive-loaded references

| 場景 | Skill |
|---|---|
| ESLint config tier 結構 / AST selector / `zdposLegacyGlobals` 白名單 / 進度衡量 grep | skill `zdpos-js-lint-config` |
| 規劃 per-leaf cleanup / 19 leaf 過渡分類 / grep gameable trap / Phase 2 exit gate 驗收 | skill `zdpos-js-static-check-strategy` |
| 改 leaf 業務邏輯（POS.* SSOT、AJAX wrapper、View-layer PHP→JS） | rule `.claude/rules/frontend.md` |

## 相關 spec

- `openspec/changes/modernize-zpos-js-static-checks/proposal.md`
- `openspec/changes/modernize-zpos-js-static-checks/design.md`（D1-D4 ESLint + TypeScript 靜態檢查決策）
- `openspec/changes/modernize-zpos-js-static-checks/specs/zpos-static-check-gate/spec.md`
- `openspec/changes/modernize-zpos-js-static-checks/tasks.md`
