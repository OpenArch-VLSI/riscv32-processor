# Board Arrival Mandatory Checklist

This checklist contains all the deferred hardware-verification tasks. **As soon as the PYNQ-Z2 board arrives, these tasks must be completed in order before proceeding with any further RTL development.**

## The Mandatory Board Proof Sequence

### 1. Phase 0: The Baseline Physical Proof
- [ ] **Hardware Setup:** Connect the PMODA TX/RX pins to the USB-UART adapter and plug it into the host PC.
- [ ] **Regenerate Bitstream:** ⚠️ Regenerate bitstream from current HEAD before flashing. The stored bitstream predates Phase 12. Phase 12 adds three new peripherals — verify timing closure (WNS must remain positive) after regeneration.
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

### 4. Phase 9 (Custom SIMD Extension): Board Proof
- [ ] **Load SIMD benchmark:** Load sw/simd_checksum.mem via tools/mem_to_load_commands.py.
- [ ] **Verify results:** Run and confirm UART output shows correct PADD8/PSUB8/PAVG8 results matching tb_phase9.sv expected values.
- [ ] **Speedup measurement:** Time SIMD vs scalar checksum runs. Confirm 3.85× speedup from Phase 10 holds on physical hardware.
- [ ] **Save proof:** Capture UART terminal log to results/board_phase9_proof.txt.

### 5. Phase 12 (Optional Peripherals): Board Proof

⚠️ Verified and correct: BTN1=D20, SW0=M20, SW1=M19, PWM_OUT=W18. Regenerate bitstream from current HEAD — Phase 12 peripherals added after last build.

- [ ] **LED Control:** Load a program that writes alternating patterns to 0xD0000000. Verify LEDs toggle correctly and heartbeat disappears on first write. Note: led_sw_ctrl is irreversible without reset.
- [ ] **Button/Switch:** Load a program that polls 0xD0000004 and prints to UART. Toggle BTN1 and SW0/SW1. Confirm bit 0 always reads 0 (BTN0 tied low internally).
- [ ] **PWM Output:** Load a program that sets PERIOD=1000, DUTY=500, CTRL=1. Measure PMODA JA3. Expected: 50% duty at 25 MHz ÷ 1000 = 25 kHz.
- [ ] **Save proof:** Capture terminal logs and oscilloscope screenshot to results/.
