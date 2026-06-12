#!/usr/bin/env bash
# js-tier-detect.sh — shared JS tier detection (zdpos_dev SSOT).
# Source-only — do not execute directly.
# Sourced by post-edit-remind.sh / post-edit-js-lint.sh (and any future
# hook needing the same vendor / core / subdirectory分流).
#
# Contract:
#   detect_js_tier "<relative_path>"
#   exports JS_TIER=<one of: "frontend" | "vendor" | "non-js">
#   exit code 0 always (caller checks $JS_TIER)
#
# Rules (依 .claude/rules/js/static-checks.md「Tier 1.5 core 檔豁免」+「Global ignores」):
#   - 子目錄 vendor 路徑 + js/admin/core/RecordTable.js → vendor
#   - 任何 js/*/* 子目錄 .js/.ts → frontend
#   - js/ 根目錄：在 ZPOS_CORE_FILES 白名單 → frontend；否則 → vendor
#   - 非 js/ 路徑或非 .js/.ts → non-js

# Tier 1.5 core 白名單 — 唯一從 js/ 根目錄被 frontend-reviewer 接收的 leaf
# 新加 zpos core 檔到根目錄請同步擴充此白名單。
ZPOS_CORE_FILES=("zpos.js" "zpos.v2.js" "mpos.js" "pos_core.js" "main.js")

detect_js_tier() {
    local rel="$1"
    local basename="${rel##*/}"
    JS_TIER="non-js"

    case "$rel" in
        js/ckeditor/*|js/ckfinder/*|js/jquery-*|js/dataTables.*|js/jqPlug/*|js/ubereats*/*|js/ueditor/*|js/utils/*|js/service*/*|js/omniorder/*|js/oss/*|js/modules/*|js/async/*|js/dashboard/*|js/admin/core/RecordTable.js)
            case "$basename" in
                *.js|*.ts) JS_TIER="vendor" ;;
            esac
            ;;
        js/*/*)
            case "$basename" in
                *.js|*.ts) JS_TIER="frontend" ;;
            esac
            ;;
        js/*)
            local is_core=0
            local core
            for core in "${ZPOS_CORE_FILES[@]}"; do
                [[ "$basename" == "$core" ]] && is_core=1 && break
            done
            case "$basename" in
                *.js|*.ts)
                    if [[ "$is_core" -eq 1 ]]; then
                        JS_TIER="frontend"
                    else
                        JS_TIER="vendor"
                    fi
                    ;;
            esac
            ;;
    esac
}
