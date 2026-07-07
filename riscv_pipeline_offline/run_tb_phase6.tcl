open_project riscv_pipeline_offline.xpr
set_property top tb_phase6 [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
run all
exit
