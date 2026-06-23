# Phase 8 Verification Guide: Dynamic Branch Prediction

This guide provides step-by-step instructions to verify that Phase 8 (Dynamic Branch Prediction) is successfully implemented and working as intended. 

We introduced a **64-entry Branch History Table (BHT)** using 2-bit saturating counters. The goal of this phase is to drastically reduce pipeline flushes (`F`) caused by branch mispredictions, lowering the overall Cycles Per Instruction (CPI).

---

## Method 1: System-Level Simulation (The Benchmark)
The most definitive proof of the predictor is running real C programs. We wrote a suite of benchmarks (Bubble Sort, Fibonacci, Matrix Multiplication, Primes, and String Match) heavily reliant on backwards looping branches.

### Steps to Verify via CLI (Batch Mode)
You don't even need to open the Vivado GUI! You can run the entire simulation suite from the command line using Vivado's batch mode.

1. Open your terminal (Command Prompt or PowerShell).
2. Navigate to your project directory or use absolute paths. Run the following command:
   ```bash
   <vivado-path>/vivado -mode batch -source <repo>\run_all_benchmarks.tcl
   ```
3. Vivado will boot up headlessly, compile all simulation files, run all 5 memory `.mem` images for up to 10 milliseconds each, and then close.

### What to Look For
Check the terminal output. The simulated UART will print:
```text
>>> RUNNING BENCHMARK SIMULATION: benchmark.mem
C:00000764
I:00000549
S:000000BF
F:00000052
```
*(C: Cycles, I: Instructions, S: Stalls, F: Flushes)*

**The Verdict:** If the `F` (Flushes) counter is remarkably low compared to the `I` (Instructions) counter (e.g., 82 flushes for 1353 instructions), the dynamic branch predictor is successfully learning and predicting the loop branches.

---

## Method 2: Unit Testing the BHT (`tb_bht.sv`)
If you want to verify the exact logic of the 2-bit saturating counters independently from the pipeline, run the BHT unit test.

### Steps to Verify
1. In Vivado GUI, navigate to the **Sources** pane.
2. Expand `Simulation Sources > sim_1`.
3. Right-click on `tb_bht.sv` and select **Set as Top**.
4. Click **Run Simulation > Run Behavioral Simulation** in the Flow Navigator.

### What to Look For
1. **Console Output:** The testbench will print pass/fail results for state machine transitions. You should see `*** BHT UNIT TEST PASSED ***`.
2. **Waveforms:** Open the Waveform viewer. Add `predict_taken` and `actual_taken`. Watch how the module reacts when `update_en` is pulsed. You will physically see the 2-bit internal state saturate at `11` (Strongly Taken) even if you keep training it.

---

## Method 3: Real FPGA Hardware Verification
Once you are ready to synthesize and program the physical PYNQ-Z2 board, you can verify the performance counters on silicon.

### Steps to Verify
1. Generate the bitstream in Vivado and program the PYNQ-Z2 board.
2. Open a Serial Terminal (PuTTY/TeraTerm) at `115200` baud.
3. Use the Python loader script to push the compiled benchmark to the board:
   ```bash
   python tools/mem_to_load_commands.py sw/demos/benchmark.mem -f interactive --port COM3
   ```
4. In the interactive prompt, type `run` to execute the program.
5. Once the program completes, type `perf` to dump the hardware performance counters.
