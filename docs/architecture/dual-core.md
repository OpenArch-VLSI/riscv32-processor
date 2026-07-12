# Dual-Core Architecture

## Overview
This RISC-V processor implementation includes a dual-core SoC extension. The architecture instantiates two identical pipeline cores (`core0` and `core1`) running concurrently, integrated at the top level via `dual_core_top.sv`. Both cores operate on the same clock and reset signals but execute independently.

## Memory Map
The dual-core extension adds a Mailbox peripheral for inter-core communication and a `CORE_ID` memory-mapped register for core identification.

### Mailbox (Base Address: `0xC0000500`)
The mailbox peripheral provides hardware registers for data exchange and synchronization between the two cores.

| Address      | Register Name   | Description |
|--------------|-----------------|-------------|
| `0xC0000500` | `C0_TO_C1_DATA` | Data written by Core 0, read by Core 1 |
| `0xC0000504` | `C0_TO_C1_FLAG` | Flag set by Core 0 to signal Core 1 |
| `0xC0000508` | `C1_TO_C0_DATA` | Data written by Core 1, read by Core 0 |
| `0xC000050C` | `C1_TO_C0_FLAG` | Flag set by Core 1 to signal Core 0 |

### Core Identification (`0xC0000410`)
A read-only `CORE_ID` register is mapped at `0xC0000410` inside the Memory stage.
- **Core 0** reads `0x00000000`
- **Core 1** reads `0x00000001`

## Mailbox Read Timing
Mailbox read data is combinational (same convention as `data_mem`): the pipeline samples MMIO read data during the MEM stage, so `rdata` is valid in the same cycle `re`/`addr` are presented. The `valid` output is a registered one-cycle read-acknowledge pulse. Writes are registered; on a simultaneous write to the same register, Core 0 wins.

## Ping-Pong Mailbox Sequence
The cores communicate using a simple "Ping-Pong" protocol over the Mailbox, demonstrated in the `core0_demo.s` and `core1_demo.s` test programs and verified end-to-end by `tb_phase13.sv`. Both cores share a single UART TX line (the multiplexer selects whichever transmitter is busy, Core 0 first), so UART ownership is handed over through the mailbox flags: a core drains its own transmitter (polls `tx_busy` until idle) before raising a flag that lets the other core print.

1. **Ping (Core 0):**
   - Core 0 prints `C0: SENT 8`, then drains its UART.
   - Core 0 writes payload `8` to `C0_TO_C1_DATA` and sets `C0_TO_C1_FLAG` to `1`.
   - Core 0 enters a polling loop, waiting for `C1_TO_C0_FLAG` to become `1`.

2. **Ping Receive & Pong Send (Core 1):**
   - Core 1 polls `C0_TO_C1_FLAG`; when set, it reads the payload from `C0_TO_C1_DATA` and clears the flag.
   - Core 1 prints `C1: RCVD 8` and `C1: SENT 16`, then drains its UART.
   - Core 1 writes payload × 2 (`16`) to `C1_TO_C0_DATA` and sets `C1_TO_C0_FLAG` to `1`, then parks.

3. **Pong Receive & Verify (Core 0):**
   - Core 0 detects `C1_TO_C0_FLAG`, reads the payload from `C1_TO_C0_DATA`, and clears the flag.
   - Core 0 prints `C0: ACK RCVD`.
   - If the payload equals `16`, Core 0 prints `C0: DUAL-CORE OK` (otherwise `C0: ERR`), then parks.

`tb_phase13.sv` reconstructs the UART byte stream and passes only when all five expected lines are received, which verifies the full round-trip data path (Core 0 → mailbox → Core 1 → compute → mailbox → Core 0) rather than just flag signalling.

Note: the demo programs end in a park loop rather than `ECALL`, because `ECALL` is handled as a trap (redirect to `mtvec`, which resets to 0) — it would restart the program, not halt the core.
