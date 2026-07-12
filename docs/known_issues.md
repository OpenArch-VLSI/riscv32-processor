# Known Issues

> **Last updated:** 2026-07-12  
> Issues are never deleted — resolved issues are marked with resolution notes.

## Summary
| Severity | Open | In Progress | Resolved | Total |
|----------|-----:|------------:|---------:|------:|
| Critical |    0 |           0 |        2 |     2 |
| High     |    0 |           0 |        4 |     4 |
| Medium   |    2 |           0 |        1 |     3 |
| Low      |    0 |           0 |        0 |     0 |

## Open Issues

#### ISSUE-001: Physical board test deferred
- **Severity:** Medium
- **Status:** Open
- **Category:** Limitation
- **Description:** Physical board test deferred until hardware is available (Phase 0).
- **Workaround:** Relying on simulation results for now.
- **Resolution:** 
- **Notes:** Hardware demo is required to complete Phase 0.

#### ISSUE-010: UART Hardware Byte-Drop Risk
- **Severity:** Medium
- **Status:** Open
- **Category:** Architecture/Hardware Risk
- **Description:** The hardware UART transmitter (`uart_tx.sv`) silently drops bytes written to it while `tx_busy` is high, as the `tx_start` pulse is only sampled in the `IDLE` state. The CPU pipeline does not stall on busy.
- **Workaround:** Software must explicitly poll the `tx_busy` bit in the UART status register (`0x80000000`) before every byte write (as currently implemented by the `PUTC` assembly macro).
- **Resolution:** 
- **Notes:** This is a latent risk if new assembly/C code is added without using a busy-polling subroutine.

## Known Limitations
- The processor clock is set to 25 MHz; timing slack indicates it could run at higher speeds (~60 MHz) but requires regeneration of UART clock divider constants.

## Unsupported Features
- Misaligned memory accesses (e.g., `LW` or `SW` on odd or non-word-aligned addresses) are not supported. Addresses are truncated to alignment boundary.

## Technical Debt
- (Resolved in Phase 11 — see ISSUE-007 in Resolved Issues below.)

## Future Investigation

## Resolved Issues


#### ISSUE-002: UART monitor pending simulation at fpga_top level
- **Severity:** High
- **Status:** Resolved
- **Category:** Verification Gap
- **Description:** The UART monitor RTL is complete and wired, but the full command parser FSM has not been exercised in a Vivado/xsim simulation with `fpga_top` as the DUT.
- **Workaround:** Monitor is verified structurally (all ports connected, FSM logic reviewed). The `top.sv`-level testbench still passes all pipeline regressions.
- **Resolution:** Resolved on 2026-06-13. Created `tb_fpga_top.sv` and successfully ran the `help` and `regs` commands end-to-end through the UART FSM using xsim.
- **Notes:** Phase 4 RTL is now verified and board-ready.

#### ISSUE-003: Missing trap path and timer interrupts
- **Severity:** High
- **Status:** Resolved
- **Category:** Missing Feature
- **Description:** No trap path / timer interrupts yet (Phase 5 pending).
- **Workaround:** None.
- **Resolution:** Resolved 2026-06-14. Phase 5 RTL implemented: csr_file.sv, timer.sv, CSR decode, trap entry, MRET, timer IRQ.
- **Notes:** Simulation pending in Vivado xsim.

#### ISSUE-004: Vivado Synthesis Hang due to UART Monitor Array Assignments
- **Severity:** Critical
- **Status:** Resolved
- **Category:** Synthesis Anti-Pattern
- **Description:** Vivado `synth_design` hung indefinitely because the `uart_monitor.sv` FSM was assigning multiple bytes of a `tx_buf` array concurrently in a single cycle. This generated a massive unrolled multiplexer network that exhausted memory during logic optimization.
- **Resolution:** Resolved on 2026-06-13. Completely removed the `tx_buf` array. Rewrote the `ST_PRINT_HEX` FSM state to use a pure 256-bit shift register that writes strictly one byte to the UART TX FIFO per clock cycle. Synthesis now completes rapidly.
- **Notes:** Hardware design pattern fixed. No multi-write array assignments allowed.

#### ISSUE-005: Branch prediction not yet implemented
- **Severity:** High
- **Status:** Resolved
- **Category:** Missing Feature
- **Description:** Dynamic branch prediction was absent prior to Phase 8.
- **Workaround:** None.
- **Resolution:** Resolved in Phase 8. 64-entry Branch History Table
  (BHT) with 2-bit saturating counters implemented in `bht.sv`.
  Verified by `tb_bht` testbench.
- **Notes:** Static not-taken fallback also retained.

#### ISSUE-006: Custom packed-SIMD extension not yet implemented
- **Severity:** High
- **Status:** Resolved
- **Category:** Missing Feature
- **Description:** Custom packed-SIMD instructions were absent prior
  to Phase 9.
- **Workaround:** None.
- **Resolution:** Resolved in Phase 9. Five instructions added via
  custom-0 opcode (0001011): PADD8, PSUB8, PMAXU8, PMINU8, PAVG8.
  Verified by `tb_phase9` testbench. Benchmark showed 3.85x cycle
  speedup over scalar equivalent.
- **Notes:** Encoded using the RV32 custom-0 opcode space.

#### ISSUE-007: Peripherals decoded ad-hoc rather than through a unified bus
- **Severity:** Medium
- **Status:** Resolved
- **Category:** Technical Debt
- **Description:** Prior to Phase 11, UART, Timer, Performance Counters,
  and Debug MMIO were each wired into `mem_stage.sv` with their own
  bespoke set of signals rather than a common interface.
- **Workaround:** None needed — design worked correctly, this was a
  maintainability concern rather than a functional bug.
- **Resolution:** Resolved in Phase 11. All peripherals now route through
  a common internal signal-bundle bus (bus_<periph>_*) in
  mem_stage.sv. Verified by `tb_memory_map.sv`. No address-map changes.
- **Notes:** A cache was explicitly NOT added as part of this phase, per
  `docs/roadmap.md`'s own Phase 11 scope — the project's small on-chip
  BRAM does not yet justify one.

#### ISSUE-008: fpga_top.sv multi-driven led net
- **Severity:** Critical
- **Status:** Resolved
- **Category:** Synthesis Anti-Pattern
- **Description:** The `led` output in `fpga_top.sv` was driven by both a
  continuous `assign` (line 330) and an `always_ff` sequential block
  (`led <= 4'b0000` in reset clause, line 320). This caused 12
  `[Synth 8-6859] multi-driven net` critical warnings during synthesis.
- **Workaround:** None — synthesis warnings indicated the `always_ff`
  driver was silently ignored by the tool, favouring the constant GND
  driver. Hardware behaviour was undefined.
- **Resolution:** Resolved on 2026-06-28. Removed `led <= 4'b0000` from
  the `always_ff` reset clause. The `assign` on line 330 already handles
  reset correctly via `fail_sync`, `pass_sync`, and `pll_locked`
  conditions in the mux expression. Re-synthesis confirmed 0 errors,
  0 critical warnings (Checksum: 84a84c29).
- **Notes:** Saved `results/synthesis_clean_2026-06-28.txt` with the
  pre-fix and post-fix synthesis output for audit trail.

#### ISSUE-009: Division instructions causing severe timing failure
- **Severity:** Critical
- **Status:** Resolved
- **Category:** Timing/Architecture
- **Description:** DIV/DIVU/REM/REMU were originally implemented as a single-cycle combinational operation in `alu.sv`. This approach worked functionally but caused a severe timing regression (WNS -61.9ns, TNS -1969.7ns) due to deep combinational logic.
- **Workaround:** None.
- **Resolution:** Resolved by revising the architecture to use a 32-cycle iterative multi-cycle FSM divider (shift-subtract restoring division) in `ex_stage.sv`. Division-by-zero and signed-overflow are fast-tracked. The pipeline correctly stalls during execution.
- **Notes:** Timing is fully restored. WNS improved from -61.9ns to +5.232ns, and TNS improved from -1969.7ns to 0.000ns.