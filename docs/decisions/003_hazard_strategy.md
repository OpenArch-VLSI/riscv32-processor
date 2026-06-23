# ADR 003: Pipeline Hazard Strategy

## Status
Accepted

## Context
Data and control hazards in the 5-stage pipeline must be resolved efficiently
to maintain low CPI.

## Decision
Hybrid hazard handling:
- **Data forwarding**: `forwarding_unit.sv` bypasses results from EX/MEM and
  MEM/WB back to the EX stage inputs.
- **Load-use stalls**: `hazard_detection_unit.sv` stalls the pipeline for one
  cycle on a load-use dependency (load in EX followed by dependent use in ID).
- **Control hazards**: Flush-on-taken strategy flushes IF/ID and ID/EX when a
  branch or jump is resolved in EX. A 64-entry BHT dynamic predictor (Phase 8)
  reduces the flush penalty.

## Consequences
- Better CPI than stalling on all hazards.
- Increased logic complexity in forwarding and hazard detection units.
- BHT adds ~4K bits of state but significantly reduces branch penalty.
