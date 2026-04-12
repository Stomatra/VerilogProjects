# ============================================================
# Vivado 2018 仿真集成脚本
# 作者: Stomatra
# 功能: 自动创建 Vivado 项目并运行仿真
# 使用: .\vivado_run.ps1 [-Create] [-RunSim] [-HexFile "tests/addi.hex"]
# ============================================================

param(
    [Parameter(Mandatory=$false)]
    [switch]$Create = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunSim = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$HexFile = "rv32/tests/addi.hex",
    
    [Parameter(Mandatory=$false)]
    [switch]$GUI = $false
)

# ========================================
# 配置
# ========================================
$vivadoVersion = "2018.3"  # 修改为你的 Vivado 版本
$projectName = "rv32_sim"
$projectDir = "vivado_project"
$rtlDir = "rv32/rtl"
$tbDir = "rv32/tb"

# ========================================
# 函数: 打印彩色信息
# ========================================
function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Color
    Write-Host "  $Message" -ForegroundColor $Color
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

# ========================================
# 检查 Vivado 安装
# ========================================
Write-Step "检查 Vivado 安装" "Cyan"

$vivado = Get-Command vivado -ErrorAction SilentlyContinue
if (-not $vivado) {
    Write-Error-Custom "未找到 Vivado！"
    Write-Host "请确保 Vivado 已安装并添加到 PATH" -ForegroundColor Gray
    Write-Host "可能需要运行: source <Vivado_Install_Dir>/settings64.sh (Linux/WSL)"
    Write-Host "或者:          <Vivado_Install_Dir>\settings64.bat (Windows CMD)"
    exit 1
}

# 获取 Vivado 版本
try {
    $output = & vivado -version 2>&1
    Write-Success "找到 Vivado: $output"
} catch {
    Write-Error-Custom "无法获取 Vivado 版本"
    exit 1
}

# ========================================
# 创建项目（如果需要）
# ========================================
if ($Create) {
    Write-Step "创建 Vivado 项目" "Cyan"
    
    # 生成创建脚本
    $createScript = @"
set project_name "$projectName"
set project_dir "$projectDir"
set rtl_dir "$rtlDir"
set tb_dir "$tbDir"

if {[file exists `$project_dir]} {
    puts "删除旧项目..."
    file delete -force `$project_dir
}

puts "创建项目: `$project_name"
create_project `$project_name `$project_dir -part xc7z020clg484-1

puts "添加源文件..."
add_files -fileset sources_1 \
    `$rtl_dir/rv32_pkg.vh \
    `$rtl_dir/rv32_alu.v \
    `$rtl_dir/rv32_branch.v \
    `$rtl_dir/rv32_decode.v \
    `$rtl_dir/rv32_imm.v \
    `$rtl_dir/rv32_mem_if.v \
    `$rtl_dir/rv32_regfile.v \
    `$rtl_dir/rv32_core.v \
    `$rtl_dir/rv32_top.v

puts "添加仿真源文件..."
add_files -fileset sim_1 `$tb_dir/tb_rv32.v

set_property top tb_rv32 [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property include_dirs `$rtl_dir [get_filesets sim_1]

save_project_as `$project_name `$project_dir -force

puts "✅ 项目创建完成"
"@
    
    # 保存脚本到临时文件
    $tempScript = "temp_vivado_create.tcl"
    Set-Content -Path $tempScript -Value $createScript
    
    # 执行脚本
    Write-Host "   执行 vivado -mode batch -source $tempScript" -ForegroundColor Gray
    & vivado -mode batch -source $tempScript -log vivado_create.log -journal vivado_create.jou
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "项目创建失败，查看 vivado_create.log"
        exit 1
    }
    
    Write-Success "项目创建成功"
    Remove-Item -Path $tempScript -Force
}

# ========================================
# 运行仿真
# ========================================
if ($RunSim) {
    Write-Step "运行仿真" "Cyan"
    
    # 检查项目是否存在
    if (-not (Test-Path "$projectDir/$projectName.xpr")) {
        Write-Error-Custom "项目文件不存在！"
        Write-Host "请先运行: .\vivado_run.ps1 -Create" -ForegroundColor Yellow
        exit 1
    }
    
    # 检查 hex 文件
    if (-not (Test-Path $HexFile)) {
        Write-Error-Custom "hex 文件不存在: $HexFile"
        exit 1
    }
    
    Write-Info "hex 文件: $HexFile"
    
    # 生成仿真运行脚本
    $simScript = @"
open_project $projectDir/$projectName.xpr

# 编译和启动仿真
puts "启动仿真..."
launch_simulation -simset sim_1 -mode behavioral

# 等待仿真窗口完全载入
after 3000

# 运行测试
puts "运行仿真: 5000ns"
run all

# 等待运行完成
after 1000

# 保存波形
puts "导出波形..."
write_vcd -scope tb_rv32 sim_tb_rv32.vcd

# 关闭
puts "✅ 仿真完成"
close_sim
close_project
"@
    
    $tempSim = "temp_vivado_run.tcl"
    Set-Content -Path $tempSim -Value $simScript
    
    Write-Host "   执行 vivado -mode batch -source $tempSim" -ForegroundColor Gray
    & vivado -mode batch -source $tempSim -log vivado_sim.log -journal vivado_sim.jou
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "仿真可能出现问题，查看 vivado_sim.log"
    }
    
    Write-Success "仿真运行完成"
    Remove-Item -Path $tempSim -Force
    
    Write-Info "日志文件:"
    Write-Host "   vivado_sim.log" -ForegroundColor Gray
}

# ========================================
# 打开 GUI
# ========================================
if ($GUI) {
    Write-Step "打开 Vivado GUI" "Cyan"
    
    if (-not (Test-Path "$projectDir/$projectName.xpr")) {
        Write-Error-Custom "项目文件不存在"
        exit 1
    }
    
    Write-Host "   启动 Vivado GUI..." -ForegroundColor Gray
    Start-Process vivado -ArgumentList "$projectDir/$projectName.xpr"
    
    Write-Info "Vivado 已启动（后台运行）"
}

# ========================================
# 使用说明
# ========================================
if (-not ($Create -or $RunSim -or $GUI)) {
    Write-Host ""
    Write-Host "Vivado 2018 仿真集成脚本" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "使用方法:" -ForegroundColor White
    Write-Host ""
    Write-Host "  第一次使用（创建项目）:" -ForegroundColor Yellow
    Write-Host "    .\vivado_run.ps1 -Create" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  运行仿真:" -ForegroundColor Yellow
    Write-Host "    .\vivado_run.ps1 -RunSim" -ForegroundColor Gray
    Write-Host "    .\vivado_run.ps1 -RunSim -HexFile tests/addi.hex" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  打开 GUI:" -ForegroundColor Yellow
    Write-Host "    .\vivado_run.ps1 -GUI" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  完整流程:" -ForegroundColor Yellow
    Write-Host "    .\vivado_run.ps1 -Create -GUI" -ForegroundColor Gray
    Write-Host ""
    Write-Host "参数说明:" -ForegroundColor White
    Write-Host "  -Create      创建 Vivado 项目" -ForegroundColor Gray
    Write-Host "  -RunSim      运行仿真" -ForegroundColor Gray
    Write-Host "  -GUI         打开 Vivado GUI" -ForegroundColor Gray
    Write-Host "  -HexFile     指定 hex 文件路径（默认: tests/addi.hex）" -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""
