#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Checks whether documentation is stale relative to project source files.
  Returns exit code 0 if docs are fresh, 1 if docs are stale.

.DESCRIPTION
  Compares the modification time of the most recently changed source file
  against the most recent session log and key doc targets. If ANY source
  file is newer than the session log, the check fails.

  This script should be run:
    - By the git pre-commit hook (block commits with stale docs)
    - By any AI agent BEFORE claiming a task is complete
    - By the user before pushing to remote

.PARAMETER Strict
  When set, also requires that the session log itself was written AFTER
  the last source modification (not just that docs exist).

.EXAMPLE
  .\tools\check_docs_stale.ps1
  .\tools\check_docs_stale.ps1 -Strict
#>

param(
    [switch] $Strict
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# ---------------------------------------------------------------
# Directories to scan for source changes
# ---------------------------------------------------------------
$SourceRoots = @(
    "$ProjectRoot/riscv_pipeline_offline/riscv_pipeline_offline.srcs/sources_1/imports/src",
    "$ProjectRoot/riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1",
    "$ProjectRoot/riscv_pipeline_offline/riscv_pipeline_offline.srcs/constrs_1"
)

$ToolDir = "$ProjectRoot/tools"
$DocsDir  = "$ProjectRoot/Docs"
$UpdatesDir = "$DocsDir/updates"

# ---------------------------------------------------------------
# Key doc files that MUST be fresh
# ---------------------------------------------------------------
$RequiredDocs = @(
    "$DocsDir/ai_context.md",
    "$DocsDir/roadmap.md"
)

# ---------------------------------------------------------------
# Finding the latest source file modification time
# ---------------------------------------------------------------
$latestSourceTime = [DateTime]::MinValue
$latestSourceFile = ""

$searchPaths = $SourceRoots + @($ToolDir)
foreach ($root in $searchPaths) {
    if (-not (Test-Path $root)) { continue }
    $files = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '\.(sv|py|ps1|tcl|xdc|mem)$' }
    foreach ($f in $files) {
        if ($f.LastWriteTime -gt $latestSourceTime) {
            $latestSourceTime = $f.LastWriteTime
            $latestSourceFile = $f.FullName
        }
    }
}

if (-not $latestSourceFile) {
    Write-Host "CHECK_DOCS: No source files found. Skipping check."
    exit 0
}

Write-Host "CHECK_DOCS: Latest source change: $latestSourceFile"
Write-Host "CHECK_DOCS:   at $($latestSourceTime.ToString('yyyy-MM-dd HH:mm:ss'))"

# ---------------------------------------------------------------
# Finding the latest session log
# ---------------------------------------------------------------
$latestSessionTime = [DateTime]::MinValue
$latestSessionFile = ""

if (Test-Path $UpdatesDir) {
    $logFiles = Get-ChildItem -Path $UpdatesDir -File -Filter "session_*.md" -ErrorAction SilentlyContinue
    foreach ($f in $logFiles) {
        if ($f.LastWriteTime -gt $latestSessionTime) {
            $latestSessionTime = $f.LastWriteTime
            $latestSessionFile = $f.FullName
        }
    }
}

if (-not $latestSessionFile) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " CHECK FAILED: NO SESSION LOGS FOUND    " -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Every agent session MUST write a log to docs/updates/session_YYYY-MM-DD_HHMM_<name>.md"
    Write-Host "Run:  New-Item docs/updates/session_$(Get-Date -Format 'yyyy-MM-dd_HHmm')_agent.md"
    Write-Host ""
    exit 1
}

Write-Host "CHECK_DOCS: Latest session log: $latestSessionFile"
Write-Host "CHECK_DOCS:   at $($latestSessionTime.ToString('yyyy-MM-dd HH:mm:ss'))"

# ---------------------------------------------------------------
# Check: is the session log newer than the latest source change?
# ---------------------------------------------------------------
if ($latestSessionTime -lt $latestSourceTime) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " CHECK FAILED: DOCS ARE STALE           " -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Source file:  $latestSourceFile"
    Write-Host "  modified:   $($latestSourceTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "Session log:  $latestSessionFile"
    Write-Host "  modified:   $($latestSessionTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host ""
    Write-Host "MANDATORY: Before committing or claiming completion:"
    Write-Host "  1. Update docs/ai_context.md, docs/roadmap.md"
    Write-Host "  2. Write a new session log to docs/updates/"
    Write-Host "  3. Append the log link to docs/updates/README.md"
    Write-Host "  4. Run this script again to verify"
    Write-Host ""
    exit 1
}

# ---------------------------------------------------------------
# Check: are the required doc files newer than last session?
# (Session log should be the LAST thing written)
# ---------------------------------------------------------------
foreach ($doc in $RequiredDocs) {
    if (Test-Path $doc) {
        $docTime = (Get-Item $doc).LastWriteTime
        if ($docTime -gt $latestSessionTime) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host " WARNING: $($doc.Split('/')[-1]) is newer than session log" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host " The session log should be the LAST file written in a session."
            Write-Host " Consider updating the session log timestamp or content."
            Write-Host ""
            # Non-fatal warning
        }
        Write-Host "CHECK_DOCS: $($doc.Split('/')[-1]) -- last updated $($docTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    }
}

# ---------------------------------------------------------------
# Check: is the latest session log indexed in docs/updates/README.md?
# ---------------------------------------------------------------
$readmePath = "$UpdatesDir/README.md"
if (Test-Path $readmePath) {
    $logFileName = Split-Path -Leaf $latestSessionFile
    $readmeContent = Get-Content $readmePath -Raw
    if ($readmeContent -notmatch [regex]::Escape($logFileName)) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host " CHECK FAILED: SESSION LOG NOT INDEXED  " -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Latest session log '$logFileName' is not linked in docs/updates/README.md"
        Write-Host "Add a line to docs/updates/README.md referencing this log."
        Write-Host ""
        exit 1
    }
    Write-Host "CHECK_DOCS: Session log indexed in docs/updates/README.md" -ForegroundColor Cyan
}

# ---------------------------------------------------------------
# All checks passed
# ---------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " CHECK PASSED: DOCS ARE FRESH            " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
exit 0
