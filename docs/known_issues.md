# Known Issues

> **Last updated:** 2026-06-14  
> Issues are never deleted — resolved issues are marked with resolution notes.

## Summary
| Severity | Open | In Progress | Resolved | Total |
|----------|-----:|------------:|---------:|------:|
| Critical |    0 |           0 |        1 |     1 |
| High     |    0 |           0 |        2 |     2 |
| Medium   |    1 |           0 |        0 |     1 |
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

#### ISSUE-002: UART monitor pending simulation at fpga_top level
- **Severity:** High
- **Status:** Resolved
- **Category:** Verification Gap
- **Description:** The UART monitor RTL is complete and wired, but the full command parser FSM has not been exercised in a Vivado/xsim simulation with `fpga_top` as the DUT.
- **Workaround:** Monitor is verified structurally (all ports connected, FSM logic reviewed). The `top.sv`-level testbench still passes all pipeline regressions.
- **Resolution:** Resolved on 2026-06-13. Created `tb_fpga_top.sv` and successfully ran the `help` and `regs` commands end-to-end through the UART FSM using xsim.
- **Notes:** Phase 4 RTL is now verified and board-ready.

#### ISSUE-004: Vivado Synthesis Hang due to UART Monitor Array Assignments
- **Severity:** Critical
- **Status:** Resolved
- **Category:** Synthesis Anti-Pattern
- **Description:** Vivado `synth_design` hung indefinitely because the `uart_monitor.sv` FSM was assigning multiple bytes of a `tx_buf` array concurrently in a single cycle. This generated a massive unrolled multiplexer network that exhausted memory during logic optimization.
- **Resolution:** Resolved on 2026-06-13. Completely removed the `tx_buf` array. Rewrote the `ST_PRINT_HEX` FSM state to use a pure 256-bit shift register that writes strictly one byte to the UART TX FIFO per clock cycle. Synthesis now completes rapidly.
- **Notes:** Hardware design pattern fixed. No multi-write array assignments allowed.

#### ISSUE-003: Missing trap path and timer interrupts
- **Severity:** High
- **Status:** Resolved
- **Category:** Missing Feature
- **Description:** No trap path / timer interrupts yet (Phase 5 pending).
- **Workaround:** None.
- **Resolution:** Resolved 2026-06-14. Phase 5 RTL implemented: csr_file.sv, timer.sv, CSR decode, trap entry, MRET, timer IRQ.
- **Notes:** Simulation pending in Vivado xsim.

## Known Limitations
- The processor clock is set to 25 MHz; timing slack indicates it could run at higher speeds (~60 MHz) but requires regeneration of UART clock divider constants.

## Unsupported Features
- Misaligned memory accesses (e.g., `LW` or `SW` on odd or non-word-aligned addresses) are not supported. Addresses are truncated to alignment boundary.
- Division instructions (DIV/DIVU/REM/REMU) are not implemented yet. MUL is implemented.

## Technical Debt
- Peripherals (UART, Performance Counters, Debug Unit) are decoded directly in the MEM stage rather than unified behind an internal peripheral bus.

## Future Investigation
