open_project {<repo>/riscv_pipeline_offline/riscv_pipeline_offline.xpr}
add_files -norecurse {<repo>/riscv_pipeline_offline/riscv_pipeline_offline.srcs/sources_1/imports/src/uart_monitor.sv}
reset_run synth_1
after 3000
launch_runs synth_1 -jobs 4
