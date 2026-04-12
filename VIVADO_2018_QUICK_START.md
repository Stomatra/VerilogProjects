# Windows Vivado 2018 快速开始

## ⚡ 30 秒快速开始

1. **打开 PowerShell**（在项目根目录）

2. **第一次运行（创建项目）**
   ```powershell
   .\vivado_run.ps1 -Create
   ```
   等待 1-2 分钟...

3. **运行仿真**
   ```powershell
   .\vivado_run.ps1 -RunSim
   ```

4. **打开 GUI 查看波形**
   ```powershell
   .\vivado_run.ps1 -GUI
   ```

---

## 📋 前置步骤

### 1. 安装并配置 Vivado 2018

在本地安装了 Vivado 2018 后，需要配置 PATH：

**Windows CMD：**
```batch
REM 请根据实际安装路径修改
"C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -version
```

**PowerShell：**
```powershell
# 检查是否可以直接调用 vivado
vivado -version

# 如果不行，运行 settings64.bat
& "C:\Xilinx\Vivado\2018.3\settings64.bat"
```

### 2. 克隆或下载项目

```powershell
git clone https://github.com/Stomatra/VerilogProjects.git
cd VerilogProjects
```

---

## 🚀 操作步骤

### 方法 A：使用 PowerShell 脚本（推荐）

#### 初次使用

```powershell
# 1. 创建 Vivado 项目
.\vivado_run.ps1 -Create

# 2. 打开 GUI（可选，用于后续手动操作）
.\vivado_run.ps1 -GUI
```

#### 后续运行仿真

```powershell
# 运行仿真（使用默认 hex 文件）
.\vivado_run.ps1 -RunSim

# 或指定具体的 hex 文件
.\vivado_run.ps1 -RunSim -HexFile "tests/addi.hex"
```

---

### 方法 B：使用 Vivado GUI 手动操作

#### 1. 创建项目

1. 打开 **Vivado Design Suite 2018.3**
2. `File` → `New Project`
3. 填写信息：
   - **Project name:** `rv32_sim`
   - **Project location:** 选择你的项目根目录
   - **Create project subdirectory:** ✓（打勾）
   - **Default location:** ✓（打勾）

#### 2. 配置项目

点击 `Next`，设置：
- **Project type:** RTL Project
- **Don't specified sources right now:** ✓（先不添加源）

点击 `Next`

#### 3. 添加源文件

- **Default Part:** 选 `xc7z020clg484-1`（或任意 Zynq 7000 系列）
- 完成项目创建

#### 4. 添加文件

在 **Project Manager** 左侧右键 `Sources`:
```
Add Files...
```

添加以下文件（按顺序）：
```
rv32/rtl/rv32_pkg.vh
rv32/rtl/rv32_alu.v
rv32/rtl/rv32_branch.v
rv32/rtl/rv32_decode.v
rv32/rtl/rv32_imm.v
rv32/rtl/rv32_mem_if.v
rv32/rtl/rv32_regfile.v
rv32/rtl/rv32_core.v
rv32/rtl/rv32_top.v
rv32/tb/tb_rv32.v
```

#### 5. 配置仿真

右键 `tb_rv32.v` → `Set as Top`（针对 sim_1）

#### 6. 查看仿真设置

在 **Project Manager** 左侧找 `sim_1`，右键 → `Simulation Settings`:

确保：
- **Simulator language:** `SystemVerilog`（不是 Verilog！）
- **Simulation runtime:** `5000 ns`

#### 7. 运行仿真

左侧 `Flow` → `Run Simulation` → `Run Behavioral Simulation`

或使用快捷键 **Ctrl+F2**

---

## 📊 查看仿真结果

### 在 Vivado 中查看

仿真窗口下方会显示 Tcl console 的输出：

```
[TB] loading program: tests/addi.hex
[TB] PASS: ram[0]=XX ram[1]=1
```

表示测试通过！

### 查看波形

1. 仿真运行中，Go to Wave 窗口
2. 左侧 `Wave` 窗口中右键 → `Add All Signals`
3. 点击 `Zoom Full` 查看完整波形

### 导出波形

```tcl
# 在 Tcl Console 直接运行：
write_vcd -scope tb_rv32 my_waveform.vcd
```

然后用 GTKWave 打开：

```powershell
gtkwave my_waveform.vcd
```

---

## ⚙️ 常见设置

### 修改仿真时长

**在 Vivado GUI 中：**

1. `Tools` → `Project Settings`
2. `Simulation` → `xsim`
3. Modify `xsim.simulate.runtime`
   - 改为 `10000 ns`（表示 10 微秒）

### 修改 hex 文件路径

**在 PowerShell 脚本中修改：**

编辑 `vivado_run.ps1`，找到：
```powershell
[Parameter(Mandatory=$false)]
[string]$HexFile = "tests/addi.hex"
```

改为你的文件路径，或直接传参：
```powershell
.\vivado_run.ps1 -RunSim -HexFile "tests/my_custom_test.hex"
```

---

## 🔧 故障排除

### ❌ "vivado: command not found"

**原因：** Vivado 未添加到系统 PATH

**解决：** 运行初始化脚本

```powershell
# Windows - 找到你的 Vivado 安装目录，运行：
& "C:\Xilinx\Vivado\2018.3\settings64.bat"

# 然后重新开启 PowerShell
```

### ❌ "Cannot find package"

**原因：** RTL 文件未正确添加

**解决：**
1. 检查文件路径
2. 确保 `rv32/rtl/rv32_pkg.vh` 已添加
3. 重新创建项目：
   ```powershell
   .\vivado_run.ps1 -Create
   ```

### ❌ 仿真卡住或超时

**原因：** 测试程序问题或仿真配置

**调试步骤：**
1. 查看仿真日志：`vivado_sim.log`
2. 在 GUI 中逐步运行：`run 100` （运行 100ns）
3. 观察 `ram[1]` 寄存器的值

### ❌ "FAIL: ram[1]=0xDEADBEEF"

**原因：** 测试程序执行错误

**调试：**
1. 检查 hex 文件
2. 在 GUI 波形中观察 PC 和寄存器变化
3. 对照指令集手册检查程序逻辑

---

## 📁 生成的文件说明

运行后会生成：

```
vivado_project/
├── rv32_sim.xpr              # Vivado 项目文件（可用 GUI 打开）
├── rv32_sim.srcs/            # 源文件
│   ├── sources_1/            # RTL 代码
│   └── sim_1/                # 仿真代码
└── ...

sim_tb_rv32.vcd               # 波形文件（可用 GTKWave 打开）
vivado_sim.log                # 仿真日志
```

---

## 💡 后续操作

### 修改代码后重新仿真

1. **编辑 Verilog 代码** → 保存
2. **在 Vivado 中：** `Shift+F5` 重新运行仿真
3. 或使用 PowerShell：
   ```powershell
   .\vivado_run.ps1 -RunSim
   ```

### 生成比特流（综合&实现）

项目创建后可以在 Vivado GUI 中进行：

1. `Flow` → `Run Synthesis`
2. `Flow` → `Run Implementation`
3. `Flow` → `Generate Bitstream`

（注：测试不需要这一步）

---

## 📚 相关文件

| 文件 | 用途 |
|------|------|
| `vivado_run.ps1` | 自动化脚本 |
| `vivado_create_project.tcl` | 项目创建（TCL） |
| `vivado_run_sim.tcl` | 仿真运行（TCL） |
| `rv32/rtl/*.v` | RTL 源代码 |
| `rv32/tb/tb_rv32.v` | 仿真 testbench |

---

## 🔗 相关链接

- [Vivado 2018 官方文档](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/ug894-vivado-design-suite-tcl-reference-guide.pdf)
- [SystemVerilog 2012 标准](https://en.wikipedia.org/wiki/SystemVerilog)
- [RISC-V 规范](https://riscv.org/technical/specifications/)
- [GTKWave 使用指南](http://gtkwave.sourceforge.net/)

---

**创建时间：** 2026-04-12  
**作者：** Stomatra  
**版本：** 1.0

