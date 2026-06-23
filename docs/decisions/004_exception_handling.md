# ADR 004: Exception and Trap Handling

## Status
Accepted

## Context
Support for ECALL, EBREAK, illegal instructions, and timer interrupts requires
a CSR file and trap entry/return logic.

## Decision
Implemented a dedicated CSR file (`csr_file.sv`) supporting M-mode registers:
`mstatus`, `mtvec`, `mepc`, and `mcause`. A memory-mapped timer peripheral at
`0xC0000200` provides `mtime` / `mtimecmp` with interrupt generation. Trap
entry freezes/flushes the pipeline; `MRET` restores PC from `mepc`.

## Consequences
- Full support for basic M-mode traps and timer interrupts.
- Enables time-based interrupts for preemptive scheduling in C programs.
- CSR read/write instructions (CSRRW, CSRRS, etc.) are now functional.
