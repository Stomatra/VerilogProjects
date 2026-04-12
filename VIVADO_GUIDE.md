# Vivado 2018 运行指南

本文档说明如何在 Vivado 2018 中运行 RV32 仿真项目。

## 前置要求

- **Vivado 2018+** 已安装
- **Windows** (PowerShell) 或 **Linux/WSL** (Bash)
- **rv32 项目文件** 已准备好

## 方法 1：使用 PowerShell 脚本（推荐）

### 步骤 1：创建项目

在项目根目录打开 PowerShell，执行：

```powershell
.\vivado_run.ps1 -Create
```

这会：
- 自动创建 Vivado 项目
- 添加所有 RTL 和仿真源文件
- 配置项目属性

**输出：** 创建 `vivado_project/` 目录

---

### 步骤 2：运行仿真

```powershell
# 运行默认 hex 文件 (tests/addi.hex)
.\vivado_run.ps1 -RunSim

# 或指定其他 hex 文件
.\vivado_run.ps1 -RunSim -HexFile tests/your_test.hex
```

**输出：** 仿真日志和波形文件

---

### 步骤 3：打开 GUI（可选）

```powershell
.\vivado_run.ps1 -GUI
```

这会启动 Vivado GUI，可以：
- 查看项目结构
- 手动运行仿真
- 调整仿真参数
- 查看波形

---

### 一键完成流程

```powershell
.\vivado_run.ps1 -Create -GUI -RunSim
```

---

## 方法 2：使用 TCL 脚本（高级）

### 创建项目

```bash
vivado -mode batch -source vivado_create_project.tcl
```

### 运行仿真

```bash
vivado -mode batch -source vivado_run_sim.tcl
```

---

## 方法 3：在 GUI 中手动操作

### 创建项目

1. 打开 Vivado 2018
2. `File > New Project`
3. 配置：
   - **Project name:** `rv32_sim`
   - **Project location:** 选择项目根目录
   - **Project type:** RTL Project
   - **Simulator language:** SystemVerilog

4. 添加源文件：
   ```
   rv32/rtl/rv32_pkg.vh
   rv32/rtl/rv32_*.v
   rv32/tb/tb_rv32.v
   ```

5. 设置仿真顶层：`tb_rv32`

---

### 运行仿真

1. `Flow > Run Simulation` 或点击左边栏的 `Run Simulation`
2. 等待仿真编译完成
3. 在 Tcl Console 运行：
   ```tcl
   run all
   ```

---

## 波形查看

### Vivado 内置波形查看

1. 仿真运行后，在 Vivado 中：
   - `File > Open Waveform > waveform_1.wcfg`
   - 或直接在波形窗口中查看

### 外部工具查看

生成的 `.vcd` 文件可用 GTKWave 打开：

```bash
gtkwave sim_tb_rv32.vcd
```

---

## 常见问题

### Q1: 找不到 Vivado 命令

**原因：** Vivado 未添加到系统 PATH

**解决：**
- **Windows:** 运行 Vivado 附带的 `settings64.bat`
- **Linux/WSL:** 运行 Vivado 附带的 `settings64.sh`

例如：
```bash
source /opt/Xilinx/Vivado/2018.3/settings64.sh
```

---

### Q2: "Cannot open include file"

**原因：** Include 路径配置错误

**解决：** 确保 `rv32/rtl/` 目录包含所有 `.v` 和 `.vh` 文件

---

### Q3: SystemVerilog 语法错误

**原因：** Vivado 仿真器未启用 SystemVerilog

**解决：** 在 Vivado GUI 中：
- `Tools > Project Settings`
- `Simulator language: SystemVerilog`

---

### Q4: 仿真超时

**原因：** 
- hex 文件路径错误
- 测试程序逻辑错误
- 仿真配置不匹配

**调试：**
1. 检查 `vivado_sim.log` 日志
2. 在 Vivado GUI 中逐步运行仿真
3. 检查 `ram[1]` 的值：
   - `0x00000001` = PASS
   - `0xDEADBEEF` = FAIL

---

## 项目文件结构

创建项目后的目录结构：

```
vivado_project/
├── rv32_sim.xpr           # Vivado 项目文件
├── rv32_sim.srcs/         # 源文件
│   ├── sources_1/         # RTL 源
│   └── sim_1/             # 仿真源
├── rv32_sim.sim/          # 仿真文件
└── ...
```

---

## 高级配置

### 修改仿真参数

编辑 `vivado_run.ps1`：

```powershell
# 改变仿真时间
set_property -name {xsim.simulate.runtime} -value {10000ns} [get_filesets sim_1]

# 添加编译标志
set_property -name {xsim.compile.additional_flags} -value {-verbose -d DEBUG} [get_filesets sim_1]
```

### 自定义 hex 文件路径

在 TCL 中配置：

```tcl
set_property -name {xsim.testplus_args} -value {hex=tests/custom_test.hex} [get_filesets sim_1]
```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `vivado_run.ps1` | PowerShell 自动化脚本（推荐） |
| `vivado_create_project.tcl` | TCL 项目创建脚本 |
| `vivado_run_sim.tcl` | TCL 仿真运行脚本 |
| `run_verilog.ps1` | iverilog 仿真脚本（不依赖 Vivado） |

---

## 切换仿真方式

### 使用 iverilog（不需要 Vivado 许可证）

```powershell
.\run_verilog.ps1
```

### 使用 Vivado xsim

```powershell
.\vivado_run.ps1 -RunSim
```

---

## 支持的 Vivado 版本

- ✅ Vivado 2018.1+
- ✅ Vivado 2019.x
- ✅ Vivado 2020.x
- ✅ Vivado 2021.x+

本项目使用标准 SystemVerilog 2012，应兼容所有现代 Vivado 版本。

---

## 获取帮助

```powershell
# 查看脚本使用说明
.\vivado_run.ps1

# 查看完整行为
.\vivado_run.ps1 -RunSim -Verbose
```

查看日志：
- `vivado_create.log` - 项目创建日志
- `vivado_sim.log` - 仿真日志

---

**更新时间：** 2026-04-12  
**作者：** Stomatra
