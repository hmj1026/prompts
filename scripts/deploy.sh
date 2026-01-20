#!/bin/bash
# Prompts Repository 部署腳本 (Bash)
# 透過 symlink 將資源部署到用戶或專案目錄

set -e

# 載入 .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROMPTS_ROOT/.env" ]; then
    source "$PROMPTS_ROOT/.env"
else
    echo "錯誤: 找不到 .env 檔案" >&2
    echo "請複製 .env.example 為 .env 並設定路徑" >&2
    exit 1
fi

# 顯示使用說明
usage() {
    echo "使用方式:"
    echo "  $0 --user              部署用戶級別資源"
    echo "  $0 --project <名稱>    部署專案級別資源"
    echo "  $0 --force             強制覆蓋既有連結"
    echo ""
    echo "範例:"
    echo "  $0 --user"
    echo "  $0 --project <project_name>"
    echo "  $0 --user --force"
}

# 建立 symlink (支援目錄和檔案)
create_symlink() {
    local source="$1"
    local target="$2"
    local force="$3"

    # 確保來源存在
    if [ ! -e "$source" ]; then
        echo "警告: 來源不存在 - $source" >&2
        return 1
    fi

    # 確保目標父目錄存在
    mkdir -p "$(dirname "$target")"

    # 處理既有連結或檔案
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ "$force" = "true" ]; then
            rm -rf "$target"
            echo "已移除既有: $target"
        else
            echo "跳過 (已存在): $target"
            return 0
        fi
    fi

    # 建立 symlink
    ln -s "$source" "$target"
    echo "已建立連結: $target -> $source"
}

# 部署用戶級別資源
deploy_user() {
    local force="$1"
    echo "=== 部署用戶級別資源 ==="
    
    # Gemini
    local gemini_source="$PROMPTS_ROOT/user/.gemini"
    local gemini_target="$USER_HOME/.gemini"
    
    # Skills
    for skill in "$gemini_source/.agent/skills"/*; do
        if [ -d "$skill" ]; then
            local name=$(basename "$skill")
            create_symlink "$skill" "$gemini_target/.agent/skills/$name" "$force"
        fi
    done
    
    # Workflows
    for workflow in "$gemini_source/.agent/workflows"/*; do
        if [ -f "$workflow" ]; then
            local name=$(basename "$workflow")
            create_symlink "$workflow" "$gemini_target/.agent/workflows/$name" "$force"
        fi
    done
    
    # GEMINI.md
    if [ -f "$gemini_source/GEMINI.md" ]; then
        create_symlink "$gemini_source/GEMINI.md" "$gemini_target/GEMINI.md" "$force"
    fi
    
    echo "=== 用戶級別部署完成 ==="
}

# 部署專案級別資源
deploy_project() {
    local project_name="$1"
    local force="$2"
    echo "=== 部署專案級別資源: $project_name ==="
    
    # 取得專案路徑
    local project_var="PROJECT_$project_name"
    local project_path="${!project_var}"
    
    if [ -z "$project_path" ]; then
        echo "錯誤: 未在 .env 中設定專案 $project_name 的路徑" >&2
        exit 1
    fi
    
    local project_source="$PROMPTS_ROOT/projects/$project_name"
    
    if [ ! -d "$project_source" ]; then
        echo "錯誤: 專案來源目錄不存在 - $project_source" >&2
        exit 1
    fi
    
    # Skills
    if [ -d "$project_source/.agent/skills" ]; then
        for skill in "$project_source/.agent/skills"/*; do
            if [ -d "$skill" ]; then
                local name=$(basename "$skill")
                create_symlink "$skill" "$project_path/.agent/skills/$name" "$force"
            fi
        done
    fi
    
    # Workflows
    if [ -d "$project_source/.agent/workflows" ]; then
        for workflow in "$project_source/.agent/workflows"/*; do
            if [ -f "$workflow" ]; then
                local name=$(basename "$workflow")
                create_symlink "$workflow" "$project_path/.agent/workflows/$name" "$force"
            fi
        done
    fi
    
    # GEMINI.md / CLAUDE.md / AGENTS.md
    for file in GEMINI.md CLAUDE.md AGENTS.md; do
        if [ -f "$project_source/$file" ]; then
            create_symlink "$project_source/$file" "$project_path/$file" "$force"
        fi
    done
    
    echo "=== 專案級別部署完成: $project_name ==="
}

# 主程式
FORCE="false"
MODE=""
PROJECT_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            MODE="user"
            shift
            ;;
        --project)
            MODE="project"
            PROJECT_NAME="$2"
            shift 2
            ;;
        --force)
            FORCE="true"
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "未知參數: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [ -z "$MODE" ]; then
    echo "錯誤: 請指定 --user 或 --project" >&2
    usage
    exit 1
fi

case $MODE in
    user)
        deploy_user "$FORCE"
        ;;
    project)
        if [ -z "$PROJECT_NAME" ]; then
            echo "錯誤: --project 需要指定專案名稱" >&2
            exit 1
        fi
        deploy_project "$PROJECT_NAME" "$FORCE"
        ;;
esac
