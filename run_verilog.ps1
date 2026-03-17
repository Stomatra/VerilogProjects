# ========================================
# Verilog 一键运行脚本
# 作者: Stomatra
# 功能: 自动编译、仿真、查看波形
# 使用: .\run_verilog.ps1 [testbench文件路径]
# ========================================

param(
    [Parameter(Mandatory=$false, HelpMessage="Testbench 文件路径")]
    [string]$TestbenchFile = "",
    
    [Parameter(Mandatory=$false, HelpMessage="是否自动打开波形")]
    [switch]$NoWaveform = $false,
    
    [Parameter(Mandatory=$false, HelpMessage="是否清理旧文件")]
    [switch]$Clean = $false
)

# ========================================
# 配置
# ========================================
$RTL_DIR = "rtl"
$TB_DIR = "tb"
$SIM_DIR = "sim"

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
# 1. 清理旧文件（可选）
# ========================================
if ($Clean) {
    Write-Step "清理仿真文件" "Yellow"
    if (Test-Path $SIM_DIR) {
        Remove-Item -Path "$SIM_DIR\*" -Force -ErrorAction SilentlyContinue
        Write-Success "清理完成"
    }
}

# ========================================
# 2. 确保 sim 目录存在
# ========================================
if (-not (Test-Path $SIM_DIR)) {
    New-Item -ItemType Directory -Path $SIM_DIR | Out-Null
    Write-Info "创建 sim 目录"
}

# ========================================
# 3. 查找 Testbench 文件
# ========================================
Write-Step "查找 Testbench 文件" "Cyan"

if ($TestbenchFile -eq "") {
    # 自动查找 tb 目录下的文件
    $tbFiles = Get-ChildItem -Path $TB_DIR -Filter "*.v" -ErrorAction SilentlyContinue
    
    if ($tbFiles.Count -eq 0) {
        Write-Error-Custom "未找到 testbench 文件！"
        Write-Host "请确保 tb 目录下有 .v 文件" -ForegroundColor Gray
        exit 1
    }
    
    if ($tbFiles.Count -eq 1) {
        # 只有一个文件，自动选择
        $TestbenchFile = $tbFiles[0].FullName
        Write-Success "自动选择: $($tbFiles[0].Name)"
    } else {
        # 多个文件，让用户选择
        Write-Host "找到多个 testbench 文件:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $tbFiles.Count; $i++) {
            Write-Host "  [$i] $($tbFiles[$i].Name)" -ForegroundColor White
        }
        
        $selection = Read-Host "请选择 [0-$($tbFiles.Count - 1)]"
        
        if ($selection -match '^\d+$' -and [int]$selection -lt $tbFiles.Count) {
            $TestbenchFile = $tbFiles[[int]$selection].FullName
            Write-Success "已选择: $($tbFiles[[int]$selection].Name)"
        } else {
            Write-Error-Custom "无效选择！"
            exit 1
        }
    }
} else {
    # 用户指定了文件
    if (-not (Test-Path $TestbenchFile)) {
        Write-Error-Custom "文件不存在: $TestbenchFile"
        exit 1
    }
}

# 获取文件名（不含扩展名）
$tbBaseName = [System.IO.Path]::GetFileNameWithoutExtension($TestbenchFile)
$vvpFile = "$SIM_DIR\$tbBaseName.vvp"
$vcdFile = "$SIM_DIR\$tbBaseName.vcd"

Write-Host "   Testbench: $tbBaseName.v" -ForegroundColor Gray
Write-Host "   输出文件: $tbBaseName.vvp" -ForegroundColor Gray

# ========================================
# 4. 编译 Verilog
# ========================================
Write-Step "编译 Verilog 代码" "Cyan"

# 检查 RTL 目录
if (-not (Test-Path $RTL_DIR)) {
    Write-Error-Custom "未找到 rtl 目录！"
    exit 1
}

# 获取所有 RTL 文件
$rtlFiles = Get-ChildItem -Path $RTL_DIR -Filter "*.v" -Recurse | Select-Object -ExpandProperty FullName

if ($rtlFiles.Count -eq 0) {
    Write-Error-Custom "rtl 目录下没有 .v 文件！"
    exit 1
}

Write-Info "找到 $($rtlFiles.Count) 个 RTL 文件"

# 构建编译命令
$compileArgs = @(
    "-g2012",           # SystemVerilog-2012 标准
    "-Wall",            # 显示所有警告
    "-o", $vvpFile,     # 输出文件
    "-I", $RTL_DIR      # 包含路径
)

# 添加所有 RTL 文件
$compileArgs += $rtlFiles

# 添加 testbench 文件
$compileArgs += $TestbenchFile

Write-Host "   执行: iverilog $($compileArgs -join ' ')" -ForegroundColor Gray

try {
    $output = & iverilog $compileArgs 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "编译失败！"
        Write-Host $output -ForegroundColor Red
        exit 1
    }
    
    # 检查警告
    if ($output) {
        Write-Host $output -ForegroundColor Yellow
    }
    
    Write-Success "编译成功！"
    
} catch {
    Write-Error-Custom "编译出错: $_"
    exit 1
}

# ========================================
# 5. 运行仿真
# ========================================
Write-Step "运行仿真" "Cyan"

try {
    Write-Host "   执行: vvp $vvpFile" -ForegroundColor Gray
    
    $simOutput = & vvp $vvpFile 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "仿真失败！"
        Write-Host $simOutput -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
    Write-Host $simOutput
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
    Write-Host ""
    
    Write-Success "仿真完成！"
    
} catch {
    Write-Error-Custom "仿真出错: $_"
    exit 1
}

# ========================================
# 6. 查看波形
# ========================================
if (-not $NoWaveform) {
    Write-Step "查看波形" "Cyan"
    
    if (Test-Path $vcdFile) {
        Write-Info "波形文件: $vcdFile"
        
        # 检查 GTKWave 是否安装
        $gtkwaveExists = Get-Command gtkwave -ErrorAction SilentlyContinue
        
        if ($gtkwaveExists) {
            Write-Host "   启动 GTKWave..." -ForegroundColor Gray
            Start-Process gtkwave -ArgumentList $vcdFile
            Write-Success "GTKWave 已启动"
        } else {
            Write-Error-Custom "未找到 GTKWave！"
            Write-Host "请安装 GTKWave 或使用 -NoWaveform 参数跳过" -ForegroundColor Yellow
        }
    } else {
        Write-Info "未找到波形文件 (.vcd)"
        Write-Host "可能是 testbench 中没有调用 `$dumpfile" -ForegroundColor Gray
    }
}

# ========================================
# 7. 完成
# ========================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✨ 运行完成！" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "生成的文件:" -ForegroundColor White
Write-Host "   📦 $vvpFile" -ForegroundColor Gray
if (Test-Path $vcdFile) {
    Write-Host "   📊 $vcdFile" -ForegroundColor Gray
}
Write-Host ""