# ========================================
# Verilog 项目自动生成脚本
# 作者: Stomatra
# 功能: 自动创建项目目录、模板文件、VS Code 配置
# 使用方法: .\create_verilog_project.ps1 -ProjectName "my_project" -ModuleName "counter"
# ========================================

param(
    [Parameter(Mandatory=$true, HelpMessage="项目名称（文件夹名）")]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$true, HelpMessage="模块名称（如 counter, adder）")]
    [string]$ModuleName,
    
    [Parameter(Mandatory=$false, HelpMessage="项目根目录（默认当前目录）")]
    [string]$BaseDir = "."
)

# ========================================
# 1. 创建项目目录
# ========================================
$projectPath = Join-Path $BaseDir $ProjectName

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verilog 项目生成器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $projectPath) {
    Write-Host "⚠️  项目已存在: $projectPath" -ForegroundColor Yellow
    $overwrite = Read-Host "是否覆盖？(y/n)"
    if ($overwrite -ne "y") {
        Write-Host "❌ 取消创建" -ForegroundColor Red
        exit
    }
    Remove-Item -Path $projectPath -Recurse -Force
}

Write-Host "📁 创建项目目录..." -ForegroundColor Green
New-Item -ItemType Directory -Path $projectPath | Out-Null
New-Item -ItemType Directory -Path "$projectPath\rtl" | Out-Null
New-Item -ItemType Directory -Path "$projectPath\tb" | Out-Null
New-Item -ItemType Directory -Path "$projectPath\sim" | Out-Null
New-Item -ItemType Directory -Path "$projectPath\.vscode" | Out-Null

# ========================================
# 2. 生成 RTL 设计文件
# ========================================
$rtlFile = "$projectPath\rtl\$ModuleName.v"
Write-Host "📝 生成设计文件: rtl\$ModuleName.v" -ForegroundColor Green

$rtlContent = @"
// ========================================
// 模块名: $ModuleName
// 功能: (在这里描述你的模块功能)
// 作者: Stomatra
// 日期: $(Get-Date -Format "yyyy-MM-dd")
// ========================================

``timescale 1ns/1ps

module $ModuleName (
    input  wire clk,          // 时钟信号
    input  wire rst_n,        // 复位信号（低电平有效）
    input  wire [7:0] data_in,  // 8位输入数据
    output reg  [7:0] data_out  // 8位输出数据
);

    // ========================================
    // 内部信号声明
    // ========================================
    // 在这里声明内部信号（wire/reg）

    // ========================================
    // 组合逻辑
    // ========================================
    // 使用 assign 或 always @(*) 描述组合逻辑

    // ========================================
    // 时序逻辑
    // ========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            data_out <= 8'h00;
        end else begin
            // 在这里实现你的时序逻辑
            data_out <= data_in;  // 示例：直通逻辑
        end
    end

endmodule
"@

Set-Content -Path $rtlFile -Value $rtlContent -Encoding UTF8

# ========================================
# 3. 生成 Testbench 文件
# ========================================
$tbFile = "$projectPath\tb\tb_$ModuleName.v"
Write-Host "📝 生成测试文件: tb\tb_$ModuleName.v" -ForegroundColor Green

$tbContent = @"
// ========================================
// 测试平台: tb_$ModuleName
// 功能: 测试 $ModuleName 模块
// 作者: Stomatra
// 日期: $(Get-Date -Format "yyyy-MM-dd")
// ========================================

``timescale 1ns/1ps

module tb_$ModuleName;

    // ========================================
    // 1. 参数定义
    // ========================================
    parameter CLK_PERIOD = 10;  // 时钟周期 10ns (100MHz)

    // ========================================
    // 2. 信号声明
    // ========================================
    reg         clk;
    reg         rst_n;
    reg  [7:0]  data_in;
    wire [7:0]  data_out;

    // ========================================
    // 3. 时钟生成
    // ========================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ========================================
    // 4. 例化待测设计 (DUT)
    // ========================================
    $ModuleName u_$ModuleName (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (data_in),
        .data_out (data_out)
    );

    // ========================================
    // 5. 激励生成
    // ========================================
    initial begin
        // 初始化信号
        rst_n   = 0;
        data_in = 8'h00;

        // 打印测试开始信息
        `$display("========================================");
        `$display("  $ModuleName Testbench");
        `$display("  Start Time: %0t", `$time);
        `$display("========================================");

        // 复位
        #(CLK_PERIOD * 2);
        rst_n = 1;
        `$display("[%0t] Reset released", `$time);

        // 测试用例 1
        #(CLK_PERIOD);
        data_in = 8'hAA;
        `$display("[%0t] Test 1: data_in = 0x%h", `$time, data_in);

        // 测试用例 2
        #(CLK_PERIOD * 2);
        data_in = 8'h55;
        `$display("[%0t] Test 2: data_in = 0x%h", `$time, data_in);

        // 测试用例 3
        #(CLK_PERIOD * 2);
        data_in = 8'hFF;
        `$display("[%0t] Test 3: data_in = 0x%h", `$time, data_in);

        // 等待几个周期
        #(CLK_PERIOD * 5);

        // 测试结束
        `$display("========================================");
        `$display("  Simulation Finished!");
        `$display("  End Time: %0t", `$time);
        `$display("========================================");
        `$finish;
    end

    // ========================================
    // 6. 波形文件生成
    // ========================================
    initial begin
        `$dumpfile("sim/tb_$ModuleName.vcd");
        `$dumpvars(0, tb_$ModuleName);
    end

    // ========================================
    // 7. 监控输出（可选）
    // ========================================
    // initial begin
    //     `$monitor("Time=%0t clk=%b rst_n=%b data_in=%h data_out=%h", 
    //         `$time, clk, rst_n, data_in, data_out);
    // end

endmodule
"@

Set-Content -Path $tbFile -Value $tbContent -Encoding UTF8

# ========================================
# 4. 生成 VS Code tasks.json
# ========================================
$tasksFile = "$projectPath\.vscode\tasks.json"
Write-Host "⚙️  生成 VS Code 配置: .vscode\tasks.json" -ForegroundColor Green

$tasksContent = @"
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Compile Verilog",
            "type": "shell",
            "command": "iverilog",
            "args": [
                "-g2012",
                "-Wall",
                "-o",
                "sim/`${fileBasenameNoExtension}.vvp",
                "-I", "rtl",
                "rtl/*.v",
                "`${file}"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": [],
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared",
                "showReuseMessage": false,
                "clear": true
            }
        },
        {
            "label": "Run Simulation",
            "type": "shell",
            "command": "vvp",
            "args": [
                "sim/`${fileBasenameNoExtension}.vvp"
            ],
            "dependsOn": "Compile Verilog",
            "problemMatcher": [],
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": true,
                "panel": "shared",
                "showReuseMessage": false
            }
        },
        {
            "label": "View Waveform",
            "type": "shell",
            "command": "gtkwave",
            "args": [
                "sim/`${fileBasenameNoExtension}.vcd"
            ],
            "problemMatcher": [],
            "presentation": {
                "reveal": "never"
            }
        },
        {
            "label": "Full Simulation Flow",
            "dependsOn": [
                "Run Simulation",
                "View Waveform"
            ],
            "dependsOrder": "sequence",
            "problemMatcher": []
        },
        {
            "label": "Clean Simulation Files",
            "type": "shell",
            "command": "Remove-Item",
            "args": [
                "-Path", "sim/*",
                "-Force",
                "-ErrorAction", "SilentlyContinue"
            ],
            "problemMatcher": [],
            "presentation": {
                "reveal": "always"
            }
        }
    ]
}
"@

Set-Content -Path $tasksFile -Value $tasksContent -Encoding UTF8

# ========================================
# 5. 生成 .gitignore
# ========================================
$gitignoreFile = "$projectPath\.gitignore"
Write-Host "📄 生成 .gitignore" -ForegroundColor Green

$gitignoreContent = @"
# Simulation files
sim/*.vvp
sim/*.vcd
sim/*.fst

# Compiler outputs
*.out
*.log

# OS files
.DS_Store
Thumbs.db

# Editor files
.vscode/.browse.*
*.swp
*~
"@

Set-Content -Path $gitignoreFile -Value $gitignoreContent -Encoding UTF8
