open_project riscv_pipeline_offline/riscv_pipeline_offline.xpr
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
  puts "SYNTHESIS FAILED"
  exit 1
}
puts "SYNTHESIS COMPLETE"
launch_runs impl_1 -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
  puts "IMPLEMENTATION FAILED"
  exit 1
}
puts "IMPLEMENTATION COMPLETE"
open_run impl_1
report_timing_summary -file riscv_pipeline_offline/timing_report.txt
report_utilization -file riscv_pipeline_offline/utilization_report.txt
puts "BUILD SUCCESS"
exit
