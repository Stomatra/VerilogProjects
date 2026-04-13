set project_name "rv32_sim"
set project_dir "vivado_project"
set rtl_dir "rv32/rtl"
set tb_dir "rv32/tb"

if {[file exists $project_dir]} {
    puts "删除旧项目..."
    file delete -force $project_dir
}

puts "创建项目: $project_name"
create_project $project_name $project_dir -part xc7z020clg484-1

puts "添加源文件..."
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

puts "添加仿真源文件..."
add_files -fileset sim_1 $tb_dir/tb_rv32.sv

set_property top tb_rv32 [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property include_dirs $rtl_dir [get_filesets sim_1]

save_project_as $project_name $project_dir -force

puts "? 项目创建完成"
