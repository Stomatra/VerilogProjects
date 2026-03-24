# run_all_tests.ps1
# Batch-run all RV32I instruction unit tests and print a PASS/FAIL report.
#
# Usage (from the rv32/ directory):
#   pwsh -File run_all_tests.ps1
#   # or in Windows PowerShell:
#   .\run_all_tests.ps1
#
# Requirements: iverilog + vvp in PATH (Icarus Verilog)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$SimDir   = "sim"
$VvpFile  = "$SimDir\tb_rv32.vvp"
$TestsDir = "tests"

if (!(Test-Path $SimDir)) { New-Item -ItemType Directory -Path $SimDir | Out-Null }

Write-Host "=============================================="
Write-Host " RV32I Instruction Unit Test Suite"
Write-Host "=============================================="
Write-Host ""

# ---- Compile ----
Write-Host "[INFO] Compiling testbench..."
$ivArgs = @("-g2012", "-o", $VvpFile, "-I", "rtl") +
          (Get-ChildItem rtl\*.v | ForEach-Object { $_.FullName }) +
          @("tb\tb_rv32.v")
& iverilog @ivArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "[ERROR] Compilation failed – aborting."
    exit 1
}
Write-Host "[INFO] Compilation OK"
Write-Host ""

# ---- Run tests ----
$pass    = 0
$fail    = 0
$timeout = 0
$failList = @()

Get-ChildItem "$TestsDir\*.hex" | Sort-Object Name | ForEach-Object {
    $name    = $_.BaseName
    $hexFile = $_.FullName

    $output  = & vvp $VvpFile "+hex=$hexFile" 2>$null
    $tbLine  = ($output | Select-String '\[TB\]' | Select-Object -Last 1).Line

    if ($tbLine -match "PASS") {
        Write-Host ("  {0,-12}  PASS" -f $name)
        $pass++
    } elseif ($tbLine -match "FAIL") {
        Write-Host ("  {0,-12}  FAIL  ({1})" -f $name, $tbLine)
        $fail++
        $failList += $name
    } else {
        Write-Host ("  {0,-12}  TIMEOUT" -f $name)
        $timeout++
        $failList += "$name(timeout)"
    }
}

$total = $pass + $fail + $timeout

Write-Host ""
Write-Host "=============================================="
Write-Host " Results: $pass/$total PASS"
if ($failList.Count -gt 0) {
    Write-Host (" Failed:  " + ($failList -join ", "))
}
Write-Host "=============================================="

if (($fail + $timeout) -gt 0) { exit 1 } else { exit 0 }
