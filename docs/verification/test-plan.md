# Verification Status

> **Last updated:** 2026-06-04  
> **Simulation tool:** Vivado XSim v2025.2 (win64)  
> **Testbench location:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv)

## Summary Table
| Category                   | Total | ✅ PASS | ❌ FAIL | ⏳ TODO |
|----------------------------|-------|---------|---------|---------|
| Pipeline Tests             | 1     | 1       | 0       | 0       |
| Hazard Tests               | 1     | 1       | 0       | 0       |
| Forwarding Tests           | 1     | 1       | 0       | 0       |
| Branch / Jump Tests        | 1     | 1       | 0       | 0       |
| Load / Store Tests         | 1     | 1       | 0       | 0       |
| UART Tests                 | 1     | 1       | 0       | 0       |
| MMIO Tests                 | 1     | 1       | 0       | 0       |
| CSR / System Tests         | 1     | 1       | 0       | 0       |
| Performance Counter Tests  | 1     | 1       | 0       | 0       |
| FPGA Validation            | 1     | 0       | 0       | 1       |
| UART Monitor Tests         | 1     | 0       | 0       | 1       |
| **Total**                  | **11**| **9**   | **0**   | **2**   |

---

## Pipeline Tests
#### TEST-001: Pipeline baseline test
- **Status:** ✅ PASS
- **Category:** Pipeline
- **Description:** Basic pipeline execution and register writeback validation (ADD, SUB, AND, OR, XOR results).
- **Test file:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv#L377-L385)
- **Last run:** 2026-06-03
- **Notes:** Verified basic ALU instruction output matches register file state.

## Hazard Tests
#### TEST-002: Hazard detection
- **Status:** ✅ PASS
- **Category:** Hazard
- **Description:** Verifies load-use stalls (LW followed immediately by dependent ADD).
- **Test file:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv#L395-L397)
- **Last run:** 2026-06-03
- **Notes:** Confirmed that `stall_seen` flag assertions passed.

## Forwarding / Bypassing Tests
#### TEST-003: Data forwarding
- **Status:** ✅ PASS
- **Category:** Forwarding
- **Description:** Verifies data forwarding from EX/MEM and MEM/WB.
- **Test file:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv#L389-L393)
- **Last run:** 2026-06-03
- **Notes:** Confirmed that forwarding was asserted in the EX/MEM and MEM/WB paths.

## Branch and Jump Tests
#### TEST-004: Control flow instructions
- **Status:** ✅ PASS
- **Category:** Branch
- **Description:** Verifies correct branching (BEQ taken/not taken) and jump instructions (JAL/JALR).
- **Test file:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv#L399-L413)
- **Last run:** 2026-06-03
- **Notes:** Flush logic verified on taken branches and jumps. Sequential execution confirmed for not-taken branches.

## Load and Store Tests
#### TEST-005: Memory operations
- **Status:** ✅ PASS
- **Category:** Load/Store
- **Description:** Verifies subword (LB, LBU, LH, LHU, SB, SH) and word loads/stores.
- **Test file:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv#L653-L665)
- **Last run:** 2026-06-03
- **Notes:** Verified sign-extension, zero-extension, and correct byte lane writes.

## UART Tests
#### TEST-006: UART communication
- **Status:** ✅ PASS
- **Category:** UART
- **Description:** Verifies UART TX and RX functionality by receiving cycles, instructions, stalls, flushes, and IPC values printed from the program.
- **Test file:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv#L680-L709)
- **Last run:** 2026-06-03
- **Notes:** Smoke tests decoded printed metrics successfully over UART.

## MMIO Tests
#### TEST-007: Memory Mapped IO
- **Status:** ✅ PASS
- **Category:** MMIO
- **Description:** Verifies memory mapping to UART registers, performance counters, and debug registers.
- **Test file:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv#L501-L522)
- **Last run:** 2026-06-03
- **Notes:** Verified correct addresses decoder selection in MEM stage.

## CSR and System Instruction Tests
#### TEST-008: System instructions
- **Status:** ✅ PASS
- **Category:** CSR
- **Description:** Verifies that FENCE/FENCE.I decode as NOP, ECALL/EBREAK halt the pipeline, and illegal instructions raise halt.
- **Test file:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv#L712-L724)
- **Last run:** 2026-06-03
- **Notes:** Checked that halt stayed low during regression and ECALL/EBREAK halt/illegal latch decode properly.

## Performance Counter Tests
#### TEST-009: Counter accuracy
- **Status:** ✅ PASS
- **Category:** Perf
- **Description:** Verifies cycle, instruction, stall, and flush counter MMIO register tracking.
- **Test file:** [tb_top.sv](riscv_pipeline_offline/riscv_pipeline_offline.srcs/sim_1/imports/riscv_pipeline/sim/tb_top.sv#L434-L498)
- **Last run:** 2026-06-03
- **Notes:** Confirmed non-zero cycle and instruction count retire tracking.

## FPGA Validation
#### TEST-010: Hardware test
- **Status:** ⏳ TODO (Deferred)
- **Category:** FPGA
- **Description:** Verifies physical board execution on the PYNQ-Z2 board via PMODA UART.
- **Test file:** N/A (requires hardware board)
- **Last run:** N/A
- **Notes:** Deferred until physical board is available. Routed timing and bitstream generation are successfully completed in Vivado.

## UART Monitor Tests
#### TEST-011: UART monitor command parser
- **Status:** ⏳ TODO (RTL ready, pending xsim run)
- **Category:** UART Monitor
- **Description:** Verifies the UART monitor command parser FSM with fpga_top as DUT. Tests help, load, run, reset, regs, mem, perf, and trace commands.
- **Test file:** N/A (requires fpga_top-level testbench)
- **Last run:** N/A
- **Notes:** Monitor RTL (`uart_monitor.sv`) is structurally complete and wired in `fpga_top.sv`. Debug read ports are connected. The `tb_top.sv` already includes `sim_uart_tx_byte()` helper. Full end-to-end simulation needs xsim with fpga_top as DUT. Host-side loader (`tools/mem_to_load_commands.py`) supports interactive mode.

## Phase 5 Tests
#### TEST-012: Traps and CSRs
- **Status:** Pass
- **Category:** Phase 5
- **Description:** Verifies CSR file, trap entry, MRET, and timer interrupts.
- **Last run:** 2026-06-14

## Phase 6 Tests
#### TEST-013: RV32M Multiply
- **Status:** Pass
- **Category:** Phase 6
- **Description:** Verifies MUL, MULH, MULHU, MULHSU.
- **Last run:** 2026-06-14

## Phase 8 Tests
#### TEST-014: Branch Prediction
- **Status:** Pass
- **Category:** Phase 8
- **Description:** Verifies 64-entry BHT logic and prediction accuracy.
- **Last run:** 2026-06-16

## Phase 9 Tests
#### TEST-015: Packed SIMD
- **Status:** Pass
- **Category:** Phase 9
- **Description:** Verifies PADD8, PSUB8, PMAXU8, PMINU8, PAVG8.
- **Last run:** 2026-06-19

## Phase 10 Tests
#### TEST-016: C Benchmark Programs
- **Status:** Pass
- **Category:** Phase 10
- **Description:** Verifies compiled C benchmark programs run correctly in simulation.
- **Last run:** 2026-06-21
