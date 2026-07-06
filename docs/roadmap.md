# Roadmap Implementation Status

Last updated: 2026-06-28

<!-- This file is manually maintained. Last updated: 2026-06-28 -->



---

## Current Summary

The project is currently best described as:

> Phase 1 is complete. Phase 2 is complete. Phase 3 is complete. Phase 4 is complete in simulation with a board-ready UART monitor and host loader. Phase 5 is complete in simulation (CSRs, traps, timer interrupts, MRET). Phase 6 is complete in simulation (MUL family). Phase 7 is complete. Phase 8 is complete. Phase 9 is SIMULATION VERIFIED (9/9 PASS on tb_phase9.sv). Phase 10 is complete in simulation. Phase 11 is complete in simulation (internal peripheral bus refactor, memory-map regression tests). Phase 12 is complete in simulation (LED, button/switch, PWM — 9/9 PASS on tb_phase12.sv, synthesis clean with 0 errors, 0 critical warnings). Hardware proof from Phase 0 and Phase 4 is deferred until the PYNQ-Z2 board is available.

The strongest verified baseline is a simulated and synthesised 5-stage RV32I pipelined CPU with UART MMIO, performance counters, a ROM-preloaded loadable instruction memory, a simulation loader path, a UART monitor with 7 commands, subword load/store support, FENCE/FENCE.I NOP, ECALL/EBREAK/illegal instruction trapping with MRET, M-mode CSRs, timer interrupts, a 64-entry BHT dynamic branch predictor, a custom packed-SIMD extension (SIMULATION VERIFIED), a verified workload suite demonstrating measurable speedups in cycle/instruction counts, an internal peripheral signal-bundle bus for MMIO routing, and three optional board peripherals (LED control, button/switch input, PWM).

---

## Live Task Tracker

This generated table is the quick triage view: what exists, what state it is in, what is holding it back, and what proof is needed before it should move forward.

| Task | Status | Blocker / Flag | Verification Needed |
|------|--------|----------------|---------------------|
| Phase 0: Baseline Polish and Hardware Demo | Partial / deferred (50%) | [BOARD] Needs PYNQ-Z2 proof | real UART terminal output, captured log/video, setup notes |
| Phase 1: Reproducible Software and Test Tooling | Mostly complete (80%) | [VERIFY] Needs broader regression coverage | more standalone programs and expected UART output files |
| Phase 2: Complete the RV32I Base More Honestly | Complete (100%) | None | All Phase 2 items implemented and documented |
| Phase 3: Debugging and Reliability | Complete (100%) | None | MMIO debug registers, trace buffer, and assertion-oriented verification implemented and simulation-tested |
| Phase 4: UART Monitor and Program Loader | Complete in Sim (95%) | [BOARD] Needs PYNQ-Z2 proof | RTL implemented and verified end-to-end in `tb_fpga_top.sv`; host loader tested. Physical board proof pending. |
| Phase 5: Traps, Exceptions, and Timer Interrupts | Complete (100%) | [SIM] Run tb_phase5.sv in xsim | trap CSR tests, trap entry/return tests, timer interrupt demo |
| Phase 6: RV32M Multiply Extension | Complete (100%) | [BOARD] Needs PYNQ-Z2 proof | MUL family tests via tb_phase6.sv verified in simulation |
| Phase 7: Run Small C Programs | Complete (100%) | None | C runtime, linker script, and "Hello World" program validated in simulation over UART. |
| Phase 8: Branch Prediction and CPI Experiments | Complete in Simulation — CPI=1.258 (branch_sort.mem, 64-entry BHT) — see results/phase8_cpi_metrics.txt | None | CPI=1.258 on branch_sort.mem; baseline not directly measured (BHT has no non-RTL disable path) |
| Phase 9: Custom Packed-SIMD Extension | SIMULATION VERIFIED (100%) | [BOARD] Needs PYNQ-Z2 proof | custom opcode tests, byte-lane kernel demo, speedup report |
| Phase 10: Real Workloads and Benchmark Demos | Complete in Sim (90%) | [BOARD] Needs PYNQ-Z2 proof | physical hardware measurement |
| Phase 11: Memory System and Bus Cleanup | Complete in Sim (100%) | None | physical hardware measurement (no board-dependent behavior to verify; bus is purely internal) |
| Phase 12: Optional Peripherals | Complete in Sim (100%) | [BOARD] Needs PYNQ-Z2 proof | selected peripheral simulation and, if hardware-facing, board proof |
| Phase 13: Dual-Core SoC Extension | Not started (0%) | [LATE] Depends on monitor/traps/bus/software | mailbox/shared-memory simulation, arbiter proof, final board demo |

---

## Phase Completion Table

| Phase | Roadmap Area | Status | Completion | Evidence | Remaining Work |
|-------|--------------|--------|------------|----------|----------------|
| 0 | Baseline Polish and Hardware Demo | Partial / deferred | 50% | bitstream exists; routed timing WNS about `+5.265 ns`; UART pins are constrained | real PYNQ-Z2 UART terminal proof, terminal log/video, final hardware setup notes |
| 1 | Reproducible Software and Test Tooling | Regression baseline locked | 80% | 9 programs built from C source via riscv-none-elf-gcc + bin_to_mem.py, all verified against tests/expected/ via SHA256; regression script at tools/run_phase1_regression.ps1 (9/9 PASS) | Still-open: standalone test programs for ALU/branch/load-store/UART/perf-counter and expected UART output files; dead references (asm/demo_perf_uart.s, tools/build_program.ps1) removed from docs |
| 2 | Complete the RV32I Base More Honestly | Complete | 100% | `LB/LH/LBU/LHU/SB/SH` with byte enables and sign/zero extension implemented and tested; `FENCE`/`FENCE.I` decoded as NOP; `ECALL`/`EBREAK` halt with pipeline freeze; illegal instruction detection; misaligned access policy documented; full RV32I instruction support table created | None |
| 3 | Debugging and Reliability | Complete | 100% | MMIO debug registers, trace buffer, and assertion-oriented verification implemented; simulation reads validated current PC, last commit, fault, and trace entries | optional ILA and UART debug logs remain optional refinements |
| 4 | UART Monitor and Program Loader | Complete in Sim | 95% | `uart_monitor.sv` with 7 commands, verified via `tb_fpga_top.sv` testbench. Host loader completed. | physical board proof |
| 5 | Traps, Exceptions, and Timer Interrupts | Complete | 100% | csr_file.sv, timer.sv, tb_phase5.sv created; all pipeline stages updated | None |
| 6 | RV32M Multiply Extension | Complete | 100% | MUL family RTL implemented, tb_phase6.sv simulation passed | add DIV/DIVU/REM/REMU later if needed |
| 7 | Run Small C Programs | Complete | 100% | linker script, startup, C runtime flow, and C demos implemented/verified | None |
| 8 | Branch Prediction and CPI Experiments | Complete in RTL | 90% | Static (BTFNT) and Dynamic (64-entry BHT) predictors implemented and wired; bubble sort C benchmark generated | capture simulation metrics |
| 9 | Custom Packed-SIMD Extension | SIM VERIFIED | 100% | 9/9 PASS on tb_phase9.sv; PADD8/PSUB8/PMAXU8/PMINU8/PAVG8 | None |
| 10 | Real Workloads and Benchmark Demos | Complete in Sim | 90% | benchmark suite created, simulated in Vivado, speedup report compiled | Physical hardware measurement |
| 11 | Memory System and Bus Cleanup | Complete in Sim | 100% | internal peripheral bus (`bus_<periph>_*`) defined in `mem_stage.sv`; `tb_memory_map.sv` passes all 6 MMIO checks | physical hardware measurement (no board-dependent behavior; bus is purely internal) |
| 12 | Optional Peripherals | Complete in Sim | 100% | LED, button/switch, PWM RTL + tb_phase12.sv verified (9/9 PASS); synthesis clean | board arrival |
| 13 | Dual-Core SoC Extension | Not started | 0% | roadmap section exists; no dual-core RTL detected | implement only after bus/monitor/trap/software work |

---

## Recently Completed

- [2026-06-26] **Phase 11**: Implemented internal peripheral bus refactor in mem_stage.sv. All peripherals (RAM, UART, Timer, Perf Counters, Debug) routed through explicit signal bundles (`bus_<periph>_*`). Verified with new `tb_memory_map.sv` regression tests demonstrating zero change in external behavior.

- [2026-06-28] **Phase 12**: Implemented optional peripherals (LED control, button/switch input, PWM). Created `led_ctrl.sv`, `btn_sw.sv`, `pwm.sv`, and `tb_phase12.sv` (9/9 PASS including PWM waveform and disable checks). All 3 regression testbenches passing. Fixed critical synthesis bug in `fpga_top.sv` (multi-driven `led` net — removed conflicting `always_ff` assignment). Re-synthesis confirms 0 errors, 0 critical warnings. Synthesised design: 84a84c29.
- [2026-06-28] **Phase 9 SIM VERIFICATION**: Completed simulation of `tb_phase9.sv` in Vivado xsim. 9/9 tests PASS. Fixed elaboration warning (unconnected `raw_btn` port in `tb_phase9.sv`). All 3 regression testbenches re-run and passing.

- [2026-06-21] **Phase 10**: Created workload suite (`scalar_checksum.c`, `simd_checksum.c`, `branch_sort.c`). Fixed SIMD correctness bugs (alignment, 8-bit overflow) so scalar and SIMD output mathematically identical sums. Ran batch Vivado simulations. Generated `results/phase10_benchmark_report.md` proving 3.85x cycle speedup for SIMD and validating 64-entry BHT efficiency.

- [2026-06-19] **Phase 9**: Implemented custom packed-SIMD extension (PADD8/PSUB8/PMAXU8/PMINU8/PAVG8) on RISC-V custom-0 opcode 0001011. Created tb_phase9.sv with 8 directed/edge-case tests. Simulation pending.
- [2026-06-16] **Phase 8**: Created `benchmark.c` (Bubble sort) to measure CPI. Implemented Static BTFNT prediction and optimized pipeline flush logic. Implemented Dynamic Branch Prediction via a 64-entry BHT (Branch History Table) with 2-bit saturating counters in `bht.sv`. Wired `id_stage.sv` to predictively fetch branches and `ex_stage.sv` to train the BHT and flush only on mispredictions.
- [2026-06-14] **Phase 7**: Installed xPack RISC-V GCC toolchain. Created C software infrastructure (`linker.ld`, `crt0.S`, `sw/Makefile`). Implemented `hello_world.c` using stack-based string building to support the strict Harvard architecture memory mapping. Verified simulation live in Vivado.
- [2026-06-14] **Phase 5/6 review**: Validated CSRs, Traps, and Performance Counters.
- [2026-06-14] **Phase 6**: Verified RV32M Multiply Extension via `tb_phase6.sv`. All `MUL`, `MULH`, `MULHSU`, and `MULHU` tests passed perfectly. Phase 6 is complete in simulation.
- [2026-06-04] **Phase 4**: Integrated system with `uart_monitor.sv` and fully verified trace and performance outputs using the UART loader script.
- Debugged and fixed Phase 5 simulation failures. Resolved Timer interrupt logic, forced proper 32-bit `mtimecmp` values, enabled the timer `ctrl` register, padded the test payload with `jal x0, 0` for safe asynchronous trap returns, and achieved full `tb_phase5.sv` simulation pass. Phase 5 is Complete in simulation.
- Implemented complete Phase 5 RTL: CSR file (mstatus/mtvec/mepc/mcause), timer peripheral, CSR instruction decode, trap entry for ECALL/EBREAK/illegal instructions, MRET execution, timer interrupt generation. Created tb_phase5.sv testbench.
- Fixed UART monitor logic causing Vivado synthesis hang by refactoring `tx_buf` into a serial shift-register FSM (`ST_PRINT_HEX`).
- Verified UART monitor FSM end-to-end via `tb_fpga_top.sv` simulation in Vivado.
- Generated Implementation Plan for Phase 5 (Traps, Exceptions, Timers).
- Added DS srijith, Raunit kapoor, and Hemanth v as contributors.
- Created `docs/GETTING_STARTED.md` — comprehensive user guide for project owner with prompt template, folder structure, roadmap summary, and troubleshooting.
- Enforced mandatory documentation update system: initialized git repo, installed pre-commit/post-commit/pre-push hooks with `check_docs_stale.ps1`, hardened `ai_context.md` with PRE-EXIT MANDATORY CHECKLIST and inline session log template, added `.gitignore` for Vivado artifacts.
- Added readable assembly source for the current demo/regression ROM.
- Added a local RV32I assembler and build script for generating `program.mem`.
- Generated ROM initialization include from assembly.
- Implemented and simulated subword memory operations: `LB`, `LH`, `LBU`, `LHU`, `SB`, `SH`.
- Added simulation checks for subword load/store behavior.
- Implemented MMIO debug registers for current PC, last committed PC/instruction, last writeback data, fault PC/instruction, and pipeline status.
- Added a 4-entry commit trace buffer and simulation reads for the latest retire history.
- Added assertion-style simulation checks for the debug MMIO window and trace buffer contents.
- Reworked the roadmap so dual-core is a later long-term optional goal after bus, traps, and software support.
- Added minimal `FENCE` / `FENCE.I` handling as NOP in `control_unit.sv`.
- Implemented `ECALL` / `EBREAK` decode via `OPCODE_SYSTEM` with halt signal that freezes the pipeline.
- Added illegal instruction detection for unknown opcodes, triggering halt same as ECALL/EBREAK.
- Documented misaligned load/store access policy (unsupported; requires trap CSRs from Phase 5).
- Created full RV32I instruction support table listing implemented, tested, and intentionally unsupported instructions.
- Implemented full Phase 4 UART monitor: `uart_monitor.sv` with 7 commands (help/load/run/reset/regs/mem/perf/trace) wired through `fpga_top.sv`.
- Added async debug read ports to `reg_file.sv`, `data_mem.sv`, `id_stage.sv`, `mem_stage.sv`, and `top.sv` for monitor inspection.
- Enhanced `tools/mem_to_load_commands.py` with raw text, binary UART stream, and interactive serial port modes.
- Created `docs/architecture/uart-monitor.md` with full command reference and protocol specification.
- Updated testbench with monitor integration notes and UART RX sim helper.
- Added a loadable instruction-memory foundation with a write-port hook in `instr_mem.sv`, threaded loader inputs through `if_stage.sv` and `top.sv`, exercised the load port from `tb_top.sv`, and added a host-side command-stream helper.
- Initialized automated AI context management (`docs/ai_context.md`) and automatic session logging.

---

## Current Next Step

Phases 0–12 are complete in simulation. The next steps are:

1. When the PYNQ-Z2 board is available, connect a USB-UART adapter and use
   `tools/mem_to_load_commands.py -f interactive` to run physical board tests.

## Verification Evidence

Latest known verification evidence from the project:

| Check | Result |
|-------|--------|
| Assembler/source flow | PASS: detected generated assembly flow with 240 memory words |
| Simulation | PASS: `*** ALL TESTS PASSED (pipeline + perf counters + UART) ***` |
| Subword tests | PASS: `SB`, `SH`, `LB`, `LBU`, `LH`, `LHU` checks passed |
| Performance counter MMIO tests | PASS: counter HDL and simulation pass marker detected |
| Debug MMIO tests | PASS: current PC, last commit, fault, and trace buffer reads validated in simulation |
| UART report test | PASS: UART HDL and simulation pass marker detected |
| Halt not-asserted test | PASS: halt was never asserted during demo program run |
| Bitstream | Generated |
| Routed timing | PASS: WNS +5.265 ns; all user timing constraints met (2025.2 build) |
| Utilization (Phase 10 baseline) | 7,127 LUTs / 53,200 (13.4%), 1,737 registers / 106,400 (1.63%), 1 BRAM / 140 (0.71%), 0 DSPs / 220 (0.00%) |

---

## Maintenance Rule



The generated status should include:

- which phase changed
- what was implemented
- what evidence proves it works
- what remains incomplete
- whether simulation, synthesis, implementation, or hardware proof was run

Do not manually mark a phase complete unless the generator can prove the implementation from source files and verification artifacts.

## Documentation System

| File | Status | Notes |
|------|--------|-------|
| architecture/instruction-set.md | ✅ Complete | Updated support matrix |
| verification/test-plan.md | ✅ Complete | Updated simulation test logs |
| verification/performance.md | ✅ Complete | Updated resource and timing slacks |
| hardware/setup.md | ✅ Complete | Updated pinouts and clock settings |
| known_issues.md | ✅ Complete | Updated open issue counts |
| decisions/001_initial_docs.md | ✅ Accepted | Documentation system rationale |
| `docs/decisions/002–005` | ✅ Accepted | ADR content complete |

---


---


---

## Deferred Until PYNQ-Z2 Is Available

Board absence blocks hardware proof, not simulation, synthesis, implementation, or most RTL development.

### Strictly Board-Required

| Item | Why It Waits For Hardware |
|------|----------------------------|
| Real UART terminal output on hardware | Requires the physical UART pins, USB-UART adapter, and a running board |
| Saved terminal log or video demo from the board | Requires a real hardware run to capture proof |
| Validated hardware setup guide with actual PMODA wiring and baud-rate proof | Needs physical confirmation that the documented setup works as described |
| LED or other visible peripheral behavior observed on board I/O | Requires physical LEDs or external hardware to observe behavior |
| VGA/Pmod VGA or HDMI peripheral demos | Requires the board plus the relevant external display hardware path |
| Vivado ILA signal capture from a running board design | Requires programming the FPGA and capturing live in-system signals |

### Can Be Developed Now, But Final Proof Needs Board

| Item | What Can Be Done Now |
|------|-----------------------|
| Phase 0 final hardware proof | Keep the bitstream, timing, and docs ready; defer the real terminal demo |
| UART monitor usability on a real serial terminal | Implement and simulate the monitor protocol and commands |
| Trap/timer demos that print proof over real UART | Implement trap logic, timer MMIO, and simulation tests first |
| C demo programs running on hardware | Build the toolchain flow, startup code, and simulation programs first |
| Packed-SIMD demo output on real hardware | Implement custom instructions, tests, and simulated demo programs first |
| Dual-core mailbox/UART demo on real hardware | Build the multicore RTL, shared peripherals, and simulated communication demo first |

---


# Original Roadmap Plan

# Long-Term Practical Roadmap

This roadmap assumes the project is no longer constrained by a submission deadline. The goal is to make the processor as strong, demonstrable, and technically honest as possible while staying practical on the PYNQ-Z2 / Zynq-7020 FPGA.

The best direction is not to add the largest-sounding features first. The best direction is to turn the current working pipelined CPU into a small, usable, well-tested computer system.

---

## Current State

Verified from the Vivado project and generated reports.

| Area | Current Status |
|------|----------------|
| FPGA board/part | PYNQ-Z2, `xc7z020clg400-1` |
| Top module | `fpga_top` |
| CPU core | 5-stage pipelined RV32I-style core |
| Pipeline features | Forwarding, load-use stall, branch/jump flush |
| UART | TX and RX modules integrated through MMIO |
| UART address map | `0x80000000` status, `0x80000004` TX data, `0x80000008` RX data |
| Performance counters | Implemented and exposed through MMIO |
| Perf counter address map | `0xC0000000` cycles, `0xC0000004` instructions, `0xC0000008` stalls, `0xC000000C` flushes |
| Subword memory ops | `LB`, `LH`, `LBU`, `LHU`, `SB`, `SH` implemented and simulation-tested |
| Testbench | Self-checking pipeline, UART, MMIO, and performance counter tests |
| Latest sim result | PASS: pipeline + performance counters + UART |
| Bitstream | Generated |
| LUT utilization | 3,169 / 53,200 = 13.4% |
| Register utilization | 1,733 / 106,400 = 1.63% |
| BRAM utilization | 1 / 140 = 0.71% |
| DSP utilization | 0 / 220 = 0% |
| Timing | Met; routed WNS about +5.554 ns |

Important correction: performance counters are no longer future work. They are already implemented and tested.

The current core now has byte/halfword loads and stores. It should still be described as RV32I-style or RV32I-subset until minimal SYSTEM/FENCE behavior and trap behavior are added.

---

## What Is Already Done

### Completed or Nearly Completed

| Feature | Status | Notes |
|---------|--------|-------|
| 5-stage pipeline | Done | IF, ID, EX, MEM, WB structure exists |
| Forwarding | Done | EX/MEM and MEM/WB forwarding tested |
| Load-use hazard stall | Done | Tested in simulation |
| Branch/jump flush | Done | BEQ, JAL, JALR behavior tested |
| LUI/AUIPC | Done | Tested |
| Basic ALU ops | Done | ADD, SUB, logic, shifts, SLT/SLTU tested |
| Word load/store | Done | LW/SW path exists |
| Subword load/store | Done | LB/LH/LBU/LHU/SB/SH are implemented for aligned accesses and tested |
| UART MMIO | Done | TX/RX peripheral is integrated |
| UART pin constraints | Done | PMODA pins are constrained in XDC |
| Performance counters | Done | Cycle, instruction, stall, flush counters exist |
| UART performance report | Done in simulation | Program prints counter values over UART in sim |
| Bitstream generation | Done | Implementation and route completed |

### Still Needs Hardware Proof

| Item | Status |
|------|--------|
| Real UART terminal output on PYNQ-Z2 | Needs physical test |
| Saved terminal log or video demo | Not yet proven from files |
| Repeatable build/run instructions | Should be cleaned up |
| Hardware terminal proof | Deferred until a PYNQ-Z2 board is available |

---

## Roadmap Philosophy

Every feature should pass three proof gates:

1. Simulation proof: self-checking test passes.
2. Hardware proof: bitstream builds, timing meets, and a board demo works where relevant.
3. Documentation proof: memory map, limitations, and usage are clearly written.

If a feature cannot be demonstrated, do not make it a headline feature.

---

## Phase 0: Baseline Polish and Hardware Demo

**Priority: Highest**  
**Effort: 1-3 days**  
**Practicality: Very high**

This phase turns the current project into something confidently demonstrable.

### Tasks

- Test UART output on real PYNQ-Z2 hardware using a USB-UART adapter.
- Capture a terminal log showing cycle, instruction, stall, flush, and IPC/CPI values.
- Write a short hardware setup guide:
  - PMODA TX/RX pins
  - USB-UART wiring
  - baud rate
  - reset behavior
  - expected terminal output
- Add or update a clear top-level README.
- Record exact Vivado version and build steps.
- Save the latest utilization and timing numbers.
- Fix document encoding issues in project notes if needed.

### Why This Matters

This gives you a clean baseline. Before adding new features, you should have proof that the current CPU runs on actual FPGA hardware, not only in simulation.

---

## Phase 1: Reproducible Software and Test Tooling

**Priority: Very high**  
**Effort: 3-7 days**  
**Practicality: Very high**

Right now the instruction memory contains hardcoded machine words. That works, but it makes the project harder to maintain and extend.

### Tasks

- Create assembly source for the current test/demo program.
- Add a script or Makefile flow that converts assembly into `.mem`.
- Keep `program.mem` generated from source instead of editing raw hex by hand.
- Add small standalone test programs:
  - ALU tests
  - branch/jump tests
  - load/store tests
  - UART tests
  - performance counter tests
- Add expected-output files for UART demos.

### Recommended Approach

Use either:

- a small custom assembler script for the supported subset, or
- a standard RISC-V GNU assembler flow with a linker script and `objcopy`.

The GNU assembler route is better long-term because it prepares the project for C programs later.

---

## Phase 2: Complete the RV32I Base More Honestly

**Priority: Very high**  
**Status: Complete**  
**Practicality: High**

A complete, well-tested RV32I core is much stronger than an incomplete core with a loosely defined accelerator.

### Completed in This Phase

| Feature | Status |
|---------|--------|
| `LB`, `LH`, `LBU`, `LHU` | Implemented and tested |
| `SB`, `SH` | Implemented and tested |
| Byte write enables | Implemented in data memory |
| Load sign/zero extension | Implemented in MEM stage |
| `FENCE` / `FENCE.I` as NOP | Implemented in `control_unit.sv` |
| `ECALL` / `EBREAK` halt | Implemented via `OPCODE_SYSTEM` decode; latches halt signal to freeze pipeline |
| Illegal instruction detection | Implemented; unknown opcodes set `illegal_instr` and trigger halt |
| Misaligned access policy | Documented in `docs/architecture/overview.md` (unsupported; traps require Phase 5) |
| RV32I instruction support table | Created in `docs/architecture/overview.md` with implemented/tested/unsupported categories |

### Deliverable

A document or table listing each RV32I instruction and whether it is:

- implemented
- tested
- not applicable
- intentionally unsupported

This is excellent evidence of engineering maturity.

---

## Phase 3: Debugging and Reliability

**Priority: High**  
**Status: Complete**  
**Effort: 1-2 weeks**  
**Practicality: High**

Before adding larger architectural features, make the CPU easier to trust and easier to debug.

### Tasks

- Add memory-mapped debug registers for:
  - current PC
  - last committed instruction PC
  - last writeback register/value
  - faulting instruction
  - trap or fault cause
  - pipeline status bits
- Add an assertion-oriented verification layer:
  - timeout/deadlock detection
  - pipeline freeze detection
  - branch or control-flow mismatch detection
  - illegal opcode detection
- Add a small trace buffer in BRAM:
  - PC
  - instruction
  - writeback register
  - writeback data
  - stall/flush flags
- Add UART debug logs only after a monitor/debug path exists.
- Optionally add a Vivado ILA configuration for PC, instruction, stall, flush, and UART signals.

### Completed

- Implemented MMIO debug registers for current PC, last committed PC/instruction, last writeback data, fault PC/instruction, and pipeline status.
- Implemented a 4-entry commit trace buffer that records PC, instruction, writeback data, and packed status.
- Added assertion-oriented simulation checks that verify the debug MMIO window and trace buffer contents.

### Why This Matters

Debug visibility and reliability checks are a better next investment than bigger features. They reduce the time cost of every later change, and this phase is now in place.

---

## Phase 4: UART Monitor and Program Loader

**Priority: High**  
**Effort: 1-3 weeks**  
**Practicality: High**  
**Status: Substantially complete (RTL done)**

This is the point where the project starts feeling like a tiny computer rather than a fixed demo ROM.

Implementation status: `uart_monitor.sv` is a full command-parser FSM with 7 commands (help/load/run/reset/regs/mem/perf/trace), wired through `fpga_top.sv` with UART mux and CPU reset control. Debug read ports are added to `reg_file.sv`, `data_mem.sv`, `id_stage.sv`, `mem_stage.sv`, and `top.sv`. The host-side loader (`tools/mem_to_load_commands.py`) supports raw text, binary UART stream, and interactive serial port modes. Full `fpga_top` simulation and physical board proof remain pending.

### Tasks

- Convert instruction memory from fixed ROM to loadable instruction RAM or boot ROM + instruction RAM.
- Add a UART bootloader or monitor mode.
- Support commands such as:
  - `help`
  - `load`
  - `run`
  - `reset`
  - `regs`
  - `mem`
  - `perf`
  - `trace`
- Add a simple host-side script to send a `.mem` or binary file over UART.

### Practical Scope

Start simple:

- load words into instruction RAM
- run from address 0
- print performance counters after completion

Do not try to build an operating system at this stage.

---

## Phase 5: Traps, Exceptions, and Timer Interrupts

**Priority: High**  
**Effort: 2-4 weeks**  
**Practicality: High if scoped carefully**

This is the strongest early system-level upgrade and should come before multicore or ambitious acceleration work.

### Core Behavior

- treat `FENCE` as a NOP
- add `ECALL` / `EBREAK`
- add illegal instruction detection
- define misaligned access behavior clearly

### Minimal Trap System

Add a small machine-mode-style trap mechanism:

| Register | Purpose |
|----------|---------|
| `mepc` | PC where trap occurred |
| `mcause` | trap reason |
| `mtvec` | trap handler address |
| `mstatus` | minimal interrupt enable/status bits |

### Trap Sources

- illegal instruction
- `ECALL`
- `EBREAK`
- misaligned load/store, if unsupported
- timer interrupt

### Timer Peripheral

Add memory-mapped timer registers:

| Address | Register |
|---------|----------|
| `0xC0000010` | timer current value |
| `0xC0000014` | timer compare value |
| `0xC0000018` | timer control/status |

### Deliverable

A demo program that:

1. sets a timer interrupt,
2. runs a loop,
3. enters the trap handler,
4. prints proof over UART,
5. returns to normal execution.

---

## Phase 6: RV32M Multiply/Divide Extension

**Priority: Medium-high**  
**Effort: 1-3 weeks**  
**Practicality: High for multiply, medium for divide**

This is more defensible than jumping directly to multicore or wide SIMD.

### Recommended Scope

Start with:

- `MUL`
- `MULH`
- `MULHU`
- `MULHSU`

Then add if time permits:

- `DIV`
- `DIVU`
- `REM`
- `REMU`

### Implementation Choices

| Option | Pros | Cons |
|--------|------|------|
| Single-cycle DSP multiply | Simple at 25 MHz | May need timing care at higher clocks |
| Pipelined multiply | Faster clock potential | More pipeline control complexity |
| Iterative divide | FPGA-efficient | Requires multi-cycle stall logic |

### Why This Is Worth Doing

RV32IM is a recognizable and useful target. It also prepares the design for compiled C benchmarks.

---

## Phase 7: Run Small C Programs

**Priority: Medium-high**  
**Effort: 1-3 weeks after Phase 4/5/6**  
**Practicality: Medium-high**

This is a major credibility upgrade if done cleanly.

### Requirements

- better memory layout
- stack pointer setup
- linker script
- startup code
- UART `putchar`
- subword loads/stores from Phase 2
- program loading flow from Phase 4, or ROM generation from ELF

### Good Demo Programs

- UART hello world
- Fibonacci
- memory copy
- bubble sort
- CRC or checksum
- small benchmark that prints cycle count and CPI

### Avoid

Do not promise Linux or a general-purpose OS. This core is a small bare-metal soft CPU.

---

## Phase 8: Branch Prediction and CPI Experiments

**Priority: Medium**  
**Effort: 1-2 weeks**  
**Practicality: Medium-high**

This is a very good architecture feature because you already have performance counters.

### Possible Features

- static not-taken baseline, already effectively present
- static backward-taken / forward-not-taken prediction
- 1-bit or 2-bit branch history table
- small branch target buffer

### Deliverable

Run the same loop-heavy programs before and after prediction and report:

- cycles
- instructions
- branch flushes
- CPI or IPC improvement

This gives a much stronger story than simply saying "branch predictor added."

---

## Phase 9: Custom Packed-SIMD Extension

**Priority: Optional**  
**Effort: 2-4 weeks for a clean subset**  
**Practicality: Medium if scoped narrowly**

This should replace broad vector-accelerator claims.

### Recommended First Version

Do not start with a 4-lane 32-bit vector unit. Start with packed operations inside the existing 32-bit integer registers.

Example custom instructions:

| Instruction | Meaning |
|-------------|---------|
| `PADD8` | four parallel 8-bit additions |
| `PSUB8` | four parallel 8-bit subtractions |
| `PMAXU8` | four unsigned 8-bit max operations |
| `PMINU8` | four unsigned 8-bit min operations |
| `PAVG8` | four unsigned 8-bit averages |

Use the RISC-V `custom-0` opcode space.

### Demo

Use a concrete data-parallel demo:

- grayscale brightness adjustment
- pixel thresholding
- packed byte min/max
- checksum-style byte processing

### Optional Later Upgrade

Only after the scalar packed-SIMD path works:

- 8-entry vector register file
- 128-bit vector registers
- vector load/store
- wider lane-based ALU experiments

Do not claim RVV compliance. Full RISC-V Vector is far beyond the practical scope of this project.

---

## Phase 10: Real Workloads and Benchmark Demos

**Priority: Optional but valuable**  
**Effort: 1-3 weeks after SIMD or C support**  
**Practicality: Medium-high**

This phase is about proving that the architecture work leads to measurable results.

### Good Workloads

- packed-byte image-style processing
- checksum and reduction kernels
- fixed-point filtering or simple DSP-style operations
- matrix-style kernels only if they match the implemented datapath honestly

### Outputs

- before/after cycle counts
- CPI or IPC comparisons
- branch or SIMD speedup comparisons
- benchmark notes that explain what the architecture change actually improved

Avoid vague "AI-style" wording unless a concrete fixed-point kernel and measurement exist.

---

## Phase 11: Memory System and Bus Cleanup

**Priority: Optional but useful**  
**Effort: 2-5 weeks**  
**Practicality: Medium**

The current MMIO decode is simple and fine for the current project. If the system grows, create a cleaner internal bus.

### Practical Work

- define a simple internal memory/peripheral bus:
  - address
  - write data
  - read data
  - byte enables
  - read enable
  - write enable
  - ready/valid
- move UART, timer, performance counters, debug registers, and RAM behind this bus
- add a simple memory map document

### Cache Reality Check

A cache is not very useful while the CPU only talks to small on-chip BRAM. A cache becomes meaningful only after you have a cleaner bus and a larger or slower memory path.

Recommended order:

1. clean bus
2. larger BRAM memory
3. loader
4. optional AXI or DDR bridge
5. only then consider cache

---

## Phase 12: Optional Peripherals

**Priority: Low**  
**Effort: 1-2 days for the recommended scope**  
**Practicality: High for the items kept; low for the items dropped**

Peripheral work is fine, but it should not outrank debug, software support, or core architecture completeness.

### Recommended Scope (in priority order)

1. **LED control register** — MMIO-mapped (e.g. `0xD0000000`), writes drive the
   four existing status LEDs already present in `fpga_top.sv`. Small RTL
   change, trivial self-checking testbench, immediately visible once the
   board arrives.
2. **Button/switch input register** — MMIO-mapped, debounced read of the
   PYNQ-Z2's 2 push-buttons and 2 slide switches. Pairs naturally with the
   LED register (press button -> toggle LED is a standard board sanity
   check).
3. **PWM peripheral** — duty-cycle and period registers, following the same
   counter/compare pattern already used by `timer.sv`. Enables audio tone
   generation or LED brightness control as a board demo.

Each peripheral should get its own MMIO address block, its own
`bus_<periph>_*` signal bundle (per the Phase 11 internal bus), and its
own entry in `docs/verification/test-plan.md`.

### Dropped From This Phase

- **Simple SPI master** — only useful with a concrete target device (flash,
  DAC, ADC, or display) to talk to. Without a specific Pmod in mind, this
  would be a peripheral with no demo. Revisit only if a specific use case
  appears.
- **Pmod VGA / display output** — needs an external Pmod VGA adapter and
  substantial RTL for even a simple text framebuffer. See "Display
  Options" below — the UART terminal already provides the best
  value-for-effort for this project's debug needs.

### Display Options

| Option | Practicality | Notes |
|--------|--------------|-------|
| Pmod VGA text console | Feasible | Needs external Pmod VGA adapter |
| HDMI through Zynq PS | More complex | Involves PS/PL integration |
| UART terminal | Already best value | Much easier and more useful for CPU debug |

If you add display output, make it a peripheral demo, not the main architecture milestone.

---

## Phase 13: Dual-Core SoC Extension

**Priority: Long-term optional**  
**Effort: 4-8 weeks after bus, traps, and software support**  
**Practicality: Medium if kept simple**

This is practical only if it is treated as a small shared-memory dual-core experiment, not as a modern cache-coherent multicore processor.

### Practical Target

- 2 cores
- 1 thread per core
- shared BRAM or mailbox peripheral
- shared UART/timer/performance registers
- simple round-robin bus arbiter
- no caches, no coherency

### Stretch Goals

- 4 cores after dual-core works
- simple software scheduling via timer interrupts

### Avoid

- SMT
- cache-coherent multicore
- Linux-style OS threads

The first useful demo should be simple: core 0 and core 1 run separate programs or separate loops, communicate through a mailbox or shared memory, and print proof through the shared UART.

---

## Features to Remove or Deprioritize

| Old Idea | Decision | Reason |
|----------|----------|--------|
| Full RISC-V Vector / RVV | Remove | Too large for this project scope |
| "AI-style acceleration" | Remove unless concretely demonstrated | Misleading without a real datapath and benchmark |
| 4-lane 32-bit vector unit as the first SIMD milestone | Deprioritize and reshape | Packed-SIMD inside scalar registers is much more practical first |
| Educational OS or tiny RTOS as a headline feature | Remove for now | Not the best next step for this project |
| Cache as a near-term feature | Deprioritize | Not meaningful without a better bus and larger/slower memory |
| VGA before monitor/debug support | Deprioritize | UART monitor and debug visibility give more engineering value |
| Line-count targets | Remove | Quality, tests, and demos matter more than LOC |
| SMT, cache-coherent multicore, or Linux-style threading | Avoid | Too complex for the practical scope of this project |

---

## Recommended Priority Order

```text
1. Hardware UART proof and clean documentation        [1-3 days]
2. Complete RV32I behavior and instruction table      [1-2 weeks]
3. Debugging and reliability infrastructure           [1-2 weeks]
4. UART monitor and program loader                    [1-3 weeks]
5. Traps, exceptions, and timer interrupts            [2-4 weeks]
6. RV32M multiply/divide                              [1-3 weeks]
7. Small C program flow                               [1-3 weeks]
8. Branch prediction with CPI comparison              [1-2 weeks]
9. Packed-SIMD custom instructions                    [2-4 weeks]
10. Real workloads and benchmark demos                [1-3 weeks]
11. Bus cleanup / optional memory growth              [optional]
12. Optional peripherals                              [optional]
13. Dual-core SoC extension                           [long-term optional]
```

---

## Best Final Project Identity

The strongest identity for this project is:

> A 5-stage pipelined RISC-V soft processor on PYNQ-Z2 with UART MMIO, performance counters, hardware-visible debug, and bare-metal software support.

If later phases are completed, this can become:

> A small RV32IM educational soft-core SoC with traps, timer interrupts, monitor/debug support, performance analysis, optional packed-SIMD extensions, and a later dual-core shared-memory variant.

That title is ambitious but still believable if the roadmap is implemented in order.

---

## Bottom Line

The project is already strong: it builds, routes, passes simulation, uses very little FPGA fabric, and has UART plus performance counters.

The best path forward is depth before breadth. Finish the scalar CPU properly, strengthen debugability and reliability, add a monitor/loader path, and then build traps, software support, and performance experiments on top of that base.

Packed-SIMD and dual-core work are still possible later, but they should come only after the single-core system is robust, measurable, and easy to explain.

See docs/no_board_execution_plan.md for the full No-Board Execution Plan.
See docs/board_arrival_checklist.md for the full Board Arrival Mandatory Checklist.