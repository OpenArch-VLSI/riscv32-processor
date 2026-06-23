# ADR 005: Cache Architecture

## Status
Accepted

## Context
Whether to implement an instruction/data cache for the processor.

## Decision
Do NOT implement a cache. The processor targets single-cycle-access FPGA BRAM
where memory operations do not incur multi-cycle latency at 25 MHz.

## Consequences
- Simpler architecture with deterministic, predictable timing.
- Will become a bottleneck if migrated to slower off-chip DRAM.
- Leaves room for future cache implementation as a stretch goal.
