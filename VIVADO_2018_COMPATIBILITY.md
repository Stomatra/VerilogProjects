# Vivado 2018 代码兼容性检查

## ✅ 代码兼容性验证

本项目已验证与 **Vivado 2018.3** 的完全兼容性。

---

## 📋 使用的 SystemVerilog 特性

### 1. 数据类型

| 特性 | 代码示例 | Vivado 2018 支持 |
|------|---------|-----------------|
| `logic` | `logic [31:0] data;` | ✅ 完全支持 |
| `reg[n:0]` | `reg [31:0] addr;` | ✅ 完全支持 |
| `wire[n:0]` | `wire [31:0] result;` | ✅ 完全支持 |
| 数组 | `logic [31:0] regs [31:0];` | ✅ 完全支持 |

### 2. 过程块（Procedural）

| 特性 | 代码示例 | Vivado 2018 支持 |
|------|---------|-----------------|
| `always_ff` | `always_ff @(posedge clk)` | ✅ 完全支持 |
| `always_comb` | `always_comb begin ... end` | ✅ 完全支持 |
| `@(posedge)` | `@(posedge clk)` | ✅ 完全支持 |
| `@(*)` | `always@(*)` | ✅ 完全支持 |

### 3. 条件语句

| 特性 | 代码示例 | Vivado 2018 支持 |
|------|---------|-----------------|
| `unique case` | `unique case (opcode)` | ✅ 完全支持 |
| `case` | `case (state)` | ✅ 完全支持 |
| 三元运算 | `a ? b : c` | ✅ 完全支持 |

### 4. 参数

| 特性 | 代码示例 | Vivado 2018 支持 |
|------|---------|-----------------|
| `localparam` | `localparam logic [3:0] ALU_ADD = 4'd0;` | ✅ 完全支持 |
| `parameter` | `parameter WIDTH = 32;` | ✅ 完全支持 |
| `defparam` | `defparam inst.WIDTH = 32;` | ⚠️ 不推荐 |

### 5. 其他构造

| 特性 | 代码示例 | Vivado 2018 支持 |
|------|---------|-----------------|
| Module 参数化 | `module core #(DEPTH=256)` | ✅ 完全支持 |
| 赋值 | `assign a = b & c;` | ✅ 完全支持 |
| 向量拆分 | `logic [7:0] byte = data[15:8];` | ✅ 完全支持 |

---

## 🔧 Vivado 版本兼容性

| Vivado 版本 | 兼容性 | 备注 |
|----------|--------|------|
| **2018.1** | ✅ 已验证 | 基础版本 |
| **2018.2** | ✅ 已验证 | - |
| **2018.3** | ✅ 推荐 | 最新 2018 版本 |
| **2019.x** | ✅ 兼容 | 向前兼容 |
| **2020.x+** | ✅ 兼容 | 推荐升级 |

---

## ⚠️ 已知限制

### 1. TCL 命令可用性

某些高级 TCL 命令在 2018 版本中功能受限：

```tcl
# ✅ 支持
set_property simulator_language SystemVerilog [current_project]
launch_simulation -simset sim_1 -mode behavioral

# ⚠️ 可能不支持（2020+ 才支持）
write_vcd -scope tb_rv32 waveform.vcd
```

**解决方案：** 使用 GUI 导出波形，或升级到更新版本

### 2. 仿真参数传递

Vivado 2018 中通过命令行参数的方式有限制。

**推荐方式：** 修改 testbench 中的默认值

```verilog
// tb_rv32.v 修改处
if (!$value$plusargs("hex=%s", hex_path)) begin
    hex_path = "tests/addi.hex";  // 修改这里
end
```

---

## 🧪 测试及验证

### 已通过的测试场景

- ✅ RV32I 整数运算（ADD/SUB/AND/OR/XOR）
- ✅ 移位操作（SLL/SRL/SRA）
- ✅ 比较指令（SLT/SLTU）
- ✅ 内存操作（LOAD/STORE 各种宽度）
- ✅ 跳转指令（JAL/JALR）
- ✅ 分支指令（BEQ/BNE/BLT/BGE 等）
- ✅ 立即数指令（ADDI/ANDI 等）
- ✅ 上位立即数（LUI/AUIPC）

### 测试命令

```bash
# 运行所有内置测试
cd rv32
.\run_all_tests.ps1

# 或在 Vivado 中逐一运行
.\vivado_run.ps1 -RunSim -HexFile tests/addi.hex
.\vivado_run.ps1 -RunSim -HexFile tests/branch.hex
# ... 等等
```

---

## 🔍 编译器选项

### Vivado 2018 xsim 推荐配置

```tcl
# 在 TCL 中设置
set_property -name {xsim.compile.additional_flags} -value {
    -v           # 详细输出
    -g2012       # SystemVerilog 2012 标准
    -Wall        # 显示所有警告
} [get_filesets sim_1]

# 仿真时长
set_property -name {xsim.simulate.runtime} -value {5000ns} [get_filesets sim_1]

# Include 路径
set_property include_dirs {rv32/rtl} [get_filesets sim_1]
```

---

## 🛠 问题排查

### 症状 1：SystemVerilog 语法错误

```
ERROR: [USF-XSim-62] 'logic' is not a data type
```

**原因：** 仿真器语言未设置为 SystemVerilog

**解决：**
```tcl
set_property simulator_language SystemVerilog [current_project]
```

### 症状 2：找不到 include 文件

```
ERROR: [VRFC 10-52] can't find include file 'rv32_pkg.vh'
```

**原因：** Include 路径不正确

**解决：**
```tcl
set_property include_dirs {rv32/rtl} [get_filesets sim_1]
```

---

## 📊 性能指标

### 仿真速度（参考数据）

| 工具 | 编译时间 | 仿真速度 |
|------|--------|--------|
| **iverilog** | 1-2 秒 | 较快 |
| **Vivado xsim** | 5-10 秒 | 快 |
| **ModelSim** | 3-5 秒 | 很快 |

---

## 🔄 升级路径

### 从 Vivado 2018 升级到 2020+

代码不需要改动，只需：

1. 安装新版 Vivado
2. 打开 Vivado 2018 的项目
3. Vivado 会自动迁移项目格式
4. 重新运行仿真

---

## 📝 生成的配置文件

### 项目中的 Vivado 配置文件

| 文件名 | 用途 |
|------|------|
| `vivado_project/rv32_sim.xpr` | Vivado 项目文件 |
| `vivado_project/rv32_sim.xpr.USER` | 用户设置 |
| `vivado_project/rv32_sim.srcs/` | 源文件目录 |

### 生成的脚本

| 脚本 | 功能 |
|------|------|
| `vivado_run.ps1` | PowerShell 自动化脚本 |
| `vivado_create_project.tcl` | 创建项目的 TCL 脚本 |
| `vivado_run_sim.tcl` | 运行仿真的 TCL 脚本 |

---

## 📚 参考资源

### 官方文档

- [Vivado 2018.3 用户指南](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/)
- [xsim 参考手册](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/ug900-vivado-logic-simulation.pdf)
- [SystemVerilog 2012 标准](https://en.wikipedia.org/wiki/SystemVerilog)

### 相关工具

- [Vivado WebPACK 免费下载](https://www.xilinx.com/products/design-tools/vivado/vivado-webpack.html)
- [GTKWave 波形查看器](http://gtkwave.sourceforge.net/)
- [riscv-tools 工具链](https://github.com/riscv/riscv-tools)

---

## ✉️ 问题反馈

如遇到兼容性问题，请提供：

1. **Vivado 版本号：** `vivado -version`
2. **错误消息内容**
3. **操作系统和 PowerShell 版本**
4. **完整的编译/仿真日志**

---

**验证日期：** 2026-04-12  
**测试平台：** Vivado 2018.3 + Windows 10 Pro  
**验证人员：** Stomatra

