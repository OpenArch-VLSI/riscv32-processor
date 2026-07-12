# Memory Map

Last updated: 2026-07-12

<!-- diagrams/src/memory_map.dot updated 2026-07-05; .svg not yet re-rendered from source, run Graphviz to regenerate -->
![Memory Map](../diagrams/rendered/memory_map.svg)

## Memory and MMIO Map

| Address Range / Address | Function | Current Status |
|-------------------------|----------|----------------|
| `0x00000000` region | data memory | implemented through `data_mem.sv`, selected when address high nibble is `0x0` |
| `0x80000000` | UART status | implemented: bit 0 is TX busy, bit 1 is RX data valid |
| `0x80000004` | UART TX data | implemented: write byte 7:0 to transmit |
| `0x80000008` | UART RX data | implemented: read byte 7:0 and clear RX valid |
| `0xC0000000` | cycle counter | implemented as read-only performance-counter MMIO |
| `0xC0000004` | instruction counter | implemented as read-only performance-counter MMIO |
| `0xC0000008` | stall counter | implemented as read-only performance-counter MMIO |
| `0xC000000C` | flush counter | implemented as read-only performance-counter MMIO |
| `0xC0000010` | current PC | implemented as debug MMIO |
| `0xC0000014` | last committed PC | implemented as debug MMIO |
| `0xC0000018` | last committed instruction | implemented as debug MMIO |
| `0xC000001C` | last writeback data | implemented as debug MMIO |
| `0xC0000020` | last writeback status | implemented as debug MMIO; packs register index and reg-write flag |
| `0xC0000024` | faulting PC | implemented as debug MMIO |
| `0xC0000028` | faulting instruction | implemented as debug MMIO |
| `0xC000002C` | pipeline/debug status | implemented as debug MMIO; packs halt, illegal, stall, flush, PC-select, and trace metadata |
| `0xC0000030` | trace head/count | implemented as debug MMIO |
| `0xC0000040-0xC000007F` | 4-entry commit trace buffer | implemented as debug MMIO; each entry stores PC, instruction, writeback data, and a packed status word |
| `0xC0000200` | timer mtime (free-running counter) | implemented as read/write timer MMIO |
| `0xC0000204` | timer mtimecmp (compare value) | implemented as read/write timer MMIO |
| `0xC0000208` | timer control/status (bit 0 = enable, bit 1 = pending) | implemented as read/write timer MMIO |
| `0xC0000410` | core ID | implemented as read-only MMIO |
| `0xC0000500` | mailbox C0_TO_C1_DATA | implemented as read/write shared mailbox data |
| `0xC0000504` | mailbox C0_TO_C1_FLAG | implemented as read/write shared mailbox flag |
| `0xC0000508` | mailbox C1_TO_C0_DATA | implemented as read/write shared mailbox data |
| `0xC000050C` | mailbox C1_TO_C0_FLAG | implemented as read/write shared mailbox flag |
| `0xD0000000` | LED_CTRL | R/W. Bits [3:0] drive board LEDs directly. First write asserts led_sw_ctrl=1 — CPU permanently takes LED control from heartbeat until rst. Read returns current register value. Bits [31:4] zero. |
| `0xD0000004` | BTN_SW | R. Bit 1 = BTN1 (raw_btn_board, debounced). Bit 0 = always 0 (BTN0 reserved for rst, tied low internally). Bits [3:2] = SW1, SW0. Bits [31:4] zero. Writes ignored. 2-stage sync + 20-cycle debounce on buttons. |
| `0xD0000008` | PWM_PERIOD | R/W. PWM counter period in clock cycles. Default: 1000. |
| `0xD000000C` | PWM_DUTY | R/W. Active-high cycles per period. Default: 500. Clamped to PERIOD if DUTY > PERIOD. |
| `0xD0000010` | PWM_CTRL | R/W. Bit 0 = enable. Bit 1 = polarity invert. Default: 0x0. PWM output on PMODA JA3, pin W18 (verified). |

## Phase 12 Peripheral Address Block (0xD000xxxx)

Phase 12 peripherals decoded in mem_stage.sv via bus_ledctrl_*, bus_btnsw_*, bus_pwm_* bundles following the Phase 11 internal bus pattern. Bus mux priority: timer → debug → UART → perf → ledctrl → btnsw → pwm → RAM. XDC pin assignments are verified against PYNQ-Z2 schematic.

## Internal Peripheral Bus

As of Phase 11, `mem_stage` routes every peripheral (RAM, UART, Timer,
Performance Counters, Debug MMIO) through an internal signal-bundle bus
rather than ad-hoc per-peripheral wiring. Each peripheral has its own
`bus_<periph>_addr` / `bus_<periph>_wdata` / `bus_<periph>_rdata` /
`bus_<periph>_byte_en` / `bus_<periph>_re` / `bus_<periph>_we` /
`bus_<periph>_ready` / `bus_<periph>_valid` signal group. The final
read-data mux selects among peripherals by valid signal, in the same
priority order used before the refactor (timer, debug, UART, performance
counters, ledctrl, btnsw, pwm, RAM). This is an internal RTL refactor only — it does not
change any address in the table above. See `tb_memory_map.sv` for the
regression test covering this bus.