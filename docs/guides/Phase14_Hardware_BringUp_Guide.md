# Phase 14: Hardware Bring-Up Guide

Welcome to the hardware bring-up guide! This guide will walk you through every single step required to get the RISC-V processor running on your physical PYNQ-Z2 board. Even if you have never used Vivado, never wired a breadboard, and never used a serial terminal, this guide will provide all the necessary instructions.

## Table of Contents

1. [What you need before starting](#1-what-you-need-before-starting)
2. [Physical board orientation and one-time jumper checks](#2-physical-board-orientation-and-one-time-jumper-checks)
3. [Wiring the USB-UART adapter to PMODA](#3-wiring-the-usb-uart-adapter-to-pmoda)
4. [Installing the USB-UART driver and confirming the COM port](#4-installing-the-usb-uart-driver-and-confirming-the-com-port)
5. [Installing and configuring a serial terminal (PuTTY)](#5-installing-and-configuring-a-serial-terminal-putty)
6. [Opening the Vivado project and confirming source/constraint files](#6-opening-the-vivado-project-and-confirming-sourceconstraint-files)
7. [Running Synthesis, Implementation, and checking timing](#7-running-synthesis-implementation-and-checking-timing)
8. [Generating the bitstream](#8-generating-the-bitstream)
9. [Programming the board via JTAG](#9-programming-the-board-via-jtag)
10. [Phase 0 — first UART proof](#10-phase-0--first-uart-proof)
11. [Phase 4 — UART monitor and program loader proof](#11-phase-4--uart-monitor-and-program-loader-proof)
12. [Phase 5/6/7/8/9/10 — loading and running each phase's proof program](#12-phase-5678910--loading-and-running-each-phases-proof-program)
13. [Phase 12 — LED, button/switch, and PWM peripheral proof](#13-phase-12--led-buttonswitch-and-pwm-peripheral-proof)
14. [Phase 13 — Dual-core bring-up (the hard part)](#14-phase-13--dual-core-bring-up-the-hard-part)
15. [Full troubleshooting appendix](#15-full-troubleshooting-appendix)
16. [Saving evidence and wrapping up](#16-saving-evidence-and-wrapping-up)

---

## 1. What you need before starting

Before we begin, ensure you have the following physical items.

1. **PYNQ-Z2 Board:** The development board containing the Zynq-7020 chip (part `xc7z020clg400-1`).
2. **Micro-USB to USB-A Cable (Data & Power):** You need exactly 1 of these. This cable provides power to the board and connects the on-board JTAG for flashing our design from your computer.
3. **USB to 3.3V TTL Serial UART Adapter:** You need 1 of these. This allows your computer to read text printed by the processor. **Important:** Ensure you have an adapter designed for **3.3V logic** (many are CP2102, FT232RL, or CH340 based). Avoid adapters hard-wired for 5V logic. Also, ensure your adapter has separate pins sticking out for TX, RX, and GND (ground). If it's just a raw cable without labeled pins at the end, it will be very difficult to wire correctly.
4. **Male-to-Female Jumper Wires (Dupont 2.54mm pitch):** You need at least 3 of these. They are essential to connect the male pins on the USB-UART adapter directly to the female holes on the PYNQ-Z2 board PMODA connector.
5. **Anti-Static Wrist Strap and/or ESD Mat (Recommended):** Protects the board's exposed circuitry from static shock while you handle it.

## 2. Physical board orientation and one-time jumper checks

We need to make sure the board is receiving power from the correct source and is in the correct boot mode.

1. Lay the PYNQ-Z2 board flat on your desk so you can read the "PYNQ-Z2" text upright.
2. Locate the **JP5** power jumper (not J9 — J9 does not exist on this board). JP5 is located near the power switch and slide switches. The jumper is a small plastic cap covering three metal pins labelled USB and REG on the board silkscreen.
3. **Because you are using a 12V DC barrel jack adapter:** verify that the jumper cap on **JP5** is connecting the middle pin and the pin labelled **REG**. This tells the board to draw power from the barrel jack. If it is on "USB", pull the cap straight up and press it down over the REG pins instead.
   - The 12V DC barrel jack (2.1mm centre-positive) plugs into the round power connector on the board edge.
   - The Micro-USB cable still connects to the PROG UART port, but only for JTAG programming — it does not power the board when JP5 is set to REG.
   - Do NOT set JP5 to USB when the 12V adapter is also plugged in.
4. Locate the **JP1** boot mode jumper in the top-right quadrant of the board.
5. Verify that the jumper cap on **JP1** is in the "JTAG" position (connecting the rightmost pins). We are booting the programmable logic directly via the Vivado Hardware Manager using JTAG.

## 3. Wiring the USB-UART adapter to PMODA

Now we will connect the USB-UART adapter to the board using the jumper wires.

1. Locate the **Pmod A** (labeled **PMODA**) connector on the right edge of the board. PMODA is a 2x6 right-angle female socket connector — it has 12 holes, not pins. You need male-to-female Dupont jumper wires. The male (pin) end plugs into the PMODA holes. The female (socket) end goes onto the CP2102 USB-UART adapter pins. Female-to-female wires will not work.
2. Identify Pin 1 of PMODA. Pin 1 is at the top-right of the PMODA connector when the USB ports on the board face toward you and the PMODA label is readable.
3. Wire the CP2102 USB-UART adapter to the board using the following table. The wiring table must match this exactly:

CP2102 adapter RX --> PMODA hole Pin 1 (top-right) --> FPGA pin Y18 --> uart_txd (CPU sends to PC)
CP2102 adapter TX --> PMODA hole Pin 2 --> FPGA pin Y19 --> uart_rxd (PC sends to CPU)
CP2102 adapter GND --> PMODA hole Pin 5 or Pin 11 --> GND

4. **The Cross-Over Concept:** You might wonder why we connected TX to RX and RX to TX. Communication requires a speaker (Transmit/TX) to talk to a listener (Receive/RX). If you connect TX to TX, both sides are shouting at each other and neither is listening. Always connect TX on one device to RX on the other!

## 4. Installing the USB-UART driver and confirming the COM port

1. Plug the USB-UART adapter into a standard USB port on your Windows PC. (Do not plug the PYNQ-Z2 board in yet).
2. Right-click the Windows Start button and select **Device Manager**.
3. In the Device Manager window, click the small arrow next to **Ports (COM & LPT)** to expand the list.
4. Look for an entry matching your adapter (e.g., "Silicon Labs CP210x USB to UART Bridge", "USB-SERIAL CH340", or "USB Serial Port").
5. Note the exact COM port number listed in parentheses at the end of the name (for example, `COM3` or `COM5`). Write this down.
6. **If you do not see the port:** You need to install drivers. Search online for the chip name printed on your adapter (e.g., "CP2102 Windows 10 driver"), download the installer from the manufacturer's official site, run it, and check Device Manager again.

## 5. Installing and configuring a serial terminal (PuTTY)

1. If you don't have PuTTY, go to https://www.putty.org/, download the 64-bit MSI installer, and install it.
2. Open the **PuTTY** application.
3. In the "Category" pane on the left, make sure "Session" is selected at the top.
4. Under "Connection type:" on the right side, click the **Serial** radio button.
5. In the "Serial line" box, erase whatever is there and type your COM port from step 4 exactly (e.g., `COM3`).
6. In the "Speed" box, erase the number and type `115200`. This is the exact baud rate our hardware design uses.
7. In the left "Category" pane, scroll down to the bottom and click on **Serial**.
8. Fill in the exact settings on this page:
   - Speed (baud): `115200`
   - Data bits: `8`
   - Stop bits: `1`
   - Parity: `None`
   - Flow control: `None`
9. Click "Session" in the left pane again. Type `RISCV_UART` in the "Saved Sessions" box and click the **Save** button.
10. Click the **Open** button at the bottom. A black window will appear. It is normal that it is blank because the board isn't powered yet.

## 6. Opening the Vivado project and confirming source/constraint files

1. Open Vivado 2025.2 from your Start Menu.
2. Click **Open Project**, navigate to your repository folder, and double-click `riscv_pipeline_offline.xpr` (located in the `riscv_pipeline_offline` folder).
3. In the "Sources" pane on the left, expand the `Design Sources` folder, and then expand `fpga_top` (or navigate through `sources_1/imports/src/`). Verify you see all the SystemVerilog files (`.sv`) like `dual_core_top.sv`, `pipeline_registers.sv`, etc.
4. In the same "Sources" pane, expand the `Constraints` folder, then `constrs_1`. Verify that `pynq_z2.xdc` is present. This file tells Vivado which physical board pins connect to our design's ports.

## 7. Running Synthesis, Implementation, and checking timing

You must turn the raw code into a physical circuit map. Choose one of the two paths below.

### Option A: The Manual Path (Recommended for first-timers)

1. In the "Flow Navigator" panel on the far left, click **Run Synthesis**. If a dialog appears, click OK. Wait for it to finish (a green checkmark dialog will appear).
2. When synthesis finishes, select "Run Implementation" in the dialog and click OK. Wait for it to finish.
3. Once implementation is complete, select "Open Implemented Design" and click OK.
4. **Critical Timing Check:** In the bottom panel, click the **Timing** tab. Look for the "Design Timing Summary" section.
5. Find the **WNS (Worst Negative Slack)** value. It must be a positive number (the baseline docs note a WNS of `+5.265 ns` or better). If this number is negative (red), the circuit is too slow to run at 25 MHz! **Do not program the board if WNS is negative.**

### Option B: The Scripted Path (Faster)

1. Open the text file `tools/run_impl_gui.tcl` in a text editor like Notepad.
2. Find the `<repo>` placeholder text and replace it with the exact absolute path to your cloned repository (e.g., `C:/Users/YourName/projects/riscv32-processor` — use your actual folder path). Save the file.
3. In Vivado, look at the bottom panel and click the **Tcl Console** tab.
4. Type `source C:/Users/YourName/projects/riscv32-processor/tools/run_impl_gui.tcl` (using forward slashes, substituting your actual repo path) and press Enter. (This resets synthesis, sets the `Flow_RuntimeOptimized` strategy, and runs through to bitstream).
5. Watch the "Design Runs" tab in the bottom panel. Wait until the `impl_1` run shows 100% complete.
6. Exactly like the manual path, open the Implemented Design and manually check the **Timing Summary** to confirm a positive WNS before proceeding. _(Note: you can also use `run_build.tcl` for a pure batch mode build to write reports to disk, but `run_impl_gui.tcl` or the manual path is best to generate the bitstream easily)._

## 8. Generating the bitstream

1. If you used the manual path in Step 7, look in the "Flow Navigator" panel on the left and click **Generate Bitstream**. Wait about 1-2 minutes for the "Bitstream Generation Completed" dialog.
2. If you used the scripted path, this step was already done for you automatically!
3. The final output file is located on your hard drive at: `riscv_pipeline_offline\riscv_pipeline_offline.runs\impl_1\fpga_top.bit`.

## 9. Programming the board via JTAG (Vivado Hardware Manager)

1. Take the Micro-USB cable and plug it into your computer.
2. Plug the other end into the **PROG UART** port on the PYNQ-Z2 board. The red PWR LED will light up.
3. In Vivado's "Flow Navigator" panel, scroll down to the bottom and click **Open Hardware Manager**.
4. A green banner will appear near the top of the main window. Click **Open Target**, then click **Auto Connect**.
5. In the "Hardware" pane that opens, you will see a device tree. Right-click on the FPGA chip (named `xc7z020_1`) and select **Program Device...**.
6. A dialog box will appear. The "Bitstream file" box should already point to your `.bit` file. Click the **Program** button.
7. A progress bar will appear and finish. Look at the PYNQ-Z2 board. The green **DONE** LED next to the buttons will turn on. Your board is now running the custom RISC-V processor!

## 10. Phase 13 — First UART proof (the dual-core mailbox demo)

> ⚠️ **The bitstream you built and flashed in Sections 7–9 is the Phase 13 dual-core bitstream** (`fpga_top.sv` wrapping `dual_core_top.sv`). It does NOT print Phase 0 output. The Phase 0 single-core ROM output (`*** ALL TESTS PASSED ***`) only appears when you flash a separate single-core Phase 0/4 bitstream — see Section 17 for that flow. The first proof with this bitstream is the five-line dual-core mailbox handshake below.

1. Look at the four status LEDs (LD0 to LD3) on the board above the switches:

LD0 (FPGA pin R14) = Heartbeat. Blinks at roughly 4 Hz. Driven by bit 24 of a counter running on the 125 MHz board clock. Starts blinking immediately at power-up — confirms the board oscillator is running.

LD1 (FPGA pin P14) = PLL locked. Solid ON once the PLLE2 clock generator locks after reset (~1 ms). Goes OFF during any reset.

LD2 (FPGA pin N16) = Core 0 halted. OFF while Core 0 is running. Turns solid ON when Core 0 reaches its park loop after printing "C0: DUAL-CORE OK". (With the current `fpga_top.sv` bypass fixes applied, this LED may stay OFF because the assembly parks with `j done` rather than `EBREAK` — this is expected and not a failure.)

LD3 (FPGA pin M14) = Core 1 halted. Same as above for Core 1.

2. Make sure PuTTY is open on your COM port at 115200 baud with **"Implicit CR in every LF"** ticked ON (Terminal → Implicit CR in every LF). Without this, lines will staircase across the screen.

3. On the board, locate pushbutton **BTN0** (the right-most button, connected to pin `D19`). Press it down and release it. This resets both cores.

4. Look at your PuTTY terminal window immediately. You should see exactly these five lines printed once and then stop:

   ```
   C0: SENT 8
   C1: RCVD 8
   C1: SENT 16
   C0: ACK RCVD
   C0: DUAL-CORE OK
   ```

5. After the output stops, LD0 keeps blinking and LD1 stays solid ON. LD2 and LD3 behaviour depends on the exact `fpga_top.sv` version — if the park loop uses `j done` (not `EBREAK`) they remain OFF; this is normal.

6. Press BTN0 two more times and confirm identical output each time with no extra lines and no continuous scrolling. This is your Phase 13 hardware proof.

> **If you see continuous looping output** (the five lines repeating endlessly): your `fpga_top.sv` still has `assign cpu_rst_async = rst | ~pll_locked;` on line 84. Replace it with `assign cpu_rst_async = rst;`, regenerate the bitstream, and reprogram. See the fixed `fpga_top.sv` provided separately.

> **Phase 0 single-core proof** (`*** ALL TESTS PASSED ***` output) requires a separate single-core Phase 0/4 bitstream. See Section 17.

## 11. Phase 4 — UART monitor and program loader proof

--- WARNING ---
The Phase 13 dual-core bitstream hardwires all debug readback ports to zero and leaves the instruction loader disconnected (fpga_top.sv lines 141-158). These monitor commands will respond but return wrong data:

"regs" command → prints x0 through x31 all as 0x00000000. These are NOT real register values.
"perf" command → prints cycles=0, instructions=0, stalls=0, flushes=0. All fake zeros.
"trace" command → returns empty or zero trace data.
"load" command → sends data over UART but nothing is written to any core's memory.
"run" command → resets both cores. The program that runs is the fixed preloaded .mem file, not anything loaded by "load".

Only "reset" (which asserts cpu_reset_n) and basic UART passthrough work correctly in this configuration. To use the full monitor and loader, build and flash a separate single-core Phase 4 bitstream.
--- END WARNING ---

The processor includes a hardware "UART Monitor" mode for interactive debugging and loading programs without needing to reprogram the FPGA via Vivado.

> ⚠️ **You must flash a single-core Phase 4 bitstream before any step in this section.** The Phase 13 dual-core bitstream (currently on the board) cannot run these steps — `regs`, `perf`, `trace`, and `load` all return zeros or do nothing, and `run` only resets the dual cores without loading anything. See the warning block above. Flash the Phase 4 single-core bitstream first, then return here.

**Steps (with single-core Phase 4 bitstream flashed):**

1. First, open a command prompt (or PowerShell) on your Windows PC.
2. Ensure you have the required Python library installed by running: `python -m pip install pyserial`
3. Close your PuTTY terminal window entirely, because PuTTY is currently holding the COM port open, and our Python script needs to use it.
4. In your command prompt, navigate to your repository folder and run:
   ```bash
   python tools/mem_to_load_commands.py asm/core0_demo.mem -f interactive --port COM3
   ```
   _(Replace `COM3` with your actual COM port from Step 4)._
5. You are now in **MONITOR** mode. Type `help` and press Enter. The monitor will respond with a list of available commands.
6. Type `regs` to read all 32 CPU registers. Expect a block of text listing `x0` through `x31` with **non-zero values** (not all zeros — if you see all zeros you are still on the Phase 13 dual-core bitstream).
7. Type `perf` to read the hardware performance counters. Expect a dump of cycle, instruction, stall, and flush counts with **non-zero values**.
8. Type `trace` to dump the recent instruction commit trace buffer. Expect 4 lines of trace data with PC and instructions.
9. Type `load` and press Enter. The Python script will stream the `asm/core0_demo.mem` program over the UART into the processor's memory.
10. Type `run` and press Enter. The processor switches to **RUNNING** mode, executes the program, and prints output back to the terminal.
11. Type `!!!` (three exclamation marks) to escape back to MONITOR mode.

## 12. Phase 5/6/7/8/9/10 — loading and running each phase's proof program

--- WARNING ---
The Phase 13 dual-core bitstream hardwires all debug readback ports to zero and leaves the instruction loader disconnected (fpga_top.sv lines 141-158). These monitor commands will respond but return wrong data:

"regs" command → prints x0 through x31 all as 0x00000000. These are NOT real register values.
"perf" command → prints cycles=0, instructions=0, stalls=0, flushes=0. All fake zeros.
"trace" command → returns empty or zero trace data.
"load" command → sends data over UART but nothing is written to any core's memory.
"run" command → resets both cores. The program that runs is the fixed preloaded .mem file, not anything loaded by "load".

Only "reset" (which asserts cpu_reset_n) and basic UART passthrough work correctly in this configuration. To use the full monitor and loader, build and flash a separate single-core Phase 4 bitstream.
--- END WARNING ---

> ⚠️ **Each phase below requires its own single-core bitstream** built from the correct git tag. Flash the appropriate bitstream in Vivado Hardware Manager before running each phase's test. Do not attempt any of these with the Phase 13 dual-core bitstream — the `load` and `run` commands do not function with it.

Using the exact same `mem_to_load_commands.py` interactive flow from Section 11 (with the correct single-core bitstream flashed for each phase), load and run the `.mem` files located in the `asm/` or `sw/` folder of the project.

- **Phase 5 (Traps & Timers):** Flash Phase 5 single-core bitstream. Load the timer interrupt demo `.mem` file and run it. Verify the trap handler prints proof over UART.
- **Phase 6 (RV32M):** Flash Phase 6 single-core bitstream. Load and run the multiply/divide benchmark. Verify correct results.
- **Phase 7 (C programs):** Flash Phase 7 single-core bitstream. Load and run the compiled C Hello World or Fibonacci `.mem` file. Verify correct output.
- **Phase 8–10 (Benchmarks/SIMD):** Flash the appropriate single-core bitstream. Load `sw/simd_checksum.mem` for Phase 9, run it, and confirm PADD8/PSUB8/PAVG8 results match `tb_phase9.sv` expected values. Time SIMD vs scalar to confirm ~3.85× speedup.
- _(Note: Use only the `.mem` files that actually exist in your `asm/` or `sw/` directory.)_

## 13. Phase 12 — LED, button/switch, and PWM peripheral proof

--- WARNING ---
The Phase 12 peripherals (LED control, button/switch input, PWM output) are NOT active in the Phase 13 dual-core bitstream.

In fpga_top.sv, pwm_out is permanently tied to 0 (line 173: assign pwm_out = 1'b0).
In dual_core_top.sv, led_sw_ctrl, raw_btn, raw_sw, and pwm_out are all left unconnected on both core instances (lines 56-59 and 85-88).

To test the Phase 12 peripherals you must build and flash a separate single-core Phase 12 bitstream. The Phase 13 dual-core bitstream cannot run any test in this section.
--- END WARNING ---

Phase 12 added memory-mapped peripherals. The memory map assigns:

- `LED_CTRL`: `0xD0000000`
- `BTN_SW`: `0xD0000004`
- `PWM_PERIOD`: `0xD0000008`
- `PWM_DUTY`: `0xD000000C`
- `PWM_CTRL`: `0xD0000010`

1. **Flash a single-core Phase 12 bitstream first.** The Phase 13 dual-core bitstream flashed in Step 9 does NOT include these peripherals — `pwm_out` is tied to `1'b0` and all peripheral ports are left unconnected in that build. Build and flash a separate single-core Phase 12 bitstream before continuing.
2. In the interactive Python monitor (with Phase 12 bitstream flashed), load a tiny test program or use memory write commands to write the value `0xF` (binary `1111`) to `LED_CTRL` at address `0xD0000000`.
3. Look at the board: All four LEDs (LD0-LD3) should light up solidly. Note that once you write to this register, the `led_sw_ctrl` signal permanently takes over the LEDs, meaning the blinking heartbeat on LD0 will stop until you press the reset button.
4. To test the buttons and switches, run a polling program reading `BTN_SW` at `0xD0000004` and printing the value. Toggle **BTN1** (pin `D20`), **SW0** (pin `M20`), and **SW1** (pin `M19`). The printed values will change. Notice that reading bit 0 (BTN0) will always yield `0` because BTN0 is hardwired internally as our processor reset.
5. To test PWM output, write the value `1000` to `PWM_PERIOD` (`0xD0000008`), `500` to `PWM_DUTY` (`0xD000000C`), and `1` to `PWM_CTRL` (`0xD0000010`).
6. This sets up a 50% duty cycle signal on **PMODA connector hole Pin 9 (JA4_P, FPGA pin W18)**. The PWM frequency is 25 MHz ÷ `PWM_PERIOD` register value. Since the default `PWM_PERIOD` is `1000`, the default frequency is **25 kHz**. If you have an oscilloscope or multimeter with frequency measurement, probe PMODA connector hole Pin 9. This is the second hole from the right on the top row, when Pin 1 is at the top-right.. You will measure exactly a 25 kHz square wave.

## 14. Phase 13 — Dual-core bring-up (the hard part)

Phase 13 introduces a massive architectural change: two identical CPU cores running side-by-side, sharing a mailbox and a UART transmitter.

**The Problem:**
Up until now, we used `fpga_top.sv` as our top-level file. It contained a `PLLE2_BASE` module to safely divide the board's native 125 MHz clock down to 25 MHz, and inverted our active-high reset.
The Phase 13 source file, `dual_core_top.sv`, is structurally different. It has _no_ clock divider inside it. It also expects an active-low reset (`rst_n`), whereas our physical board button (BTN0) is active-high. Also, it does not expose Phase 12 peripheral ports. If you just synthesize `dual_core_top.sv` directly with the board's 125 MHz clock on pin H16, the CPU will run 5x too fast, the UART baud rate math will be completely wrong, and your terminal will show nothing but garbage characters.

**The Solution:**
You must create a new wrapper module that sits between the physical board pins and `dual_core_top.sv`.

> ✅ **If you have been following this guide from the beginning, you have already done this.** Your existing `fpga_top.sv` in the project IS the correct dual-core wrapper — it already contains the `PLLE2_BASE` clock divider, both `BUFG` primitives, the synchronised reset, and the `dual_core_top` instantiation. You do not need to create a new file. The bitstream you built in Sections 7–9 is already the Phase 13 dual-core bitstream. Skip to step 8 below.

> **Only follow steps 1–7 if you are starting a completely fresh Vivado project from scratch** without the existing `fpga_top.sv`.

1. In Vivado, click "Add Sources", select "Add or create design sources", and click "Create File". Name it `fpga_dual_core_top.sv`.
2. Open the new file and paste the following SystemVerilog code. This is the corrected version with three critical fixes applied (see inline comments):

```systemverilog
module fpga_dual_core_top (
    input  logic clk,        // 125 MHz board clock from pin H16
    input  logic rst,        // Active-high button BTN0 from pin D19
    input  logic uart_rxd,   // PMODA hole Pin 2, FPGA pin Y19
    output logic uart_txd,   // PMODA hole Pin 1, FPGA pin Y18
    output logic [3:0] led   // led[0]=heartbeat, [1]=pll_locked, [2]=core0_halt, [3]=core1_halt
);
    logic cpu_clk;
    logic pll_locked;
    logic pll_clk;
    logic clkfb;
    logic clkfb_buf;

    // Divide 125 MHz to 25 MHz for the CPU
    PLLE2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT(8),
        .CLKFBOUT_PHASE(0.0),
        .CLKIN1_PERIOD(8.000),
        .CLKOUT0_DIVIDE(40),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0.0),
        .DIVCLK_DIVIDE(1),
        .STARTUP_WAIT("FALSE")
    ) u_cpu_pll (
        .CLKIN1(clk),
        .CLKFBIN(clkfb_buf),  // buffered feedback — required for DRC
        .RST(rst),
        .PWRDWN(1'b0),
        .CLKFBOUT(clkfb),
        .CLKOUT0(pll_clk),
        .LOCKED(pll_locked)
    );

    // BUFG on feedback path — required to avoid DRC CLOCK-6 error
    BUFG u_clkfb_buf (
        .I(clkfb),
        .O(clkfb_buf)
    );

    // BUFG on CPU clock — routes onto global clock network, not fabric
    BUFG u_cpu_clk_buf (
        .I(pll_clk),
        .O(cpu_clk)
    );

    logic cpu_rst_async;
    logic [1:0] cpu_rst_sync;
    logic cpu_rst;

    // FIX 1: pll_locked is NOT included in cpu_rst_async.
    // Including ~pll_locked here causes UART TX switching noise to glitch
    // pll_locked LOW, pulsing cpu_rst_async and restarting both cores on
    // every transmitted character, producing continuous looping output.
    assign cpu_rst_async = rst;

    always_ff @(posedge cpu_clk or posedge cpu_rst_async) begin
        if (cpu_rst_async)
            cpu_rst_sync <= 2'b11;
        else
            cpu_rst_sync <= {cpu_rst_sync[0], 1'b0};
    end

    assign cpu_rst = cpu_rst_sync[1];

    // Heartbeat counter on the 125 MHz board clock (not cpu_clk)
    logic [24:0] heartbeat_counter;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) heartbeat_counter <= 25'd0;
        else     heartbeat_counter <= heartbeat_counter + 25'd1;
    end

    logic [3:0] core_status_led;
    logic cpu_halt;

    // FIX 2: uart_rxd is NOT connected to the cores.
    // The CP2102 adapter's TX line produces brief electrical noise when
    // idle. The pipeline's UART receiver interprets this as a framing
    // error, triggering a trap that jumps execution back to PC=0 and
    // restarts the cores. Tying rxd HIGH (UART idle level) eliminates
    // this. The assembly programs never read from UART RX, so this is safe.
    dual_core_top u_core (
        .clk(cpu_clk),
        .rst_n(~cpu_rst),
        .uart_rxd(1'b1),     // tied idle — see FIX 2 above
        .uart_txd(uart_txd),
        .led(core_status_led),
        .halt(cpu_halt)
    );

    // FIX 3: All 4 LEDs are connected, not just 2.
    // The original guide only exposed led[1:0] (R14, P14), dropping
    // core0_halt (N16) and core1_halt (M14) entirely.
    assign led = {core_status_led[1], core_status_led[0],
                  pll_locked, heartbeat_counter[24]};

endmodule
```

3. You also need a constraints (XDC) file. In Vivado, click "Add Sources", select "Add or create constraints", and create a file named `dual_core_pynq_z2.xdc`.
4. Open it and paste the following. Note: all 4 LEDs are constrained (the original guide only had 2):

```tcl
set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 8.000 -waveform {0.000 4.000} [get_ports { clk }]

set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports { rst }]

set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports { uart_txd }]
set_property -dict { PACKAGE_PIN Y19 IOSTANDARD LVCMOS33 } [get_ports { uart_rxd }]
set_false_path -from [get_ports { uart_rxd }]

## LEDs: [0]=heartbeat(R14), [1]=pll_locked(P14), [2]=core0_halt(N16), [3]=core1_halt(M14)
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { led[3] }]
```

5. In Vivado's Sources pane, right-click `fpga_dual_core_top.sv` and select **Set as Top**. Also right-click `dual_core_pynq_z2.xdc` and ensure it is set as the active constraint file.
6. Run Synthesis, run Implementation, and Generate Bitstream.
7. Open the Vivado Hardware Manager and program the board with the new bitstream.
8. Re-open PuTTY (115200 baud, 8N1, "Implicit CR in every LF" ticked ON). Press the **BTN0** reset button on the board.
9. **The Proof:** Over the UART, you will see exactly these five lines, proving the ping-pong mailbox protocol works on hardware:
   ```
   C0: SENT 8
   C1: RCVD 8
   C1: SENT 16
   C0: ACK RCVD
   C0: DUAL-CORE OK
   ```
   _What is happening?_ Core 0 boots up, sends the payload `8` via the shared mailbox to Core 1, and raises a flag. Core 1 sees the flag, reads `8`, multiplies it by 2 to get `16`, and sends it back via the mailbox to Core 0 with its own flag. Core 0 receives `16` and verifies it. They take turns printing to the shared UART transmitter using a multiplexer. Until now, this was only verified in simulation using `tb_phase13.sv` and `results/sim_tb_phase13.ps1` — seeing this on physical silicon is the ultimate proof!

## 15. Full troubleshooting appendix

| Symptom                                              | Likely Cause                                           | Fix                                                                                                                                                                                                                                 |
| ---------------------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **No DONE LED after programming**                    | Board not receiving JTAG commands.                     | Verify Micro-USB is in the **PROG UART** port, not the OTG port. Ensure board is powered (PWR LED on).                                                                                                                              |
| **PuTTY shows nothing at all**                       | Disconnected wires, or wrong COM port.                 | Re-seat jumper wires firmly. Verify PMODA hole Pin 1 (top-right, FPGA Y18) → CP2102 RX, Pin 2 → CP2102 TX, Pin 5 or 11 → GND. Verify PuTTY is connected to the CP2102 COM port, not the Zynq bridge COM port.                       |
| **PuTTY shows garbled/garbage characters**           | Baud rate mismatch, or missing Phase 13 clock divider. | Ensure PuTTY is set to exactly `115200`. For Phase 13, ensure you built the `fpga_dual_core_top` wrapper containing the `PLLE2_BASE`; if you synthesize `dual_core_top` directly, the clock is 5x too fast and ruins the baud math. |
| **PuTTY shows reversed or duplicated characters**    | TX and RX are swapped.                                 | Ensure the adapter's RX pin connects to PMODA hole Pin 1 (top-right, FPGA pin Y18 = board TX), and the adapter's TX pin connects to PMODA hole Pin 2 (FPGA pin Y19 = board RX). Connect TX to RX, not TX to TX!                     |
| **Board not detected in Hardware Manager**           | Missing drivers or loose cable.                        | Try a different USB cable (some cables are "charge-only" and lack data lines). Click Auto Connect again.                                                                                                                            |
| **Wrong COM port selected**                          | Using the board's internal Zynq UART.                  | Go back to Device Manager. Identify the specific CP210x/FTDI/CH340 entry that disappears when you unplug your adapter, and use that COM port number.                                                                                |
| **Negative WNS after adding the Phase 13 wrapper**   | Missing clock constraint.                              | Ensure you copy-pasted the `create_clock` line into your new `dual_core_pynq_z2.xdc` file. Without it, Vivado doesn't know the clock is 125 MHz and won't route properly.                                                           |
| **Phase 12 LEDs never light**                        | led_sw_ctrl bit not asserted.                          | The LEDs will not display your values until you perform the very first write to `0xD0000000`, which flips control from the hardware heartbeat to the CPU.                                                                           |
| **Button/switch reads always zero**                  | Reading the wrong bits or address.                     | Ensure you read from `0xD0000004`. Remember bit 0 is BTN0 (always reads 0), bit 1 is BTN1, bits 2/3 are switches.                                                                                                                   |
| **`mem_to_load_commands.py` fails to import serial** | Missing pyserial library.                              | Run `python -m pip install pyserial` in your command prompt.                                                                                                                                                                        |

## 16. Saving evidence and wrapping up

You have successfully brought up the entire RISC-V processor stack on physical hardware!

1. Gather your evidence: Copy the text from your PuTTY terminal logs and save them as text files in the `results/` folder. For Phase 9, save your timing analysis. For Phase 13, save the 5-line handshake output.
2. Take photos or short video clips of the board running and place them in the `results/` folder.
3. **Important Note:** This whole guide strictly proves the **PL (Programmable Logic)** side of the Zynq-7020 chip. This is a bare-metal, PL-only project. **Do not** drift into attempting to configure the Zynq PS (Processing System), playing with the PYNQ Python framework, or attempting an SD-card Linux boot flow. None of that applies here!

### Ultimate Bring-Up Checklist

- [ ] USB-UART Adapter wired correctly (cross-over: CP2102 RX → PMODA Pin 1, TX → Pin 2, GND → Pin 5).
- [ ] Jumper **JP5** set to **REG** (12V barrel jack power). JP1 set to JTAG.
- [ ] PuTTY configured to 115200 baud, 8N1, "Implicit CR in every LF" ticked ON.
- [ ] Positive WNS timing achieved in Vivado (baseline: +5.265 ns or better).
- [ ] Phase 13 (dual-core, current HEAD): 5-line mailbox proof prints exactly once per BTN0 press.
- [ ] Phase 0/4 (single-core bitstream): ROM demo prints correct Cycle/IPC numbers. `mem_to_load_commands.py` enters interactive monitor with non-zero `regs`/`perf` output.
- [ ] Phase 9 (single-core bitstream): SIMD benchmark run shows ~3.85× speedup.
- [ ] Phase 12 (single-core bitstream): LEDs, buttons, and 25 kHz PWM on PMODA Pin 9 measured successfully.
- [ ] Proof logs and photos saved to `results/`.

## 17. Board Verification for Earlier Phases

The Phase 13 dual-core bitstream (current HEAD) is used for Phase 14 verification. Earlier phases each require a separate single-core bitstream built from the appropriate git tag or branch. None of the following can be verified using the Phase 13 dual-core bitstream.

Phase 0 and Phase 4 — Single-core baseline and UART monitor:
Build a single-core Phase 4 bitstream. Flash it. Connect PMODA as described in Section 3. Open a serial terminal at 115200 baud.

- Verify the ROM program runs and prints cycle count, instruction count, stall count, and flush count over UART.
- Connect using tools/mem_to_load_commands.py in interactive mode.
- Run the "help", "regs", "perf", and "trace" commands. Confirm non-zero meaningful values are returned (not all zeros).
- Load a small program using the "load" command and run it with "run". Confirm it matches simulation output.

Phase 5 (Traps and Timers):
Build and flash the Phase 5 single-core bitstream. Load and run the timer interrupt demo. Verify the trap handler prints proof over UART.

Phase 6 (RV32M multiply/divide):
Build and flash the Phase 6 single-core bitstream. Load and run an RV32M multiply/divide benchmark. Verify correct output over UART.

Phase 7 (C programs):
Build and flash the Phase 7 single-core bitstream. Load and run the compiled C Hello World or Fibonacci program. Verify correct output over UART.

Phase 8, 9, 10 (Benchmarks and SIMD):
Build and flash the appropriate single-core bitstream for each phase. For Phase 9 specifically:

- Load sw/simd_checksum.mem via tools/mem_to_load_commands.py.
- Confirm UART output shows correct PADD8, PSUB8, and PAVG8 results matching tb_phase9.sv expected values.
- Time SIMD vs scalar checksum runs and confirm the 3.85x speedup holds on real hardware.
- Save the terminal log to results/board_phase9_proof.txt.

Phase 12 (Optional peripherals — LED control, buttons, PWM):
IMPORTANT: Build and flash a single-core Phase 12 bitstream. Do NOT use the Phase 13 dual-core bitstream for this — the peripherals are stubbed out.
Verified FPGA pin assignments from pynq_z2.xdc:
BTN1 input = FPGA pin D20 (on-board button, BTN0 is reserved for reset)
SW0 input = FPGA pin M20 (on-board slide switch)
SW1 input = FPGA pin M19 (on-board slide switch)
PWM output = FPGA pin W18 = JA4_P = PMODA connector hole Pin 9 (NOT Pin 3 / JA3)

- Load a program that writes alternating patterns to 0xD0000000. Verify LED toggling. Note: led_sw_ctrl is irreversible without reset.
- Load a program that polls 0xD0000004 and prints over UART. Toggle BTN1 and SW0/SW1. Confirm bit 0 always reads 0.
- Load a program that sets PERIOD=1000, DUTY=500, CTRL=1. Connect oscilloscope to PMODA hole Pin 9. Expected: 50% duty cycle at 25 kHz (25 MHz divided by 1000).
