# Interactive pattern-matching demo (simulated CPU).
#
# Usage:  .\run_pattern_match.ps1
# You type the text and the pattern; they are played as UART keystrokes
# into the RV32 core running sw/demos/string_match_interactive.c in xsim,
# and the step-by-step matching trace the CPU prints comes back here.
# Empty text quits. First run compiles the simulation snapshot (~30 s);
# after that each round only costs the simulation itself.

$repo  = "c:\Users\nayak\Desktop\riscv32-processor"
$vbin  = "C:\AMDDesignTools\2025.2\Vivado\bin"
$build = Join-Path $repo "results\xsim_pattern_match"

New-Item -ItemType Directory -Force $build | Out-Null
Set-Location $build

if (-not (Test-Path "xsim.dir\tb_string_match_snap")) {
    Write-Host "Building simulation snapshot (one-time)..." -ForegroundColor Cyan
    $srcdir = "$repo\riscv_pipeline_offline\riscv_pipeline_offline.srcs\sources_1\imports\src"
    $tb     = "$repo\riscv_pipeline_offline\riscv_pipeline_offline.srcs\sim_1\imports\sim\tb_string_match.sv"
    $src    = Get-ChildItem "$srcdir\*.sv" | Select-Object -ExpandProperty FullName
    & "$vbin\xvlog.bat" -sv @($src) $tb | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "xvlog failed" -ForegroundColor Red; exit 1 }
    & "$vbin\xelab.bat" --timescale 1ns/1ps tb_string_match -snapshot tb_string_match_snap | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "xelab failed" -ForegroundColor Red; exit 1 }
}

while ($true) {
    Write-Host ""
    $text = Read-Host "Text     (1-39 printable chars, empty to quit)"
    if ($text -eq "") { break }
    $pat  = Read-Host "Pattern  (1-11 chars, not longer than text)"

    if ($text.Length -gt 39 -or $pat.Length -lt 1 -or $pat.Length -gt 11 -or $pat.Length -gt $text.Length) {
        Write-Host "Invalid lengths: text 1-39 chars, pattern 1-11 and <= text." -ForegroundColor Yellow
        continue
    }
    if (($text + $pat) -match '[^\x20-\x7E]') {
        Write-Host "Printable ASCII only." -ForegroundColor Yellow
        continue
    }

    Write-Host ""
    # Inputs go via file — spaces survive, no Windows quoting issues
    Set-Content -Path "pm_input.txt" -Value @($text, $pat) -Encoding ascii
    & "$vbin\xsim.bat" tb_string_match_snap -R |
        Where-Object { $_ -notmatch '^(INFO|WARNING|source |run |Time res|\*\*\*\* |\s*\*\* |exit|\$finish|xsim\b|# )' -and $_ -notmatch '^\*\*\*\*\*\*' }
}
