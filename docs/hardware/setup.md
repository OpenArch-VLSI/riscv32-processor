# Hardware Setup and Build Guide

> **Board:** PYNQ-Z2 / Zynq-7000 (`xc7z020clg400-1`)  
> **Last verified:** 2026-06-28 (Timing and implementation verified in Vivado; Phase 4 UART monitor added)

---

## FPGA Board
| Field            | Value                          |
|------------------|-------------------------------|
| Board name       | PYNQ-Z2                       |
| FPGA family      | Zynq-7000                     |
| FPGA part number | xc7z020clg400-1               |
| Speed grade      | -1                            |
| Vendor           | AMD / Xilinx                  |

## Toolchain
| Field              | Value                        |
|--------------------|------------------------------|
| Synthesis tool     | Vivado                       |
| Vivado version     | v2025.2 (64-bit)             |
| Simulator          | Vivado XSim v2025.2          |
| Host loader        | `tools/mem_to_load_commands.py` (Python 3 + pyserial for interactive mode) |
| Constraint file    | `riscv_pipeline_offline/riscv_pipeline_offline.srcs/constrs_1/imports/constraints/pynq_z2.xdc` |

## Clock Configuration
| Field              | Value                        |
|--------------------|------------------------------|
| Primary clock      | `clk` (board PL clock input) |
| Frequency          | 125.00 MHz (8.000 ns period) |
| PLL / MMCM used    | `PLLE2_BASE` (instantiated in `fpga_top.sv`) |
| Clock pin          | `H16`                        |
| Constraint         | `create_clock -add -name sys_clk_pin -period 8.000 -waveform {0.000 4.000} [get_ports { clk }]` |

*Note: The PLLE2_BASE block divides the 125 MHz clock to generate a 25 MHz CPU clock (`cpu_clk` / `pll_clk` domain).*

## Reset Configuration
| Field              | Value                        |
|--------------------|------------------------------|
| Reset type         | Asynchronous assert / synchronous de-assert chain |
| Reset polarity     | Active-high (for board input reset button `rst`) |
| Reset pin          | `D19` (Pushbutton BTN0 on PYNQ-Z2 board) |
| Reset behavior     | Asserts reset asynchronously when locked is lost or button pressed; synchronizes release to CPU clock domain. |

## UART Configuration
| Field              | Value                        |
|--------------------|------------------------------|
| Baud rate          | 115200                       |
| TX pin (FPGA)      | `Y18` (PMODA JA1 connector)  |
| RX pin (FPGA)      | `Y19` (PMODA JA2 connector)  |
| Stop bits          | 1                            |
| Parity             | None (8N1 formatting)        |
| Wiring notes       | Connect PMODA JA1 (TX) to USB-UART RX, PMODA JA2 (RX) to USB-UART TX, and JA5/JA9 to Shared Ground. |

## Pin Assignments
| Signal     | FPGA Pin | Direction | Standard | Notes |
|------------|----------|-----------|----------|-------|
| clk        | H16      | IN        | LVCMOS33 | 125 MHz Board Oscillator clock |
| rst        | D19      | IN        | LVCMOS33 | Board reset pushbutton BTN0 |
| uart_txd   | Y18      | OUT       | LVCMOS33 | PMODA JA1 TX signal |
| uart_rxd   | Y19      | IN        | LVCMOS33 | PMODA JA2 RX signal |
| led[0]     | R14      | OUT       | LVCMOS33 | Heartbeat LED (driven by counter bit 24) |
| led[1]     | P14      | OUT       | LVCMOS33 | CPU Running status LED |
| led[2]     | N16      | OUT       | LVCMOS33 | Regression checks PASS status LED |
| led[3]     | M14      | OUT       | LVCMOS33 | Regression checks FAIL / Timeout status LED |
| raw_btn_board | D20   | IN        | LVCMOS33 | Phase 12 button input, BTN1 only |
| raw_sw[0]  | M20      | IN        | LVCMOS33 | Phase 12 slide switch |
| raw_sw[1]  | M19      | IN        | LVCMOS33 | Phase 12 slide switch |
| pwm_out    | W18      | OUT       | LVCMOS33 | Phase 12 PWM output, PMODA JA3 |

## Build Procedure
1. Open Vivado and load the project:
   `open_project riscv_pipeline_offline/riscv_pipeline_offline.xpr`
2. Add all RTL source files from `riscv_pipeline_offline/riscv_pipeline_offline.srcs/sources_1/imports/src/`
3. Add constraint file `riscv_pipeline_offline/riscv_pipeline_offline.srcs/constrs_1/imports/constraints/pynq_z2.xdc`
4. Run Synthesis: `launch_runs synth_1`
5. Run Implementation: `launch_runs impl_1`
6. Check timing summary: WNS must be positive (Baseline `sys_clk` WNS is +5.265 ns, `pll_clk` is +25.005 ns)
7. Proceed to bitstream generation.

## Bitstream Generation
1. After implementation completes successfully:
   `launch_runs impl_1 -to_step write_bitstream`
2. Bitstream output path: `riscv_pipeline_offline/riscv_pipeline_offline.runs/impl_1/fpga_top.bit`
3. Program device via Vivado Hardware Manager.

## Hardware Testing Procedure

### Option 1: ROM Preload (Default Boot)
1. Connect PYNQ-Z2 via USB (JTAG interface) to your host PC.
2. Program the bitstream via Vivado Hardware Manager.
3. Connect a USB-to-UART adapter to the PMODA header (pins Y18 TX, Y19 RX, JA5/9 GND).
4. Open a serial terminal (e.g., PuTTY, TeraTerm) on the host PC at `115200` baud (8N1).
5. Assert and release reset pushbutton BTN0.
6. The CPU boots into the ROM-preloaded demo. Observe the expected performance report:
   ```
   Cycles: 80
   Instructions: 59
   Stalls: 7
   Flushes: 6
   IPC: 0.73
   ```
7. Confirm `led[2]` (pass) turns green, `led[0]` (heartbeat) blinks.

### Option 2: UART Monitor / Program Loader
1. Program the bitstream as above. On power-up, the UART monitor starts in MONITOR mode (CPU held in reset).
2. Open a serial terminal at 115200 baud. You should see no output (monitor is idle).
3. To load a custom program:
   ```bash
   pip install pyserial
   python tools/mem_to_load_commands.py program.mem -f interactive --port COM3
   ```
4. The loader sends `reset`, loads each instruction word via `load`, then sends `run`.
5. CPU program output appears in the terminal. Type `!!!` to escape back to the monitor.
6. In MONITOR mode, use commands: `help`, `regs`, `mem <addr>`, `perf`, `trace`.

### UART Monitor Commands
| Command | Description |
|---------|-------------|
| `help` | Print available commands |
| `load <N> <HEX>` | Write instruction word at address N |
| `run` | Release CPU reset, run program |
| `reset` | Halt CPU, return to monitor |
| `regs` | Dump all 32 registers (x0-x31) |
| `mem <ADDR>` | Read data memory word |
| `perf` | Print performance counters |
| `trace` | Print commit trace buffer |

See `docs/architecture/uart-monitor.md` for the full protocol specification.

## Known Build Issues
- **Board Part Warnings:** Board part warnings (e.g., `[Board 49-26]`) might appear during project load because the local Vivado board database path differs from the initial design system. These warnings do not affect synthesis or timing constraints and can be safely ignored.
