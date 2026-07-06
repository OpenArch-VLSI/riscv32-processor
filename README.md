# Pipelined RV32IM RISC-V Processor

A 32-bit, 5-stage pipelined RISC-V processor core written in SystemVerilog,
targeting the PYNQ-Z2 (Zynq-7000) FPGA.

## Features

| Feature | Description |
|---------|-------------|
| **ISA** | RV32I base + RV32M multiply + custom packed-SIMD (PADD8/PSUB8/PMAXU8/PMINU8/PAVG8) |
| **Pipeline** | 5-stage (IF, ID, EX, MEM, WB) with forwarding, load-use stalls, branch flush |
| **Branch Prediction** | 64-entry BHT dynamic predictor |
| **Traps & CSRs** | M-mode CSRs, ECALL/EBREAK, timer interrupts, MRET |
| **UART** | TX/RX at 115200 baud with interactive monitor (help/load/run/reset/regs/mem/perf/trace) |
| **Board Peripherals** | Internal signal-bundle MMIO bus (Phase 11); LED control, debounced button/switch input, and PWM output registers (Phase 12) |
| **C Toolchain** | Custom linker script, C runtime, and benchmark suite in `sw/` |
| **Synthesis** | 7,127 LUTs (13.4%), WNS +5.265 ns @ 25 MHz on xc7z020 |

## Repository Structure

| Directory | Contents |
|-----------|----------|
| `riscv_pipeline_offline/` | Vivado project, RTL sources, testbenches, constraints |
| `sw/` | C toolchain, linker script, runtime, benchmarks |
| `results/` | Benchmark results and performance reports |
| `tools/` | Automation scripts (loader, report generation) |
| `docs/` | Architecture docs, ADRs, verification, guides |

## Getting Started

1. Clone the repository.
2. Open Vivado and load `riscv_pipeline_offline/riscv_pipeline_offline.xpr`.
3. Or use TCL automation:
   - `source run_synthesis.tcl` -- synthesis only
   - `source run_build.tcl` -- full synthesis + implementation

See `docs/hardware/setup.md` for board wiring and build details.

## License

Apache License 2.0
