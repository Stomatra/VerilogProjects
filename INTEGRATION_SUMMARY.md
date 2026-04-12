# ✅ Vivado 2018 集成完成

## 📝 集成说明

你的 RV32 Verilog 项目已成功集成 **Vivado 2018** 支持！

现在你可以在 Vivado 中运行、调试和仿真 RV32 核心。

---

## 🚀 立即开始

### 方式 A：自动化脚本（推荐）

#### 1️⃣ 创建项目（首次）

```powershell
.\vivado_run.ps1 -Create
```

等待 1-2 分钟，将生成 `vivado_project/` 目录。

#### 2️⃣ 运行仿真

```powershell
.\vivado_run.ps1 -RunSim
```

查看仿真输出：
```
[TB] loading program: tests/addi.hex
[TB] PASS: ram[0]=XXXXXXXX ram[1]=1
```

#### 3️⃣ 打开 GUI（可选）

```powershell
.\vivado_run.ps1 -GUI
```

---

### 方式 B：GUI 手动操作

1. 打开 **Vivado 2018.3**
2. 打开项目：`vivado_project/rv32_sim.xpr`
3. 左侧点击 **Run Simulation** 
4. 在 Tcl Console 中输入 `run all`

详细步骤：→ [VIVADO_2018_QUICK_START.md](VIVADO_2018_QUICK_START.md)

---

## 📂 新增文件说明

| 文件 | 说明 |
|------|------|
| **vivado_run.ps1** | ⭐ PowerShell 自动化脚本（主要工具）|
| vivado_create_project.tcl | TCL 项目创建脚本 |
| vivado_run_sim.tcl | TCL 仿真运行脚本 |
| **VIVADO_2018_QUICK_START.md** | ⭐ Vivado 快速开始指南 |
| VIVADO_GUIDE.md | Vivado 详细使用指南 |
| VIVADO_2018_COMPATIBILITY.md | Vivado 兼容性验证报告 |
| README_VIVADO_SUPPORT.md | 多工具运行方式总结 |
| **INTEGRATION_SUMMARY.md** | ⭐ 本文件 |

---

## ✨ 已验证支持

- ✅ **Vivado 2018.1 ~ 2018.3**
- ✅ **SystemVerilog 2012** 语言
- ✅ **xsim** 仿真器
- ✅ **Windows 10/11** + PowerShell
- ✅ 所有 RV32I 指令集

详细兼容性报告：→ [VIVADO_2018_COMPATIBILITY.md](VIVADO_2018_COMPATIBILITY.md)

---

## 📊 功能对比

| 功能 | iverilog | Vivado 2018 |
|------|----------|-----------|
| 仿真 | ✅ | ✅ |
| 波形查看 | ✅ | ✅ |
| 综合 | ❌ | ✅ |
| 实现 | ❌ | ✅ |
| 成本 | 免费 | 免费版 |
| 速度 | 快 | 很快 |
| 易用性 | 简单 | 丰富 |

---

## 🔧 工作流示例

### 典型流程

```
1. 修改 rv32/*.v 代码
   ↓
2. .\vivado_run.ps1 -RunSim
   ↓
3. 查看仿真结果
   ↓
4. 如果有问题，调试代码 → 回到 1
   ↓
5. .\vivado_run.ps1 -GUI （在 Vivado 中查看波形）
```

---

## 💡 快速参考

### PowerShell 脚本常用命令

```powershell
# 创建项目
.\vivado_run.ps1 -Create

# 运行仿真（使用 tests/addi.hex）
.\vivado_run.ps1 -RunSim

# 运行自定义测试
.\vivado_run.ps1 -RunSim -HexFile tests/branch.hex

# 打开 GUI
.\vivado_run.ps1 -GUI

# 一键完成（创建 + 打开 GUI）
.\vivado_run.ps1 -Create -GUI
```

### 仿真结果判断

| 结果 | `ram[1]` 值 | 含义 |
|------|----------|------|
| PASS | `0x00000001` | ✅ 测试通过 |
| FAIL | `0xDEADBEEF` | ❌ 测试失败 |
| 其他 | 其他数值 | ⏱️ 仿真超时或错误 |

---

## 🐛 常见问题

### Q1: 找不到 Vivado

```powershell
PS> vivado: command not found
```

**解决：**
```powershell
# Windows 下运行初始化脚本
& "C:\Xilinx\Vivado\2018.3\settings64.bat"

# 然后重新打开 PowerShell
```

### Q2: SystemVerilog 错误

```
ERROR: 'logic' is not a data type
```

**解决：** 检查项目设置中"Simulator language"是否为 SystemVerilog

### Q3: 仿真卡住

先尝试运行更少的时间：
```powershell
# 编辑 vivado_run.ps1
set_property -name {xsim.simulate.runtime} -value {100ns} [get_filesets sim_1]

.\vivado_run.ps1 -RunSim
```

---

## 📚 学习资源

### 本项目文档

1. **[VIVADO_2018_QUICK_START.md](VIVADO_2018_QUICK_START.md)** ← **从这里开始**
2. [VIVADO_GUIDE.md](VIVADO_GUIDE.md) - 详细功能说明
3. [VIVADO_2018_COMPATIBILITY.md](VIVADO_2018_COMPATIBILITY.md) - 兼容性验证
4. [README_VIVADO_SUPPORT.md](README_VIVADO_SUPPORT.md) - 多工具对比

### 官方资源

- [Vivado 2018 官方文档](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/)
- [RISC-V 规范](https://riscv.org/technical/specifications/)
- [SystemVerilog 标准](https://en.wikipedia.org/wiki/SystemVerilog)

---

## 🎯 下一步

### 选项 1：快速验证（2 分钟）

```powershell
# 直接运行仿真，看是否工作
.\vivado_run.ps1 -Create
.\vivado_run.ps1 -RunSim
```

### 选项 2：详细学习（30 分钟）

1. 阅读 [VIVADO_2018_QUICK_START.md](VIVADO_2018_QUICK_START.md)
2. 按步骤在 Vivado GUI 中操作
3. 尝试修改代码并重新仿真

### 选项 3：高级应用（1 小时+）

1. 研究 RV32 核心的实现细节
2. 编写自己的测试程序
3. 使用 Vivado 的综合和实现功能
4. 查看资源使用情况

---

## 📋 集成清单

- ✅ PowerShell 自动化脚本：`vivado_run.ps1`
- ✅ TCL 项目脚本：`vivado_*.tcl`
- ✅ 快速开始指南：`VIVADO_2018_QUICK_START.md`
- ✅ 详细使用指南：`VIVADO_GUIDE.md`
- ✅ 兼容性报告：`VIVADO_2018_COMPATIBILITY.md`
- ✅ 代码完全兼容 SystemVerilog
- ✅ 支持 Vivado 2018.1+

---

## 💬 反馈与支援

如有问题：

1. 查看 [常见问题](VIVADO_2018_QUICK_START.md#常见问题)
2. 检查 [故障排除](VIVADO_2018_QUICK_START.md#故障排除)
3. 查看生成的日志：`vivado_sim.log`、`vivado_create.log`

---

## 🎓 示例工作流（完整示例）

### 场景：验证 ADD 指令

```powershell
# 1. 进入项目目录
cd c:\Users\YourName\Desktop\code\VerilogProjects

# 2. 创建 Vivado 项目
.\vivado_run.ps1 -Create

# 3. 打开 Vivado GUI 查看项目结构
# .\vivado_run.ps1 -GUI

# 4. 运行仿真
.\vivado_run.ps1 -RunSim

# 5. 查看输出
# [TB] loading program: tests/addi.hex
# [TB] PASS: ram[0]=XXXXXXXX ram[1]=1

# 6. 修改 rv32/rtl/rv32_alu.v 或其他文件
# ...修改代码...

# 7. 重新运行仿真
.\vivado_run.ps1 -RunSim

# 8. 在 Vivado GUI 中查看波形和调试信息
# .\vivado_run.ps1 -GUI
```

---

## 🎉 总结

现在你可以：

1. ✅ **在 Vivado 2018 中运行 RV32 仿真**
2. ✅ **自动化管理项目和测试**
3. ✅ **使用 GUI 进行交互式调试**
4. ✅ **生成行为仿真波形**
5. ✅ **（可选）进行综合和实现**

---

**集成完成时间：** 2026-04-12  
**项目状态：** ✅ 就绪  
**维护者：** Stomatra

