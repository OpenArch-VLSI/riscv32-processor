set script_dir [pwd]

if {[current_project -quiet] eq ""} {
    open_project $script_dir/riscv_pipeline_offline/riscv_pipeline_offline.xpr
}

# Ensure the simulation top is correct
set_property top tb_c_program [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

set benchmarks [list "scalar_checksum.mem" "simd_checksum.mem" "branch_sort.mem"]
set xsim_dir "$script_dir/riscv_pipeline_offline/riscv_pipeline_offline.sim/sim_1/behav/xsim"

# Create the xsim working directory if it doesn't exist
file mkdir $xsim_dir

foreach mem $benchmarks {
    puts "================================================================"
    puts ">>> RUNNING BENCHMARK SIMULATION: $mem"
    puts "================================================================"
    
    # Copy the relevant .mem file into the xsim working directory as program.mem
    file copy -force "$script_dir/sw/$mem" "$xsim_dir/program.mem"
    
    set_property -name {xsim.simulate.xsim.more_options} -value "-testplusarg PROGRAM_MEM=$script_dir/sw/$mem" -objects [get_filesets sim_1]
    
    launch_simulation
    run -all
    close_sim
    
    puts ">>> FINISHED BENCHMARK: $mem"
    puts "================================================================"
}
