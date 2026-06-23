# No-Board Execution Plan

This document outlines the project phases and their executability while the PYNQ-Z2 board is unavailable.

## What to Do Next (Without the Board)

Since the board is not available, you are blocked *only* from physical hardware verification. You are **not** blocked from RTL development, simulation, synthesis, and implementation.

**Immediate Next Steps (Board Independent):**
1. **Phase 4 (UART Monitor and Program Loader) - Simulation Verification:** Run a Vivado/xsim simulation with `fpga_top` as the DUT to validate the UART monitor command parser FSM end-to-end.
2. **Phase 5 (Traps, Exceptions, and Timer Interrupts):** Start implementing the trap logic (CSRs: `mepc`, `mcause`, `mtvec`, `mstatus`), `ECALL`/`EBREAK` trap entry, timer peripheral (`0xC0000010`), and test them extensively in simulation.
3. **Phase 6 (RV32M Multiply/Divide Extension):** Implement the `MUL` family (and optionally `DIV`), adding execution support, pipeline stalls if needed, and verify with self-checking testbenches.
4. **Phase 7 (Run Small C Programs):** Build the C toolchain flow, create a linker script, startup code, `putchar` for UART, and compile simple C demos (like Fibonacci or bubble sort) into `.mem` files. Verify them in simulation using the monitor/loader flow.

## Phase Executability Analysis

| Phase | Description | Executable w/o Board | Deferred for Board |
|-------|-------------|----------------------|--------------------|
| **Phase 0** | Baseline Polish and Hardware Demo | **50%** (Bitstream, timing, constraints done) | Real UART terminal proof, terminal log/video, physical setup confirmation. |
| **Phase 1** | Reproducible Software & Test Tooling | **100%** (Assembler, build script, generated memory done) | None |
| **Phase 2** | Complete the RV32I Base More Honestly | **100%** (Subword ops, FENCE/NOP, ECALL halt done) | None |
| **Phase 3** | Debugging and Reliability | **100%** (MMIO debug, trace buffer, sim checks done) | None |
| **Phase 4** | UART Monitor and Program Loader | **85%** (RTL, debug ports, host loader script done) | Physical board test with `tools/mem_to_load_commands.py` over real USB-UART. |
| **Phase 5** | Traps, Exceptions, and Timer Interrupts | **90%** (Trap CSRs, entry/return logic, timer MMIO, full sim) | Final trap/timer demo running on the real board. |
| **Phase 6** | RV32M Multiply/Divide Extension | **95%** (RTL, stall logic, timing closure, full sim) | Running an RV32M benchmark on the physical board. |
| **Phase 7** | Run Small C Programs | **90%** (Linker, startup, C runtime, simulated C programs) | Real C benchmark execution on the board. |
| **Phase 8** | Branch Prediction & CPI Experiments | **90%** (Predictor RTL, branch metrics, CPI comparison in sim) | On-board benchmark timings. |
| **Phase 9** | Custom Packed-SIMD Extension | **90%** (Custom opcode RTL, tests, data-parallel demo in sim) | On-board execution and speedup report. |
| **Phase 10** | Real Workloads and Benchmark Demos | **90%** (Workload suite creation, simulated cycle/CPI reports) | Physical hardware measurement. |
| **Phase 11** | Memory System and Bus Cleanup | **100%** (Internal bus definition, memory map overhaul, sim) | None |
| **Phase 12** | Optional Peripherals | **0-100%** (Depends on peripheral. SPI/PWM can be sim'd. LEDs/VGA require board.) | Physical interaction (LEDs, VGA output, switches). |
| **Phase 13** | Dual-Core SoC Extension | **90%** (Multicore RTL, shared memory, bus arbiter, sim demo) | Final dual-core physical board demo. |
