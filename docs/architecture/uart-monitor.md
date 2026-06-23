# UART Monitor Reference

> **Phase 4 Deliverable** — 2026-06-04

The UART monitor (`uart_monitor.sv`) is a command-line interface that sits between the physical UART RX/TX pins and the CPU. It lets you load programs, run them, reset the CPU, and inspect register/memory/perf/trace state — all over a serial terminal.

---

## Architecture

```
PC Terminal  <─── UART ──→ uart_monitor.sv ──→ fpga_top.sv ──→ top.sv (CPU)
                                │
                                ├── instr_load_*   (instruction memory loader)
                                ├── cpu_reset_n     (CPU reset control)
                                ├── monitor_mode    (UART ownership flag)
                                └── dbg_*           (debug read ports)
```

The monitor owns the physical UART. During MONITOR mode, the CPU is held in reset and UART TX goes to the monitor. During RUNNING mode, UART is passed through to the CPU's UART peripheral.

---

## State Machine

| State | Description |
|-------|-------------|
| **MONITOR** | Monitor owns UART. CPU held in reset (`cpu_reset_n = 0`). Commands are parsed and executed. |
| **RUNNING** | UART passthrough to CPU. CPU runs freely. Monitor listens for `!!!` escape sequence to return to MONITOR. |

---

## Commands

All commands are **case-insensitive** and terminated by newline (`\n` or `\r\n`). Hex arguments use lowercase without `0x` prefix.

### `help`
Print available commands.

### `load <word_index> <hex_data>`
Write a 32-bit instruction word into instruction memory at the given word address.

**Example:**
```
load 0 00000293   → writes ADDI x5, x0, 0 at address 0x00000000
load 1 00000313   → writes ADDI x6, x0, 0 at address 0x00000004
```

### `run`
Release CPU reset and switch to RUNNING mode. UART output is forwarded from the CPU's UART TX.

### `reset`
Halt the CPU by asserting reset. Switch back to MONITOR mode.

### `regs`
Dump all 32 integer registers (x0–x31) as hex.

**Example output:**
```
x0  = 0x00000000
x1  = 0x00000005
x2  = 0x00000010
...
x31 = 0x00000000
```

### `mem <hex_addr>`
Read one word from data memory at the given byte address (aligned).

**Example:**
```
mem 0       → mem[0x00000000] = 0x0000000F
mem 10      → mem[0x00000010] = 0xDEADBEEF
```

### `perf`
Print all 4 performance counters (cycles, instructions, stalls, flushes) in both decimal and hex.

**Example output:**
```
Cycles:       1234 (0x000004D2)
Instructions: 42
Stalls:       3
Flushes:      7
```

### `trace`
Print the commit trace buffer. Shows up to 4 recent committed instructions with PC, instruction word, writeback data, and status word.

---

## Host-Side Loader

`tools/mem_to_load_commands.py` supports three modes:

| Mode | Description |
|------|-------------|
| `-f raw` | Emit `LOAD <N> <HEX>` text lines |
| `-f uart` | Emit binary byte stream ready for serial port |
| `-f interactive` | Connect to FPGA via pySerial, run reset→load→run flow |

**Interactive usage:**
```bash
pip install pyserial
python tools/mem_to_load_commands.py program.mem -f interactive --port COM3 --baud 115200
```

---

## Escape Sequence

While the CPU is running (RUNNING mode), typing `!!!` (three exclamation marks) returns to MONITOR mode. The CPU is reset and the monitor prompt is available again.

---

## Baud Rate

Fixed at 115200 baud (CLKS_PER_BIT = 217 at 25 MHz CPU clock).

---

## Limitations

- Full monitor simulation requires `fpga_top` as DUT (not just `top.sv`).
- No disassembly — `trace` and `regs` output raw hex.
- No program-range load — each word must be loaded individually.
- No `load` flood protection — too-rapid loads without inter-byte delay may overflow the UART RX buffer on fast hosts.
