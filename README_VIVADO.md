# 🏭 Vivado 2018 运行指南 - 简化版

> ⚡ **如果你只想快速运行，就看这个文档。**

---

## 🎯 三步启动

### 1️⃣ 打开 PowerShell

在项目根目录按 **Shift + 右键**，选择"在此处打开 PowerShell"

```powershell
PS C:\...\VerilogProjects>
```

### 2️⃣ 创建 Vivado 项目（首次）

```powershell
.\vivado_run.ps1 -Create
```

**输出：** 创建 `vivado_project/` 目录

### 3️⃣ 运行仿真

```powershell
.\vivado_run.ps1 -RunSim
```

**输出：** 
```
[TB] loading program: tests/addi.hex
[TB] PASS: ram[0]=XXXXXXXX ram[1]=1
```

✅ **完成！**

---

## 🎮 其他操作

### 打开 Vivado GUI

```powershell
.\vivado_run.ps1 -GUI
```

### 运行不同的测试

```powershell
.\vivado_run.ps1 -RunSim -HexFile tests/branch.hex
```

### 查看脚本帮助

```powershell
.\vivado_run.ps1
```

---

## ❓ 出错了？

### 错误 1："vivado: command not found"

**解决：** 配置 Vivado 路径

```powershell
# Windows 下运行此命令
& "C:\Xilinx\Vivado\2018.3\settings64.bat"

# 然后重新打开 PowerShell 重试
```

### 错误 2："Cannot find include file"

**解决：** 重新创建项目

```powershell
Remove-Item vivado_project -Recurse -Force
.\vivado_run.ps1 -Create
```

### 错误 3：其他问题

查看详细日志：
```powershell
Get-Content vivado_sim.log
```

---

## 📚 更多信息

| 需求 | 文档 |
|------|------|
| 快速开始（完整步骤） | [VIVADO_2018_QUICK_START.md](VIVADO_2018_QUICK_START.md) |
| 详细功能说明 | [VIVADO_GUIDE.md](VIVADO_GUIDE.md) |
| 兼容性验证 | [VIVADO_2018_COMPATIBILITY.md](VIVADO_2018_COMPATIBILITY.md) |
| 项目概览 | [INTEGRATION_SUMMARY.md](INTEGRATION_SUMMARY.md) |
| 多工具对比 | [README_VIVADO_SUPPORT.md](README_VIVADO_SUPPORT.md) |

---

## 🔗 快速链接

- [Vivado 2018 官网](https://www.xilinx.com/)
- [RISC-V 规范](https://riscv.org/)
- [GTKWave 波形查看](http://gtkwave.sourceforge.net/)

---

**创建时间：** 2026-04-12  
**维护者：** Stomatra

