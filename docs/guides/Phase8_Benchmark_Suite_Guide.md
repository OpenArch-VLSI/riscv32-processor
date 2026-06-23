# Phase 8: Benchmark Suite Guide

This guide walks you through running the full C-level benchmark suite we designed to stress-test the RISC-V processor's dynamic branch predictor, data forwarding unit, and memory access mechanisms.

## The Benchmarks

1. **`benchmark.c` (Bubble Sort)**: Tests highly predictable inner loops.
2. **`fibonacci_rec.c`**: Tests recursive stack operations, deep memory read/writes, and `JAL`/`JALR` control hazards.
3. **`matmul.c`**: Tests triple-nested loops, heavy memory access, and dense data hazards (stressing the EX/MEM and MEM/WB forwarding paths).
4. **`primes.c`**: Generates primes using trial subtraction. The branch patterns are highly unpredictable, which stresses the limits of the 64-entry 2-bit saturating BHT.
5. **`string_match.c`**: Tests byte-aligned (`LBU`, `SB`) memory operations and sequential data scanning.

## How to Run the Automated Suite via CLI

We have created a master TCL script (`run_all_benchmarks.tcl`) that automatically injects each `.mem` file into the Vivado simulator one by one, runs the simulation for up to 10 milliseconds, and captures the UART output directly to your terminal.

You do not need to open the Vivado GUI. Simply open a Command Prompt or PowerShell terminal in your processor directory and run:

```bash
<vivado-path>/vivado -mode batch -source run_all_benchmarks.tcl
```

Watch the terminal output! You will see blocks like this for each benchmark as Vivado churns through the logic simulations:
```text
================================================================
>>> RUNNING BENCHMARK SIMULATION: fibonacci_rec.mem
...
FIB
[C-PROGRAM UART] t=4213450000  
C:[C-PROGRAM UART] t=4475210000  0
I:[C-PROGRAM UART] t=4736970000  0
S:[C-PROGRAM UART] t=4998730000  0
F:[C-PROGRAM UART] t=5260490000  0
DONE
```

## Extracting the Results

Since the raw Vivado output contains simulator timestamps interleaving the UART characters (e.g. `[C-PROGRAM UART] t=4213450000  C`), we have a python script that will parse the output cleanly for you!

1. Save the output of the vivado command to a file (e.g. `vivado_run.log`).
2. Run the parser script:
   ```bash
   python parse_uart.py vivado_run.log
   ```
3. The script will print out the clean Hex metrics (Cycles, Instructions, Stalls, Flushes).

We have already extracted and populated the definitive results from our run into the text files in the `results/` folder! Open `results/fibonacci_benchmark_results.txt` (and the others) to see the true hardware performance counters for your pipeline.
