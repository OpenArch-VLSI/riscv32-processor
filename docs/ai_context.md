# AI Context

This is the **single source of truth** for any AI agent working on this project.
Read it fully before acting. Update it before leaving. No exceptions.

---

## ⛔ PRE-EXIT MANDATORY CHECKLIST — COMPLETE EVERY ITEM BEFORE ENDING SESSION

**If you modified ANY source file (.sv, .py, .ps1, .tcl, .xdc, .mem), the following items are NOT optional. They are REQUIRED. There is no "done" without them.**

| # | Requirement | Verify |
|---|-------------|--------|
| 1 | Update **Current Project State** and **Next Priorities** in this file | ☐ |
| 2 | Append entry to **Recent AI Updates** in this file | ☐ |
| 3 | Update `docs/roadmap.md` (Recently Completed, task tracker, phase table) | ☐ |
| 4 | Write session log: `docs/updates/session_YYYY-MM-DD_HHMM_NAME.md` | ☐ |
| 5 | Append link to new session log in `docs/updates/README.md` | ☐ |
| 6 | If performance metrics or test outputs were generated, save them in the `results/` folder | ☐ |
| 7 | Run `.\tools\check_docs_stale.ps1 -Strict` — exit 0 = you are done, exit 1 = go fix | ☐ |

**If the checker fails, your session is NOT complete. Go back and finish the items above.**

---

## 🔴 AGENT BOOT SEQUENCE — FOLLOW IN ORDER, NO EXCEPTIONS

Before acting, you must:

1. **Read this entire file.** Do not skim. Every section matters.
2. **Read** `docs/roadmap.md`, `docs/architecture/overview.md`, `docs/roadmap.md`.
3. **Read the latest session log** in `docs/updates/` to understand what the previous agent did and left incomplete.
4. **Consult the File Registry** below before creating any new file — it may already exist. If you create a new file, add it to the registry.
5. **Do not invent** implementation details. Mark unknowns as: `TODO — verify from source`.
6. **Before exiting**, complete every item in the PRE-EXIT CHECKLIST above. There is no excuse — agents have been observed skipping these steps despite the boot sequence. The checklist is your explicit instruction not to do that.

---

## 🤖 Instructions for AI Agents

1. **Context Ingestion:** Read this file completely. It is the most up-to-date project state.
2. **Mandatory State Update:** After making changes, you MUST update the "Recent AI Updates", "Current Project State", and "Next Priorities" sections below.
3. **Keep `docs/roadmap.md` Current:** Append completed tasks to "Recently Completed" and update any tables/trackers if phase progress was made.
4. **MANDATORY Session Log:** After EVERY session that touches source files, create `docs/updates/session_YYYY-MM-DD_HHMM_NAME.md`. Use the template below. Append a link to `docs/updates/README.md`. This is not optional.

### Session Log Template

```markdown
# Session Log

## Machine Fingerprint
- Hostname: (run `hostname`)
- OS: (run `systeminfo | findstr /B /C:"OS Name"` on Windows, or `uname -a`)
- CPU: (run `wmic cpu get name` on Windows)
- Username: (run `whoami`)
- Timestamp: YYYY-MM-DD HH:MM TZ

## Work Summary
- What was accomplished in this session.

## Files Created
- path/to/new/file.sv

## Files Modified
- path/to/changed/file.sv

## Docs Updated (Complete)
- **`docs/ai_context.md`**: What was updated.
- **`docs/roadmap.md`**: What was updated.

## Next Steps
- What the next agent should do.
```

---

## 📌 Project Overview
This project is a 5-stage pipelined RV32I-style soft SoC implemented on the PYNQ-Z2 FPGA with UART MMIO and performance counters. 

- **Target Board:** PYNQ-Z2 / Zynq-7000 (`xc7z020clg400-1`)
- **Core:** 5-stage pipelined RV32I-style core
- **Key Features:** Forwarding, load-use stall, branch/jump flush, UART TX/RX integrated through MMIO, Performance counters, Subword memory ops (`LB`, `LH`, `SB`, `SH`), ECALL/EBREAK/illegal instruction traps with MRET, Timer interrupts, M-mode CSRs (mstatus/mtvec/mepc/mcause), UART Monitor with 7 commands, Custom packed-SIMD extension (PADD8/PSUB8/PMAXU8/PMINU8/PAVG8).

## 🚦 Current Project State
- **Phase 0 (Hardware Demo):** Partial / Deferred. Bitstream generated successfully today. Physical board test is deferred until hardware is available.
- **Phase 1 (Reproducible Software):** Mostly complete. Assembler, build script, and `program.mem` generation are in place.
- **Phase 2 (RV32I Base):** Complete. Full subword memory ops, FENCE/NOP, ECALL halt, and illegal instruction detection are implemented and tested.
- **Phase 3 (Debugging & Reliability):** Complete. MMIO debug registers, a 4-entry commit trace buffer, and assertion-oriented simulation checks are implemented and tested.
- **Phase 4:** Substantially complete. UART monitor (`uart_monitor.sv`) FSM rewritten and mathematically verified end-to-end. Bitstream generation succeeded.
- **Phase 5 (Traps, Exceptions, Timers):** Complete in Simulation. CSR file with mstatus/mtvec/mepc/mcause, timer peripheral, trap entry, MRET execution, timer interrupt generation.
- **Phase 6 (RV32M Multiply Extension):** Complete in Simulation. `MUL`, `MULH`, `MULHSU`, `MULHU` implemented with a single-cycle DSP multiplier in `alu.sv`.
- **Phase 7 (Run Small C Programs):** Complete in Simulation. C software infrastructure (`linker.ld`, `crt0.S`, `Makefile`), UART library, and stack-allocated "Hello World" demo compiled using xPack RISC-V GCC and simulated live in Vivado.
- **Phase 8 (Branch Prediction & CPI Experiments):** Complete in RTL. Created a bubble sort benchmark program. Implemented Static Branch Prediction (BTFNT) followed by Dynamic Branch Prediction (64-entry BHT with 2-bit counters). Pipeline misprediction flush logic optimized. Pending final simulation runs for metrics validation.
- **Phase 9 (Custom Packed-SIMD Extension):** RTL complete. Five packed operations (PADD8, PSUB8, PMAXU8, PMINU8, PAVG8) on custom-0 opcode (0001011). Per-lane 8-bit operations use existing forwarding/hazard logic. Testbench `tb_phase9.sv` created. Simulation pending.
- **Phase 10 (Real Workloads and Benchmark Demos):** Complete in Simulation. Created workload suite (checksums, bubble sort). Resolved 8-bit lane overflow and unaligned access correctness bugs in SIMD benchmarking. Extracted and documented cycles, instructions, stalls, and flushes, proving a 3.85x cycle speedup for PADD8 over scalar.
- **Phase 11 (Memory System and Bus Cleanup):** Complete in Simulation.
  Refactored `mem_stage.sv` to route RAM, UART, Timer, Performance
  Counters, and Debug MMIO through an internal signal-bundle bus
  (`bus_<periph>_*`). Added `tb_memory_map.sv` regression testbench
  (6 checks, all passing). Updated `docs/architecture/memory-map.md`
  with the previously-undocumented timer register addresses. No
  address-map or behavior changes; this was a pure internal refactor.

## 🎯 Next Priorities (For the Next Agent)
1. **Phase 12 (Optional Peripherals):** Add GPIO peripheral, button/switch
   input, LED control register, or simple SPI master. Simulate any new
   peripheral. Physical board proof deferred until PYNQ-Z2 is available.
2. **Board Arrival Checklist:** Once the board is acquired, immediately
   execute `docs/board_arrival_checklist.md`.

## 📁 Key Documentation References
- [`docs/GETTING_STARTED.md`](./GETTING_STARTED.md): **User guide for the project owner.** Prompt template, folder structure, roadmap summary, troubleshooting.
- [`docs/architecture/overview.md`](./architecture/overview.md): Full technical architecture, memory map, and instruction support table.
- [`docs/roadmap.md`](./roadmap.md): Long-term plan and phase definitions.
- [`docs/roadmap.md`](./roadmap.md): Live tracker of phase completion and remaining work.
- [`docs/architecture/viva_prep.md`](./architecture/viva_prep.md): General Q&A and knowledge base for the project design.
- [`docs/architecture/uart-monitor.md`](./architecture/uart-monitor.md): UART monitor command reference and protocol specification.

---

## 📂 Documentation File Registry

This registry describes every documentation file in the docs/ directory.
Any AI agent adding a new doc file MUST add an entry here.
Any AI agent modifying a doc file MUST verify its entry is still accurate.

| File | Purpose | Status | Last Updated |
|------|---------|--------|--------------|
| `docs/ai_context.md` | PRIMARY BRAIN. Agent briefing, project state, priorities, file registry, session log rules. Read this first on every session. | ✅ Live | 2026-06-16 |
| `docs/roadmap.md` | Live phase tracker. Shows what is complete, in-progress, and pending across all phases. | ✅ Live | 2026-06-16 |
| `docs/architecture/overview.md` | Full technical architecture: pipeline stages, forwarding, hazard unit, MMIO memory map, CSR layout, instruction support. | ✅ Live | 2026-06-04 |
| `docs/roadmap.md` | Long-term project plan and phase definitions. Phases 0-7+. | ✅ Live | 2026-06-04 |
| `docs/architecture/viva_prep.md` | Q&A knowledge base for project design rationale. | ✅ Live | 2026-06-03 |
| `docs/architecture/uart-monitor.md` | UART monitor command reference and protocol specification. | ✅ Live | 2026-06-04 |
| `docs/architecture/instruction-set.md` | Instruction support matrix. Tracks implemented/tested/FPGA-verified status per RV32I instruction. | ✅ Complete | 2026-06-03 |
| `docs/verification/test-plan.md` | Test status tracker. One entry per test with PASS/FAIL/TODO status and last-run date. | ✅ Complete | 2026-06-03 |
| `docs/verification/performance.md` | Append-only FPGA utilization and timing history. One section per benchmark run. | ✅ Complete | 2026-06-03 |
| `docs/ownership.md` | Contribution tracking. Author and AI-assisted contributions. Transparency record. | ✅ Complete | 2026-06-03 |
| `docs/hardware/setup.md` | Full hardware setup and build guide. Board, pins, UART, build steps, test procedure. | ✅ Complete | 2026-06-03 |
| `docs/known_issues.md` | Living issue tracker. Bugs, limitations, technical debt, future investigations. | ✅ Complete | 2026-06-04 |
| `docs/no_board_execution_plan.md` | Detailed breakdown of phase executability without the PYNQ-Z2 board. | ✅ Complete | 2026-06-04 |
| `docs/board_arrival_checklist.md` | Mandatory checklist of hardware verification tasks to run once the board arrives. | ⌛ Complete | 2026-06-04 |
| `docs/updates/session_2026-06-26_1645_antigravity.md` | Session log: Phase 11 documentation persistence pass. | ✅ Complete | 2026-06-26 |
| `.gitignore` | Git exclusion list for Vivado artifacts, build outputs, OS files. | ✅ Active | 2026-06-04 |
| `tools/check_docs_stale.ps1` | Doc freshness checker. Compares source mtimes vs session log. Verifies README index. | ✅ Active | 2026-06-04 |
| `tools/install_hooks.ps1` | Installs pre-commit, post-commit, pre-push git hooks. Run once after git init. | ✅ Active | 2026-06-04 |
| `docs/decisions/README.md` | ADR system index and format guide. Lists all ADRs with status. | ✅ Complete | 2026-06-03 |
| `docs/decisions/001_initial_docs.md` | ADR: Decision to create this documentation system. | ✅ Accepted | 2026-06-03 |
| `docs/decisions/002_uart_mmio_layout.md` | ADR stub: UART MMIO address layout decision. | ⏳ Proposed | 2026-06-03 |
| `docs/decisions/003_hazard_strategy.md` | ADR stub: Pipeline hazard handling strategy. | ⏳ Proposed | 2026-06-03 |
| `docs/decisions/004_exception_handling.md` | ADR stub: Exception and trap handling approach. | ⏳ Proposed | 2026-06-03 |
| `docs/decisions/005_cache_decision.md` | ADR stub: Cache architecture or explicit no-cache decision. | ⏳ Proposed | 2026-06-03 |
| `docs/GETTING_STARTED.md` | 👈 USER GUIDE. For the project owner with minimal coding background. Prompt templates, folder structure, roadmap overview, troubleshooting. | ✅ Live | 2026-06-04 |
| `docs/updates/README.md` | Index of all session logs. Append a link after every session. | ✅ Live | 2026-06-16 |

## 📝 Recent AI Updates
- **2026-06-21**: Completed Phase 10 (Real Workloads and Benchmark Demos). Fixed SIMD data correctness bug involving `PADD8` lane overflow and unaligned stack arrays. Generated `results/phase10_benchmark_report.md` using batch Vivado simulation UART outputs. Proved 3.85x SIMD speedup and validated 64-entry BHT branch predictor efficiency.
- **2026-06-19**: Implemented Phase 9 (Custom Packed-SIMD Extension) RTL. Added 5 packed operations (PADD8, PSUB8, PMAXU8, PMINU8, PAVG8) on custom-0 opcode 0001011. Created `tb_phase9.sv` with 8 self-checking tests. Simulation pending.
- **2026-06-16**: Started and completed Phase 8 (Branch Prediction & CPI Experiments). Developed a Bubble Sort benchmark in C (`sw/demos/benchmark.c`). Implemented a 64-entry Branch History Table (BHT) with 2-bit saturating counters in `bht.sv` for dynamic branch prediction. Optimized the pipeline flush logic in `ex_stage.sv` to only flush upon mispredictions. The pipeline predictively fetches branches in the ID stage and routes outcomes from EX stage back to update the BHT.
- **2026-06-14**: Completed Phase 7 (Run Small C Programs). Installed the xPack RISC-V GCC toolchain. Implemented bare-metal C software infrastructure including `sw/linker.ld`, `sw/crt0.S`, `sw/lib/uart.c`, and `sw/Makefile`. Successfully compiled a "Hello World" application that uses stack-allocated arrays to bypass the Harvard architecture read-only data limitations. Verified the generated `.mem` live in Vivado.
- **2026-06-14**: Analyzed project documentation to determine the next step. Confirmed that Phases 1-6 are fully implemented and verified in simulation, and hardware verification is deferred until the PYNQ-Z2 board arrives. Concluded that the next immediate priority is **Phase 7: Run Small C Programs**.
- **2026-06-14**: Verified Phase 6 RTL (RV32M Multiply Extension) using `tb_phase6.sv`. All `MUL` family tests (`MUL`, `MULH`, `MULHSU`, `MULHU`) passed seamlessly in simulation on the first run. Phase 6 is complete in simulation.
- **2026-06-14**: Debugged and fixed Phase 5 simulation failures in `tb_phase5.sv`. Resolved Timer interrupt logic, forced proper 32-bit `mtimecmp` values, enabled the timer `ctrl` register, and padded the test payload with `jal x0, 0` to prevent safely asynchronous trap returns from tumbling into zeroes and triggering infinite illegal instruction traps. Phase 5 is now fully verified in simulation.
- **2026-06-14**: Implemented Phase 5 RTL (Traps, Exceptions, Timer Interrupts). Created csr_file.sv (mstatus/mtvec/mepc/mcause), timer.sv (0xC0000200), tb_phase5.sv. Updated 7 existing source files for CSR decode, trap entry, MRET execution, and timer MMIO. Phase 5 RTL is complete; simulation pending.
- **2026-06-13**: Identified and fixed a major hardware anti-pattern in `uart_monitor.sv` (multiple array writes per cycle causing a massive MUX network that hung Vivado synthesis). Rewrote the FSM to use a strict single-write-per-cycle shift register. Created `tb_fpga_top.sv` and fully verified the monitor end-to-end in xsim. Generated the Phase 5 Implementation Plan.
- **2026-06-05**: Updated `docs/ownership.md` to add DS srijith, Raunit kapoor, and Hemanth v as contributors per user request.
- **2026-06-04**: Created `docs/no_board_execution_plan.md` and `docs/board_arrival_checklist.md` to clarify what can be developed in simulation/RTL without the physical FPGA board, and what must be done immediately once the board arrives. Appended both files to `status.md` and `ai_context.md`.
- **2026-06-04**: Created `docs/GETTING_STARTED.md` — comprehensive user guide for the project owner. Includes prompt template, folder structure walkthrough, 13-phase roadmap summary, session log explanation, git safety net overview, and troubleshooting section.
- **2026-06-04**: Enforced mandatory documentation update system: initialized git repo, installed pre-commit/post-commit/pre-push hooks running `check_docs_stale.ps1`, hardened `ai_context.md` with PRE-EXIT MANDATORY CHECKLIST and session log template, added `.gitignore`.
- **2026-06-04**: Implemented full Phase 4 UART monitor: `uart_monitor.sv` with 7 commands (help/load/run/reset/regs/mem/perf/trace), wired through `fpga_top.sv` with UART mux and CPU reset control. Added async debug read ports to `reg_file.sv`, `data_mem.sv`, `id_stage.sv`, `mem_stage.sv`, and `top.sv`. Enhanced `tools/mem_to_load_commands.py` with raw/binary/interactive output modes. Phase 4 RTL is now board-ready.
- **2026-06-04**: Advanced Phase 4 further by wiring the loader port through `top.sv`, exercising it from `tb_top.sv` with an event-synchronized program load, and adding `tools/mem_to_load_commands.py` as a host-side command-stream helper.
- **2026-06-04**: Started Phase 4 by converting the instruction memory into a loader-friendly RAM with a ROM preload, threading loader stub signals through `if_stage.sv` and `top.sv`, and updating the architecture/status/known-issues docs.
- **2026-06-03**: Implemented the Phase 3 debug/reliability slice: MMIO debug registers, a 4-entry trace buffer, and simulation checks that validate the debug window and trace history.
- **2026-06-03**: Created documentation system: instruction-set.md, verification.md, performance.md, ownership.md, setup.md, known_issues.md, DECISIONS/ directory with 001 ADR and 4 stubs.
- **2026-06-03**: Reorganized the documentation directory into subfolders and filled in all placeholder metrics across all documentation files.

---


---

See docs/no_board_execution_plan.md for the full No-Board Execution Plan.