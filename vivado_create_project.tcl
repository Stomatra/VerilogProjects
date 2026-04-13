# ============================================================
# Vivado 2018 项目创建脚本
# 功能: 创建 rv32 仿真项目
# 使用: vivado -mode batch -source vivado_create_project.tcl
# ============================================================

# 设置项目参数
set project_name "rv32_sim"
set project_dir "vivado_project"
set rtl_dir "rv32/rtl"
set tb_dir "rv32/tb"

# 删除旧项目（如果存在）
if {[file exists $project_dir]} {
    puts "删除旧项目: $project_dir"
    file delete -force $project_dir
}

# 创建新项目
puts "创建新项目: $project_name"
create_project $project_name $project_dir -part xc7z020clg484-1

# 添加 RTL 源文件
puts "添加 RTL 源文件..."
add_files -fileset sources_1 \
    $rtl_dir/rv32_pkg.svh \
    $rtl_dir/rv32_alu.sv \
    $rtl_dir/rv32_branch.sv \
    $rtl_dir/rv32_decode.sv \
    $rtl_dir/rv32_imm.sv \
    $rtl_dir/rv32_mem_if.sv \
    $rtl_dir/rv32_regfile.sv \
    $rtl_dir/rv32_core.sv \
    $rtl_dir/rv32_top.sv

# 添加仿真源文件
puts "添加仿真源文件..."
add_files -fileset sim_1 $tb_dir/tb_rv32.sv

# 设置仿真顶层
set_property top tb_rv32 [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# 配置仿真设置
set_property xsim.simulate.runtime 5000ns [get_filesets sim_1]
set_property xsim.compile.additional_flags -v [get_filesets sim_1]

# 设置 include 路径
set_property include_dirs $rtl_dir [get_filesets sim_1]
set_property include_dirs $rtl_dir [get_filesets sources_1]

# 保存项目
save_project

puts "✅ 项目创建成功！"
puts "项目位置: $project_dir/$project_name.xpr"
puts ""
puts "后续操作:"
puts "  方法 1: 使用 GUI"
puts "    vivado vivado_project/rv32_sim.xpr"
puts "    然后在 Vivado 中点击 'Run Simulation' 运行仿真"
puts ""
puts "  方法 2: 使用命令行（自动运行仿真）"
puts "    vivado -mode batch -source vivado_run_sim.tcl"
puts ""
