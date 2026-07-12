open_project riscv_pipeline_offline.xpr
set_property top tb_c_program [get_filesets sim_1]
add_files -fileset sim_1 -norecurse {riscv_pipeline_offline.srcs/sim_1/imports/sim/tb_c_program.sv}
update_compile_order -fileset sim_1
set_property -name {xsim.more_options} -value {-testplusarg PROGRAM_MEM=../../../../../sw/branch_sort.mem} -objects [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
run all
exit
