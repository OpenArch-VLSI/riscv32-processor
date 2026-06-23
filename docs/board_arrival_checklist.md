# Board Arrival Mandatory Checklist

This checklist contains all the deferred hardware-verification tasks. **As soon as the PYNQ-Z2 board arrives, these tasks must be completed in order before proceeding with any further RTL development.**

## The Mandatory Board Proof Sequence

### 1. Phase 0: The Baseline Physical Proof
- [ ] **Hardware Setup:** Connect the PMODA TX/RX pins to the USB-UART adapter and plug it into the host PC.
- [ ] **Bitstream Programming:** Flash the Phase 0/4 bitstream onto the PYNQ-Z2 board.
- [ ] **Terminal Connection:** Open a serial terminal (e.g., PuTTY or minicom) at the configured baud rate.
- [ ] **Verify Execution:** Confirm that the pre-loaded ROM program runs and prints cycle, instruction, stall, and flush counts to the real UART terminal.
- [ ] **Documentation:** Capture a terminal log or video demo and save it as proof in the repository.

### 2. Phase 4: The Monitor & Loader Proof
- [ ] **Interactive Loader Test:** Use `tools/mem_to_load_commands.py -f interactive` to connect to the board.
- [ ] **Command Execution:** Run the `help`, `regs`, `perf`, and `trace` commands to verify the monitor FSM responds correctly.
- [ ] **Program Loading:** Load a new small program over UART using the `load` command and execute it using `run`. Verify it works identically to simulation.

### 3. Phase-Specific Board Demos (If implemented prior to board arrival)
- [ ] **Phase 5 (Traps & Timers):** Load and run the timer interrupt demo over UART. Verify the trap handler executes and prints proof over UART.
- [ ] **Phase 6 (RV32M):** Load and run an RV32M multiply/divide benchmark over UART.
- [ ] **Phase 7 (C Programs):** Load and run the compiled C "Hello World" or Fibonacci program.
- [ ] **Phase 8-10 (Benchmarks):** Run any implemented prediction/SIMD/workload benchmarks and record physical timing and CPI outputs.
