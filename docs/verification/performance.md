# Performance History

> Entries are append-only. Do not modify past entries.  
> Add new benchmark runs as additional ## sections at the bottom.

---

## Baseline — Pre-Phase-4 Snapshot

### FPGA Target
- **Board:** PYNQ-Z2 / Zynq-7000
- **Part:** xc7z020clg400-1
- **Tool:** Vivado v2025.2 (win64) Build 6299465

### Resource Utilization
| Resource | Used | Available | Utilization % |
|----------|-----:|----------:|--------------:|
| Slice LUTs | 7,127 |     53,200 |         13.4% |
| Slice Registers | 1737 |    106,400 |         1.63% |
| Block RAM Tiles (BRAM) | 1 |        140 |         0.71% |
| DSPs | 0 |        220 |         0.00% |
| Bonded IOB | 8 |        125 |         6.40% |

### Timing
| Clock Domain | Target MHz | Achieved MHz | WNS (ns) | Status |
|--------------|:----------:|:------------:|:--------:|--------|
| sys_clk      | 125 MHz    | 125 MHz      | +5.447   | ✅ Met |
| pll_clk (CPU)| 25 MHz     | 25 MHz       | +25.005  | ✅ Met |

*Note: WNS +25.005 ns on the pll_clk domain indicates the processor core has substantial timing margin at 25 MHz (equivalent to ~15.00 ns minimum cycle time or ~66.6 MHz achievable frequency).*

### IPC / Cycle Counts
| Benchmark | Cycles | Instructions Retired | IPC | Stalls | Flushes | CPI | Notes |
|-----------|-------:|--------------------:|:---:|-------:|--------:|:---:|-------|
| `demo_perf_uart.s` | 80 | 59 | 0.73 | 7 | 6 | 1.36 | Prints performance report over UART |

### Notes
- Implementation routed cleanly with no DRC violations.
- Distributed RAM utilized for reg file storage (512 LUTs as Distributed RAM) to avoid Block RAM waste on a small register file.
- Single RAMB36E1 block is used to implement instruction memory.

---
## Post-Phase-10 Synthesis (2026-06-22)

### Resource Utilization
| Resource | Used | Available | Utilization % |
|----------|-----:|----------:|--------------:|
| Slice LUTs | 7,127 | 53,200 | 13.4% |

Source: impl_1 run (2026-06-22)

### Timing
| Clock Domain | WNS (ns) | Status |
|--------------|:--------:|--------|
| sys_clk      | +5.265 | Met |

### Benchmark Results
See `results/phase10_benchmark_report.md` for the full benchmark table.

---
<!-- Append new benchmark runs above this line as new ## sections -->
