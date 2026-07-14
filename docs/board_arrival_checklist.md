# Board Arrival Mandatory Checklist

This checklist contains all the deferred hardware-verification tasks. **As soon as the PYNQ-Z2 board arrives, these tasks must be completed in order before proceeding with any further RTL development.**

> **Bitstream note:** The current HEAD (`git HEAD`) builds the **Phase 13 dual-core bitstream**. Sections 1 and 6 use this bitstream. Sections 2, 3, 4, and 5 each require a **separate single-core bitstream** built from the appropriate phase tag — they cannot be run with the Phase 13 dual-core bitstream because the monitor loader and debug readback ports are all hardwired to zero in `fpga_top.sv` (lines 141–158).

---

## The Mandatory Board Proof Sequence

### 1. Phase 13 (Dual-Core): The Baseline Physical Proof

> **Bitstream:** Phase 13 dual-core (current HEAD). Flash this bitstream for this section.
>
> **Hardware prerequisite — PMODA wiring:** PMODA is a **female socket** connector (12 holes, not pins). You need **male-to-female Dupont jumper wires**. Connect as follows. Pin 1 is at the **top-right** of the PMODA connector when the USB ports are facing you and the PMODA label is readable:
>
> | CP2102 adapter pin | Wire to PMODA hole | FPGA pin | Signal                |
> | ------------------ | ------------------ | -------- | --------------------- |
> | RX                 | Pin 1 (top-right)  | Y18      | `uart_txd` (CPU → PC) |
> | TX                 | Pin 2              | Y19      | `uart_rxd` (PC → CPU) |
> | GND                | Pin 5 or Pin 11    | GND      | Ground                |

- [ ] **Hardware Setup:** Connect male-to-female jumper wires between PMODA and the CP2102 USB-UART adapter as described above. Plug the CP2102 into the host PC.
- [ ] **Generate Bitstream:** Build the Phase 13 bitstream from current HEAD. Verify timing closure: WNS must be positive (known-good baseline: +5.265 ns). Do **not** use a stored bitstream — regenerate from source.
- [ ] **Program the Board:** In Vivado Hardware Manager → Open Target → Auto Connect. Right-click device → Program Device → select the `.bit` file. Confirm the `DONE` LED lights up.
- [ ] **Terminal Connection:** Open a serial terminal (e.g., PuTTY or minicom) at the configured baud rate (115200). Select the CP2102 COM/tty port.
- [ ] **Verify Boot Sequence:** Press BTN0 (active-high reset). Confirm the terminal prints **exactly** these five lines in order:
  ```
  C0: SENT 8
  C1: RCVD 8
  C1: SENT 16
  C0: ACK RCVD
  C0: DUAL-CORE OK
  ```
  If Core 0 receives the wrong payload it prints `C0: ERR` instead of `C0: DUAL-CORE OK` — this is a failure.
- [ ] **Verify LED State:** After the UART output completes, confirm all four LEDs:
  - **LD0 (R14):** blinking at ~4 Hz (heartbeat — board clock counter bit 24 via 125 MHz `clk`)
  - **LD1 (P14):** solid ON (PLL locked)
  - **LD2 (N16):** solid ON (Core 0 halted — core reached its park loop)
  - **LD3 (M14):** solid ON (Core 1 halted — core reached its park loop)
- [ ] **Repeat 3×:** Press BTN0 three more times. Confirm identical five-line output and LED state each time (no intermittent failures or missing lines).
- [ ] **Documentation:** Capture a terminal log to `results/board_phase13_proof.txt` and photograph the LED state to `results/board_phase13_leds.jpg`.

---

### 2. Phase 4: The Monitor & Loader Proof

> ⚠️ **Separate single-core Phase 4 bitstream required.** The Phase 13 dual-core bitstream hardwires all debug readback to zero and does not connect the instruction loader (`fpga_top.sv` lines 141–158). With the Phase 13 bitstream, `regs` prints all zeros, `perf` prints zeros, `trace` returns empty data, and `load`/`run` do not write to any core's memory. Build and flash a single-core Phase 4 bitstream before starting this section.

- [ ] **Flash Phase 4 bitstream:** Build the single-core Phase 4 bitstream and program the board.
- [ ] **Interactive Loader Test:** Use `tools/mem_to_load_commands.py -f interactive` to connect to the board.
- [ ] **Command Execution:** Run `help`, `regs`, `perf`, and `trace`. Verify the monitor FSM responds with **non-zero, meaningful values** (not all zeros).
- [ ] **Program Loading:** Load a small program using the `load` command and execute with `run`. Verify output matches simulation.

---

### 3. Phase-Specific Board Demos

> ⚠️ **Single-core bitstream required for each phase.** Build and flash the appropriate phase bitstream before each demo. The monitor `load` and `run` commands are not functional in the Phase 13 dual-core bitstream.

- [ ] **Phase 5 (Traps & Timers):** Flash Phase 5 bitstream. Load and run the timer interrupt demo over UART. Verify the trap handler executes and prints proof over UART.
- [ ] **Phase 6 (RV32M):** Flash Phase 6 bitstream. Load and run an RV32M multiply/divide benchmark over UART.
- [ ] **Phase 7 (C Programs):** Flash Phase 7 bitstream. Load and run the compiled C "Hello World" or Fibonacci program.
- [ ] **Phase 8–10 (Benchmarks):** Flash the appropriate bitstream. Run prediction/SIMD/workload benchmarks and record physical timing and CPI outputs.

---

### 4. Phase 9 (Custom SIMD Extension): Board Proof

> ⚠️ **Single-core Phase 9 (or later) bitstream required.** The SIMD instructions are not exercisable via the Phase 13 dual-core bitstream.

- [ ] **Flash appropriate bitstream:** Build and flash a single-core bitstream that includes the Phase 9 SIMD extension.
- [ ] **Load SIMD benchmark:** Load `sw/simd_checksum.mem` via `tools/mem_to_load_commands.py`.
- [ ] **Verify results:** Run and confirm UART output shows correct PADD8/PSUB8/PAVG8 results matching `tb_phase9.sv` expected values.
- [ ] **Speedup measurement:** Time SIMD vs scalar checksum runs. Confirm 3.85× speedup from Phase 10 holds on physical hardware.
- [ ] **Save proof:** Capture UART terminal log to `results/board_phase9_proof.txt`.

---

### 5. Phase 12 (Optional Peripherals): Board Proof

> ⚠️ **Separate single-core Phase 12 bitstream required.** In the Phase 13 dual-core bitstream, the Phase 12 peripherals are fully stubbed out:
>
> - `pwm_out` is tied to `1'b0` (`fpga_top.sv` line 173)
> - `led_sw_ctrl`, `raw_btn`, `raw_sw`, and `pwm_out` are all left unconnected on both `dual_core_top` core instances (`dual_core_top.sv` lines 56–59, 85–88)
>
> The Phase 13 dual-core bitstream **cannot** exercise this section. Build and flash a single-core Phase 12 bitstream before starting.
>
> **Verified FPGA pin assignments** (from `pynq_z2.xdc`):
>
> | Signal  | FPGA pin | PYNQ-Z2 connector            | Notes                               |
> | ------- | -------- | ---------------------------- | ----------------------------------- |
> | BTN1    | D20      | On-board button              | BTN0 (D19) is reserved for `rst`    |
> | SW0     | M20      | On-board slide switch        | —                                   |
> | SW1     | M19      | On-board slide switch        | —                                   |
> | PWM_OUT | W18      | PMODA hole **Pin 9** (JA4_P) | ⚠️ Not Pin 3 / JA3 — see note below |
>
> **PWM pin correction:** FPGA pin W18 = JA4_P = PMODA connector hole **Pin 9** (top row, second from right when Pin 1 is at top-right). The XDC comment on line 42–43 incorrectly labels this as `JA3_P` — ignore that comment; the pin assignment (`W18`) is correct.

- [ ] **Flash Phase 12 bitstream:** Build the single-core Phase 12 bitstream and program the board. Regenerate from source — do not use the Phase 13 bitstream.
- [ ] **LED Control:** Load a program that writes alternating patterns to `0xD0000000`. Verify LEDs toggle correctly and the heartbeat disappears on first write. Note: `led_sw_ctrl` is irreversible without a reset.
- [ ] **Button/Switch:** Load a program that polls `0xD0000004` and prints to UART. Toggle BTN1 and SW0/SW1. Confirm bit 0 always reads 0 (BTN0 is tied low internally in the single-core config; `raw_btn[0]` is reserved for reset).
- [ ] **PWM Output:** Load a program that sets PERIOD=1000, DUTY=500, CTRL=1. Connect oscilloscope probe to **PMODA connector hole Pin 9** (JA4_P, FPGA pin W18). Expected: 50% duty cycle at 25 MHz ÷ 1000 = 25 kHz.
- [ ] **Save proof:** Capture terminal logs and oscilloscope screenshot to `results/`.

---

## Quick Reference: LED Map (Phase 13 dual-core bitstream)

| LED | Board label | FPGA pin | Meaning                                                                                                               |
| --- | ----------- | -------- | --------------------------------------------------------------------------------------------------------------------- |
| LD0 | LD0         | R14      | Heartbeat — blinks at ~4 Hz from `heartbeat_counter[24]` on the 125 MHz board clock. Confirms board clock is running. |
| LD1 | LD1         | P14      | PLL locked — solid ON after reset once PLLE2 achieves lock (~1 ms).                                                   |
| LD2 | LD2         | N16      | Core 0 halted — OFF while Core 0 runs; solid ON when Core 0 reaches its `done: j done` park loop.                     |
| LD3 | LD3         | M14      | Core 1 halted — OFF while Core 1 runs; solid ON when Core 1 reaches its `done: j done` park loop.                     |

Source: `fpga_top.sv` line 186: `assign led = {core_status_led[1], core_status_led[0], pll_locked, heartbeat_counter[24]};`
and `dual_core_top.sv` line 121: `assign led = {2'b00, core1_halt, core0_halt};`

---

## Quick Reference: UART Monitor Commands (Phase 13 dual-core bitstream)

| Command          | Status in Phase 13 dual-core   | Notes                                                                 |
| ---------------- | ------------------------------ | --------------------------------------------------------------------- |
| `reset`          | ✅ Functional                  | Asserts `cpu_reset_n`, resets both cores                              |
| UART passthrough | ✅ Functional                  | Bytes received in monitor mode are forwarded to CPU UART              |
| `regs`           | ⚠️ Returns all zeros           | `dbg_reg_data` hardwired to `32'd0`                                   |
| `perf`           | ⚠️ Returns all zeros           | `dbg_perf_*` all hardwired to `32'd0`                                 |
| `trace`          | ⚠️ Returns empty/zeros         | `dbg_trace_*` all hardwired to `32'd0`                                |
| `load`           | ⚠️ Non-functional              | `instr_load_en` port left unconnected                                 |
| `run`            | ⚠️ Partial — resets cores only | Toggles `cpu_reset_n`; program in memory is fixed to preloaded `.mem` |
