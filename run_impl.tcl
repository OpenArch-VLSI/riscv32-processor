open_project <repo>/riscv_pipeline_offline/riscv_pipeline_offline.xpr

# Reset runs
reset_run synth_1

# Set aggressive runtime optimization to prevent hanging on MUX inference
set_property strategy Flow_RuntimeOptimized [get_runs synth_1]

# Launch synthesis
puts "=== RUNNING SYNTHESIS ==="
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "Synthesis failed!"
    exit 1
}

# Launch implementation and bitstream
puts "=== RUNNING IMPLEMENTATION & BITSTREAM ==="
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "Implementation failed!"
    exit 1
}

puts "=== BITSTREAM GENERATION COMPLETE ==="
exit 0
