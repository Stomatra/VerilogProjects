# RV32 Verilog 项目 - 运行指南

本项目支持多种仿真方式运行，包括免费工具和商业工具。

## 🎯 快速选择

| 工具 | 难度 | 成本 | 支持 |
|------|------|------|------|
| **iverilog** | ⭐ | 免费 | ✅ 完全支持 |
| **Vivado 2018** | ⭐⭐ | 免费版 | ✅ 完全支持 |
| **ModelSim** | ⭐⭐⭐ | 付费 | ✅ 兼容 |

---

## 📦 方式 1：iverilog（推荐新手）

**特点：** 完全免费、跨平台、无需许可证

### 安装

- **Windows:** [iverilog 官网](http://bleyer.org/icarus/) 下载 `iverilog-11_8_1_x64_setup.exe`
- **Ubuntu:** `sudo apt install iverilog gtkwave`
- **macOS:** `brew install icarus-verilog gtkwave`

### 运行

```powershell
# 自动编译、仿真、查看波形
.\run_verilog.ps1

# 或直接指定 testbench
.\run_verilog.ps1 -TestbenchFile "rv32\tb\tb_rv32.v"

# 跳过波形显示
.\run_verilog.ps1 -NoWaveform
```

### 查看波形

```bash
gtkwave sim/tb_rv32.vcd
```

---

## 🏭 方式 2：Vivado 2018（推荐企业）

**特点：** 功能完整、官方支持、可综合实现

### 安装

1. 下载 [Vivado 2018.3 WebPACK](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2018-3.html)（免费）
2. 安装到默认路径
3. 在 PowerShell 中运行初始化脚本

### 快速开始

```powershell
# 第一次（创建项目）
.\vivado_run.ps1 -Create

# 运行仿真
.\vivado_run.ps1 -RunSim

# 打开 GUI
.\vivado_run.ps1 -GUI
```

### 详细指南

**→ 查看** [VIVADO_2018_QUICK_START.md](VIVADO_2018_QUICK_START.md)

---

## 🛠 方式 3：其他工具

### ModelSim / Questa

```bash
# 编译
vlog -sv rv32/rtl/*.v rv32/tb/tb_rv32.v

# 仿真
vsim -do "run -all" tb_rv32
```

### Verilator（高性能）

```bash
verilator --cc -sv rv32/rtl/*.v rv32/tb/tb_rv32.v
cd obj_dir
make -f Vtb_rv32.mk
./Vtb_rv32
```

---

## 📂 项目结构

```
VerilogProjects/
├── rv32/
│   ├── rtl/              # RTL 源代码
│   │   ├── rv32_pkg.vh   # 指令集定义
│   │   ├── rv32_alu.v    # ALU 模块
│   │   ├── rv32_branch.v # 分支判断
│   │   ├── rv32_decode.v # 指令译码
│   │   ├── rv32_imm.v    # 立即数生成
│   │   ├── rv32_mem_if.v # 存储器接口
│   │   ├── rv32_regfile.v # 寄存器堆
│   │   ├── rv32_core.v   # 核心控制（主文件）
│   │   └── rv32_top.v    # 顶层例化
│   ├── tb/
│   │   └── tb_rv32.v     # 仿真 testbench
│   └── tests/            # 测试程序（hex 格式）
│       ├── addi.hex
│       ├── ...
│       └── ...
├── run_verilog.ps1       # iverilog 运行脚本
├── vivado_run.ps1        # Vivado 运行脚本
├── VIVADO_GUIDE.md       # Vivado 详细指南
└── VIVADO_2018_QUICK_START.md # Vivado 快速开始
```

---

## 🧪 运行测试

### 列举所有测试

```bash
ls rv32/tests/
```

### 使用 iverilog 运行特定测试

```powershell
# 运行 addi.hex 测试
.\run_verilog.ps1

# 通过 rv32/run_all_tests.ps1 运行所有测试
cd rv32
.\run_all_tests.ps1
```

### 使用 Vivado 运行特定测试

```powershell
# 使用 addi.hex
.\vivado_run.ps1 -RunSim -HexFile rv32/tests/addi.hex

# 或指定其他测试
.\vivado_run.ps1 -RunSim -HexFile rv32/tests/another_test.hex
```

---

## 📊 仿真结果解读

### 成功（PASS）

```
[TB] PASS: ram[0]=XXXXXXXX ram[1]=1
```

- `ram[1] == 0x00000001` → 测试通过
- 继续查看 `ram[0]` 中的结果

### 失败（FAIL）

```
[TB] FAIL: ram[0]=XXXXXXXX ram[1]=DEADBEEF
```

- `ram[1] == 0xDEADBEEF` → 测试失败
- 检查测试程序逻辑或 CPU 实现

### 超时（TIMEOUT）

```
[TB] TIMEOUT: ram[0]=XXXXXXXX ram[1]=XXXXXXXX
```

- 仿真运行了 5000ns 但未得到结果
- 原因可能是：
  1. 测试程序死循环
  2. 存储器地址错误
  3. 仿真时长配置不足

---

## 🔍 调试技巧

### 1. 查看波形

**使用 iverilog 时：**
```bash
gtkwave sim/tb_rv32.vcd
```

**使用 Vivado 时：**
- 在仿真窗口中查看波形
- 或导出 VCD：`write_vcd tb_inst.vcd`

### 2. 查看寄存器值

在仿真中添加 `$monitor`：
```verilog
initial begin
  $monitor("Time=%0t PC=%h rs1=%h rs2=%h rd=%h",
           $time, pc, rs1_val, rs2_val, rf_wdata);
end
```

### 3. 单步调试

**Vivado GUI 中：**
- 在 Tcl Console 运行 `run 100` （运行 100ns）
- 逐步观察信号变化

**iverilog 中：**
- 无原生支持，使用 GTKWave 的逐步功能

### 4. 查看日志

```powershell
# iverilog 日志（如有编译错误）
Get-Content "run_verilog.log"

# Vivado 日志
Get-Content "vivado_sim.log"
```

---

## 🎲 编写测试程序

### 创建 Hex 文件

1. 用汇编器编写 RISC-V 程序（`.s` 文件）
2. 编译成机器码（`.bin` 或 `.hex`）
3. 放到 `rv32/tests/` 目录
4. 在 tb_rv32.v 中的 `$readmemh` 加载

### 示例：简单的 ADDI 测试

```riscv
# tests/my_addi.s
main:
  addi x5, x0, 10    # x5 = 10
  addi x6, x5, 20    # x6 = 30
  sw   x6, 4(x0)     # ram[1] = 30（测试通过标志位）
  nop
```

转换到 hex：
```bash
riscv32-unknown-elf-as -march=rv32i my_addi.s -o my_addi.o
riscv32-unknown-elf-objcopy -O binary my_addi.o my_addi.bin
./bin2hex my_addi.bin my_addi.hex  # 需要自己实现或用脚本
```

---

## ⚙️ 配置参数

### iverilog 配置

编辑 `run_verilog.ps1`：
```powershell
# 改变仿真时长
-timeout 30000  # 30 秒

# 编译标志
"-g2012"  # SystemVerilog 2012
```

### Vivado 配置

编辑 `vivado_run.ps1`：
```powershell
# 改变仿真模式
set_property -name {xsim.simulate.runtime} -value {10000ns} [get_filesets sim_1]

# 添加详细输出
set_property -name {xsim.compile.additional_flags} -value {-v} [get_filesets sim_1]
```

---

## 🐛 常见问题

### Q: "Cannot find iverilog"
**A:** 安装 iverilog 或添加到 PATH

### Q: "Cannot open include file rv32_pkg.vh"
**A:** 确保 include 路径正确，编译时加 `-I rv32/rtl`

### Q: "Undefined reference to OPC_*"
**A:** 确保 rv32_pkg.vh 已被添加或 include

### Q: 波形文件很大
**A:** 减少 `$dumpvars` 的范围，或改为 `$dumpvars(1, tb_rv32)`

### Q: xsim 编译错误
**A:** 检查 Vivado 项目设置中是否选择 `SystemVerilog` 语言

---

## 📚 参考资源

- [RISC-V 官网](https://riscv.org/)
- [RV32I 指令集规范](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf)
- [Vivado 2018 用户指南](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/)
- [iverilog 文档](http://bleyer.org/icarus/)
- [SystemVerilog 2012 标准](https://en.wikipedia.org/wiki/SystemVerilog)

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📄 许可证

MIT License

---

**更新时间：** 2026-04-12  
**维护者：** Stomatra

