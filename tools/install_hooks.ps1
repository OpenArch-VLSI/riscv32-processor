#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Installs git hooks for the RISC-V pipeline project.
  Run this once after git init or clone.
  chmod: Not needed on Windows; just run: .\tools\install_hooks.ps1
#>

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

$gitDir = "$ProjectRoot/.git"
if (-not (Test-Path $gitDir)) {
    Write-Host "No .git directory found. Run 'git init' first, then re-run this script."
    exit 1
}

$hooksDir = "$gitDir/hooks"
if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
}

# ---------------------------------------------------------------
# pre-commit hook
# ---------------------------------------------------------------
$preCommitPath = "$hooksDir/pre-commit"
@'
#!/bin/sh
# RISC-V Pipeline Project — Pre-commit Hook
# Blocks commit if documentation is stale.
# To bypass: git commit --no-verify

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CHECKER="$PROJECT_ROOT/tools/check_docs_stale.ps1"

if [ -f "$CHECKER" ]; then
    powershell -NoProfile -ExecutionPolicy Bypass -File "$CHECKER" -Strict
    if [ $? -ne 0 ]; then
        echo ""
        echo "COMMIT BLOCKED: Documentation is stale."
        echo "Update docs/ai_context.md, docs/roadmap.md, and write a session log."
        echo "Then try your commit again."
        echo ""
        exit 1
    fi
else
    echo "WARNING: check_docs_stale.ps1 not found. Bypassing doc check."
fi
exit 0
'@ | Set-Content -Path $preCommitPath -Encoding ASCII

Write-Host "Installed: $preCommitPath"

# ---------------------------------------------------------------
# post-commit hook (warns if session log still not written)
# ---------------------------------------------------------------
$postCommitPath = "$hooksDir/post-commit"
@'
#!/bin/sh
# RISC-V Pipeline Project — Post-commit Hook
# Warns if docs are still stale after a commit.

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CHECKER="$PROJECT_ROOT/tools/check_docs_stale.ps1"

if [ -f "$CHECKER" ]; then
    powershell -NoProfile -ExecutionPolicy Bypass -File "$CHECKER" -Strict
    if [ $? -ne 0 ]; then
        echo ""
        echo "WARNING: Docs are stale. Your commit went through, but"
        echo "please update documentation BEFORE your next commit."
        echo ""
    fi
fi
exit 0
'@ | Set-Content -Path $postCommitPath -Encoding ASCII

Write-Host "Installed: $postCommitPath"

# ---------------------------------------------------------------
# pre-push hook
# ---------------------------------------------------------------
$prePushPath = "$hooksDir/pre-push"
@'
#!/bin/sh
# RISC-V Pipeline Project — Pre-push Hook
# Blocks push if documentation is stale.
# To bypass: git push --no-verify

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CHECKER="$PROJECT_ROOT/tools/check_docs_stale.ps1"

if [ -f "$CHECKER" ]; then
    powershell -NoProfile -ExecutionPolicy Bypass -File "$CHECKER" -Strict
    if [ $? -ne 0 ]; then
        echo ""
        echo "PUSH BLOCKED: Documentation is stale."
        echo "Update docs/ai_context.md, docs/roadmap.md, and write a session log."
        echo "Then try your push again."
        echo ""
        exit 1
    fi
else
    echo "WARNING: check_docs_stale.ps1 not found. Bypassing doc check."
fi
exit 0
'@ | Set-Content -Path $prePushPath -Encoding ASCII

Write-Host "Installed: $prePushPath"

Write-Host ""
Write-Host "Git hooks installed. Documentation will be checked on every commit AND push." -ForegroundColor Green
Write-Host "To skip the check in an emergency:  git commit --no-verify   or   git push --no-verify"
