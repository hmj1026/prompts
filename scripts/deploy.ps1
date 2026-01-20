<# 
.SYNOPSIS
    Prompts Repository 部署腳本 (PowerShell)
.DESCRIPTION
    透過 symlink 將資源部署到用戶或專案目錄
.EXAMPLE
    .\deploy.ps1 -User
.EXAMPLE
    .\deploy.ps1 -Project myProject
.EXAMPLE
    .\deploy.ps1 -User -Force
#>

param(
    [switch]$User,
    [string]$Project,
    [switch]$Force,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# 設定路徑
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PromptsRoot = Split-Path -Parent $ScriptDir

# 載入 .env
$EnvFile = Join-Path $PromptsRoot ".env"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^([^#=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim().Trim('"').Trim("'")
            Set-Variable -Name $name -Value $value -Scope Script
        }
    }
} else {
    Write-Error "錯誤: 找不到 .env 檔案。請複製 .env.example 為 .env 並設定路徑"
    exit 1
}

function Show-Usage {
    Write-Host @"
使用方式:
    .\deploy.ps1 -User              部署用戶級別資源
    .\deploy.ps1 -Project <名稱>    部署專案級別資源
    .\deploy.ps1 -Force             強制覆蓋既有連結

範例:
    .\deploy.ps1 -User
    .\deploy.ps1 -Project myProject
    .\deploy.ps1 -User -Force
"@
}

function New-Symlink {
    param(
        [string]$Source,
        [string]$Target,
        [bool]$ForceOverwrite
    )
    
    # 確保來源存在
    if (-not (Test-Path $Source)) {
        Write-Warning "來源不存在: $Source"
        return $false
    }
    
    # 確保目標父目錄存在
    $TargetParent = Split-Path -Parent $Target
    if (-not (Test-Path $TargetParent)) {
        New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null
    }
    
    # 處理既有連結或檔案
    if (Test-Path $Target) {
        if ($ForceOverwrite) {
            Remove-Item -Path $Target -Force -Recurse
            Write-Host "已移除既有: $Target"
        } else {
            Write-Host "跳過 (已存在): $Target"
            return $true
        }
    }
    
    # 判斷是目錄還是檔案
    $IsDirectory = (Get-Item $Source).PSIsContainer
    
    # 建立 symlink (需要管理員權限或開發者模式)
    try {
        if ($IsDirectory) {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
        } else {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
        }
        Write-Host "已建立連結: $Target -> $Source"
        return $true
    } catch {
        Write-Error "建立 symlink 失敗: $_"
        Write-Host "提示: 請以管理員身份執行或啟用 Windows 開發者模式"
        return $false
    }
}

function Deploy-User {
    param([bool]$ForceOverwrite)
    
    Write-Host "=== 部署用戶級別資源 ===" -ForegroundColor Cyan
    
    $GeminiSource = Join-Path $PromptsRoot "user\.gemini"
    $GeminiTarget = Join-Path $USER_HOME ".gemini"
    
    # Skills
    $SkillsSource = Join-Path $GeminiSource ".agent\skills"
    if (Test-Path $SkillsSource) {
        Get-ChildItem -Path $SkillsSource -Directory | ForEach-Object {
            $SkillTarget = Join-Path $GeminiTarget ".agent\skills\$($_.Name)"
            New-Symlink -Source $_.FullName -Target $SkillTarget -ForceOverwrite $ForceOverwrite
        }
    }
    
    # Workflows
    $WorkflowsSource = Join-Path $GeminiSource ".agent\workflows"
    if (Test-Path $WorkflowsSource) {
        Get-ChildItem -Path $WorkflowsSource -File | ForEach-Object {
            $WorkflowTarget = Join-Path $GeminiTarget ".agent\workflows\$($_.Name)"
            New-Symlink -Source $_.FullName -Target $WorkflowTarget -ForceOverwrite $ForceOverwrite
        }
    }
    
    # GEMINI.md
    $GeminiMd = Join-Path $GeminiSource "GEMINI.md"
    if (Test-Path $GeminiMd) {
        $TargetMd = Join-Path $GeminiTarget "GEMINI.md"
        New-Symlink -Source $GeminiMd -Target $TargetMd -ForceOverwrite $ForceOverwrite
    }
    
    Write-Host "=== 用戶級別部署完成 ===" -ForegroundColor Green
}

function Deploy-Project {
    param(
        [string]$ProjectName,
        [bool]$ForceOverwrite
    )
    
    Write-Host "=== 部署專案級別資源: $ProjectName ===" -ForegroundColor Cyan
    
    # 取得專案路徑
    $ProjectVar = "PROJECT_$ProjectName"
    $ProjectPath = Get-Variable -Name $ProjectVar -ValueOnly -ErrorAction SilentlyContinue
    
    if (-not $ProjectPath) {
        Write-Error "錯誤: 未在 .env 中設定專案 $ProjectName 的路徑"
        exit 1
    }
    
    $ProjectSource = Join-Path $PromptsRoot "projects\$ProjectName"
    
    if (-not (Test-Path $ProjectSource)) {
        Write-Error "錯誤: 專案來源目錄不存在 - $ProjectSource"
        exit 1
    }
    
    # Skills
    $SkillsSource = Join-Path $ProjectSource ".agent\skills"
    if (Test-Path $SkillsSource) {
        Get-ChildItem -Path $SkillsSource -Directory | ForEach-Object {
            $SkillTarget = Join-Path $ProjectPath ".agent\skills\$($_.Name)"
            New-Symlink -Source $_.FullName -Target $SkillTarget -ForceOverwrite $ForceOverwrite
        }
    }
    
    # Workflows
    $WorkflowsSource = Join-Path $ProjectSource ".agent\workflows"
    if (Test-Path $WorkflowsSource) {
        Get-ChildItem -Path $WorkflowsSource -File | ForEach-Object {
            $WorkflowTarget = Join-Path $ProjectPath ".agent\workflows\$($_.Name)"
            New-Symlink -Source $_.FullName -Target $WorkflowTarget -ForceOverwrite $ForceOverwrite
        }
    }
    
    # GEMINI.md / CLAUDE.md / AGENTS.md
    @("GEMINI.md", "CLAUDE.md", "AGENTS.md") | ForEach-Object {
        $SourceFile = Join-Path $ProjectSource $_
        if (Test-Path $SourceFile) {
            $TargetFile = Join-Path $ProjectPath $_
            New-Symlink -Source $SourceFile -Target $TargetFile -ForceOverwrite $ForceOverwrite
        }
    }
    
    Write-Host "=== 專案級別部署完成: $ProjectName ===" -ForegroundColor Green
}

# 主程式
if ($Help) {
    Show-Usage
    exit 0
}

if (-not $User -and -not $Project) {
    Write-Error "錯誤: 請指定 -User 或 -Project"
    Show-Usage
    exit 1
}

if ($User) {
    Deploy-User -ForceOverwrite $Force
}

if ($Project) {
    Deploy-Project -ProjectName $Project -ForceOverwrite $Force
}
