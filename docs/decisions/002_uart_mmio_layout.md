# ADR 002: UART MMIO Layout

## Status
Accepted

## Context
The RV32I core needs to communicate with the outside world via UART for both
program output and interactive debugging/loading.

## Decision
Implement memory-mapped I/O for the UART peripheral at base address `0x80000000`:
- `0x80000000` (Read): UART_STATUS (bit 0 = tx_busy, bit 1 = rx_data_valid)
- `0x80000004` (Write): UART_TX_DATA (write byte[7:0] to transmit)
- `0x80000008` (Read): UART_RX_DATA (read byte[7:0], clears valid flag)

Default baud rate: 115200 at 25 MHz CPU clock (CLKS_PER_BIT = 217).

## Consequences
- Simple polled I/O model; no DMA or FIFO.
- Reserves address space starting at `0x80000000` for I/O peripherals.
