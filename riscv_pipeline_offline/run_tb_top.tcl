open_project riscv_pipeline_offline.xpr
set_property top tb_top [get_filesets sim_1]
add_files -fileset sim_1 -norecurse {riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv}
add_files -fileset sim_1 -norecurse {riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/mem/program.mem}
update_compile_order -fileset sim_1
set_property -name {xsim.more_options} -value {-testplusarg PROGRAM_MEM=riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/mem/program.mem} -objects [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
run all
exit
