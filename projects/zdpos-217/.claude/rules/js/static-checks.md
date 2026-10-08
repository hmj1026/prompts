---
paths:
  - "**/*.{js,jsx,mjs,cjs,ts,tsx}"
---

# JS 靜態檢查防線 SSOT (index)

OpenSpec change: `modernize-zpos-js-static-checks`
Capability: `zpos-static-check-gate`

## 工具鏈

| 工具 | 設定檔 | npm script | Enforce 點（block on error） |
|---|---|---|---|
| ESLint 9 flat config | `eslint.config.js` | `npm run lint` | 本地 commit-time：dhpk js module `pre-commit-js-validation.sh`（攔 `git commit`）。**尚無 server 端 CI**（`.github/workflows/` 目前為空） |
| TypeScript（noEmit） | `tsconfig.json` | `npm run typecheck` | 同上 commit-time hook（block on error）。**尚無 server 端 CI** |

> 註：團隊尚未導入 CI，刻意不在 `.github/workflows/` 放 workflow（會對所有人觸發 GitHub Actions）。防線目前為「本地 edit-time + commit-time hook」；若日後導入 CI，回填本表並把 `.github/workflows/ci.yml` 的 step 名稱補上。

## Edit-time feedback

由 **dhpk js module** 負責：JS/TS edit 後 `modules/js/hooks/post-edit-js-lint.sh`（經 post-edit-dispatch 背景跑）即時 ESLint；commit time 由 `modules/js/hooks/pre-commit-js-validation.sh`（經 pre-bash-dispatch 的 git commit 預過濾）把關。npm script 名稱可經 `js_lint_script` / `js_typecheck_script` userConfig 覆寫。

## Hook 端 vendor / core 判定

SSOT 在 dhpk js module 的 `modules/js/hooks/_lib/js-tier-detect.sh`（`detect_js_tier()`）；需與 ESLint Global ignores 與 Tier 1.5 core 白名單保持一致（新增 vendor 路徑 / 新加 core 檔，兩處同步）。

## Progressive-loaded references

| 場景 | Skill |
|---|---|
| eslint tier／新檔落哪一層 | skill `zdpos-js-lint-config` |
| @ts-check per-leaf cleanup | skill `zdpos-js-static-check-strategy` |
| 改 leaf 業務邏輯 | rule `.claude/rules/frontend.md` |
