open_project {c:/Users/nayak/Desktop/riscv32-processor/riscv_pipeline_offline/riscv_pipeline_offline.xpr}
# uart_monitor.sv, mailbox.sv and dual_core_top.sv are already registered in the project
set_property top fpga_top [current_fileset]
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
