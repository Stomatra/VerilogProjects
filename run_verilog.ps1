param (
    [string]$Project = 'rv32',
    [string]$Hex,
    [string]$Tb = 'tb/tb_rv32.v',
    [switch]$Clean,
    [switch]$NoWaveform
)

# Change to project directory
Set-Location $Project

# Ensure sim directory exists
if (-not (Test-Path -Path 'sim')) {
    New-Item -ItemType Directory -Path 'sim'
}

# Compile the design
$files = Get-ChildItem 'rtl\*.v'
iverilog -g2012 -o 'sim\tb_rv32.vvp' -I rtl $files.FullName, $Tb
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Compilation error. Exiting with code 1.'
    exit 1
}

# Run the simulation
$runArgs = 'sim\tb_rv32.vvp'
if ($Hex) {
    $runArgs += " +hex=$Hex"
}

vvp $runArgs

# Check for no waveform requirement
if (-not $NoWaveform) {
    if (Test-Path 'sim\tb_rv32.vcd' -and (Get-Command gtkwave -ErrorAction SilentlyContinue)) {
        Start-Process gtkwave 'sim\tb_rv32.vcd'
    }
}

# Exit with 0 on PASS, 1 on FAIL/TIMEOUT/compile error
if ($LASTEXITCODE -eq 0) {
    exit 0
} else {
    exit 1
}