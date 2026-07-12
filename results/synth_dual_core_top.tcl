set src_files [glob c:/Users/nayak/Desktop/riscv32-processor/riscv_pipeline_offline/riscv_pipeline_offline.srcs/sources_1/imports/src/*.sv]
foreach file $src_files {
    read_verilog -sv $file
}
synth_design -top dual_core_top -part xc7z020clg400-1
exit
