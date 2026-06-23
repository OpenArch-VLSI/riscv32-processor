# run_sim_live.tcl
# Add the new fpga_top testbench to the simulation fileset
add_files -fileset sim_1 -norecurse <repo>/riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/sim/tb_fpga_top.sv
update_compile_order -fileset sim_1

# Set it as the active top-level simulation module
set_property top tb_fpga_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

# Launch the simulation and run for 3 milliseconds (enough for PLL lock + UART TX)
launch_simulation
run 3 ms
