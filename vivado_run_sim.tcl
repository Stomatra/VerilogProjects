# ============================================================
# Vivado 2018 仿真运行脚本
# 功能: 编译、运行仿真、导出波形
# 使用: vivado -mode batch -source vivado_run_sim.tcl
# ============================================================

# 打开项目
open_project vivado_project/rv32_sim.xpr

# 设置仿真参数
set_property -name {xsim.simulate.runtime} -value {5000ns} [get_filesets sim_1]

# 添加代位参数（运行 tests/addi.hex）
# 注意：Vivado 2018 中通过 -testplusarg 传递参数给仿真
set_property -name {xsim.compile.addtheflag} -value {-testplusarg hex=tests/addi.hex} [get_filesets sim_1]

puts "编译 RTL 和仿真源..."
launch_simulation -simset sim_1 -mode behavioral

puts "等待仿真完成..."
# 运行仿真直到完成
run all

# 导出波形
puts "导出波形文件..."
# xsim 会自动生成 .vcd 文件到指定目录

puts "✅ 仿真完成！"
puts "波形文件应该位于: sim_1/behav/xsim_0.vcd"
puts ""

# 关闭仿真
close_sim

# 关闭项目
close_project

puts "项目已关闭"
