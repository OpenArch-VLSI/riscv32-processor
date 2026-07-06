# No-Board Execution Plan

This document outlines the project phases and their executability while the PYNQ-Z2 board is unavailable.

## What to Do Next (Without the Board)

Since the board is not available, you are blocked *only* from physical hardware verification. You are **not** blocked from RTL development, simulation, synthesis, and implementation.

**Immediate Next Steps (Board Independent):**
Phases 0–12 are complete in simulation and synthesis. Currently, the only remaining work that blocks closing these phases entirely is the mandatory physical hardware verification upon board arrival (see `docs/board_arrival_checklist.md`). 
Phase 13 (Dual-Core SoC Extension) is the next unstarted phase, but it is explicitly marked as long-term and optional; it should not be started before the baseline physical hardware bring-up is complete. Therefore, there are no immediate board-independent development steps left.

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
| **Phase 8** | Branch Prediction & CPI Experiments | **100% in Simulation** (CPI=1.258 on branch_sort.mem — see results/phase8_cpi_metrics.txt; baseline not measured without RTL change) | On-board benchmark timings (defers until board available). |
| **Phase 9** | Custom Packed-SIMD Extension | **100%** (9/9 tb_phase9.sv tests PASS, verified 2026-06-28) | Physical SIMD benchmark execution on board and speedup measurement. |
| **Phase 10** | Real Workloads and Benchmark Demos | **90%** (Workload suite creation, simulated cycle/CPI reports) | Physical hardware measurement. |
| **Phase 11** | Memory System and Bus Cleanup | **100%** (Internal signal-bundle peripheral bus in `mem_stage.sv`; `tb_memory_map.sv` regression coverage; memory-map doc updated) | None — Phase 11 has no board-dependent component. |
| **Phase 12** | Optional Peripherals | **100% executable without board** (LED control register, button/switch input register, and PWM peripheral — all simulation-testable with self-checking testbenches; SPI master and VGA dropped from scope) | Physical confirmation that LEDs, buttons/switches, and PWM output behave correctly on real PYNQ-Z2 hardware. |
| **Phase 13** | Dual-Core SoC Extension | **0%** (Not started — no dual-core RTL exists in this codebase) | Full dual-core implementation: second core, shared memory/mailbox, bus arbiter, and final board demo. |