open_project <repo>/riscv_pipeline_offline/riscv_pipeline_offline.xpr
reset_run synth_1
set_property strategy Flow_RuntimeOptimized [get_runs synth_1]
launch_runs impl_1 -to_step write_bitstream -jobs 4
puts "Build launched! You can monitor the progress in the 'Design Runs' tab."
