#!/usr/bin/env pwsh
param([switch]$NoElevate)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Repo = $PSScriptRoot
if ([string]::IsNullOrEmpty($Repo)) { Write-Host "✗ 無法解析 repo 根目錄。"; exit 1 }

$HomeRoot = if ($env:DUAL_AGENT_INSTALL_HOME) { $env:DUAL_AGENT_INSTALL_HOME } else { $HOME }
$CodexDir = Join-Path $HomeRoot '.codex'
$ClaudeDir = Join-Path $HomeRoot '.claude'
$AgentsDir = Join-Path $HomeRoot '.agents'
$ConfigDir = Join-Path $HomeRoot '.config'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:Failed = 0

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltinRole]::Administrator)
$devMode = $false
try {
  $key = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
    -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction Stop
  $devMode = [bool]$key.AllowDevelopmentWithoutDevLicense
} catch { $devMode = $false }

if (-not $isAdmin -and -not $devMode) {
  if ($NoElevate) {
    Write-Host "⚠️  請開啟開發人員模式後重試。"
    Start-Process 'ms-settings:developers'
    exit 1
  }
  $hostExe = (Get-Process -Id $PID).Path
  if (-not $hostExe) { $hostExe = 'powershell.exe' }
  $argLine = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`""
  try {
    Start-Process -FilePath $hostExe -Verb RunAs -ArgumentList $argLine
    Write-Host "→ 已在管理員視窗繼續安裝。"
  } catch { Write-Host "✗ 提權被取消或失敗。" }
  exit
}

function Make-Link {
  param([string]$Src, [string]$Dest)
  if (-not (Test-Path -LiteralPath $Src)) {
    Write-Host "  ✗ 來源不存在：$Src"
    $script:Failed++
    return
  }
  try {
    $parent = Split-Path -Parent $Dest
    if (-not (Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $existing = Get-Item -LiteralPath $Dest -Force -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
      if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        $currentTarget = $null
        if ($existing.Target) { $currentTarget = @($existing.Target)[0] }
        if ($currentTarget -eq $Src) {
          $existing.Delete()
        } else {
          Move-Item -LiteralPath $Dest -Destination "$Dest.backup-$Stamp"
          Write-Host "  ⚑ 已備份既有連結。"
        }
      } else {
        Move-Item -LiteralPath $Dest -Destination "$Dest.backup-$Stamp"
        Write-Host "  ⚑ 已備份既有檔案。"
      }
    }

    New-Item -ItemType SymbolicLink -Path $Dest -Target $Src | Out-Null
    Write-Host "  ✓ $Dest -> $Src"
  } catch {
    Write-Host "  ✗ 建立 symlink 失敗：$Dest`n    $($_.Exception.Message)"
    $script:Failed++
  }
}

Write-Host "Repo：$Repo"
Write-Host "家目錄：$HomeRoot"
Make-Link (Join-Path $Repo 'skills') (Join-Path $AgentsDir 'skills')
Make-Link (Join-Path $Repo 'skills') (Join-Path $ClaudeDir 'skills')
Make-Link (Join-Path $Repo 'shared/hooks') (Join-Path $CodexDir 'hooks')
Make-Link (Join-Path $Repo 'codex/hooks/hooks.json') (Join-Path $CodexDir 'hooks.json')
Make-Link (Join-Path $Repo 'codex/AGENTS.md') (Join-Path $CodexDir 'AGENTS.md')
Make-Link (Join-Path $Repo 'shared/hooks') (Join-Path $ClaudeDir 'hooks')
Make-Link (Join-Path $Repo 'claude/settings.json') (Join-Path $ClaudeDir 'settings.json')
Make-Link (Join-Path $Repo 'claude/CLAUDE.md') (Join-Path $ClaudeDir 'CLAUDE.md')
Make-Link (Join-Path $Repo 'claude/output-styles') (Join-Path $ClaudeDir 'output-styles')
Make-Link (Join-Path $Repo 'claude/ccstatusline/settings.json') (Join-Path $ConfigDir 'ccstatusline/settings.json')

if ($script:Failed -eq 0) { Write-Host "✅ Codex 與 Claude Code 設定安裝完成。" }
else { Write-Host "⚠️  有 $($script:Failed) 項安裝失敗。"; exit 1 }
