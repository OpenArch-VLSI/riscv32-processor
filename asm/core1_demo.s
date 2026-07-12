# Phase 13 dual-core demo — Core 1 (worker)
#
# Protocol (verified by tb_phase13):
#   1. Wait for ping flag from Core 0, read payload (8), clear flag
#   2. Print "C1: RCVD 8" then "C1: SENT 16"
#   3. Send payload*2 (16) back via mailbox, raise pong flag
#   4. Park forever
#
# Core 1 only touches the shared UART between receiving the ping flag
# and raising the pong flag, so it never collides with Core 0.

.section .text
.global _start

# Print one character: wait while tx_busy, then write to TX data register.
# The trailing nops give tx_busy time to assert before the next poll
# (the status write takes a few cycles to propagate through the pipeline).
.macro PUTC ch
1:  lw   t0, 0(s0)          # UART status: bit0 = tx_busy
    andi t0, t0, 1
    bnez t0, 1b
    li   a0, \ch
    sw   a0, 0(s1)
    nop
    nop
    nop
.endm

# Wait until our UART transmitter is completely idle
.macro TXIDLE
    nop
    nop
    nop
1:  lw   t0, 0(s0)
    andi t0, t0, 1
    bnez t0, 1b
.endm

_start:
    li   sp, 0x00001000     # Stack (unused, set up just in case)
    li   s0, 0x80000000     # UART status
    li   s1, 0x80000004     # UART TX data
    li   s3, 0xC0000500     # MAILBOX C0_TO_C1_DATA
    li   s4, 0xC0000504     # MAILBOX C0_TO_C1_FLAG
    li   s5, 0xC0000508     # MAILBOX C1_TO_C0_DATA
    li   s6, 0xC000050C     # MAILBOX C1_TO_C0_FLAG

    # ---- Wait for ping from Core 0 ----
wait_ping:
    lw   t0, 0(s4)
    andi t0, t0, 1
    beqz t0, wait_ping

    lw   s7, 0(s3)          # ping payload, expect 8
    sw   zero, 0(s4)        # clear ping flag

    # ---- "C1: RCVD 8\n" ----
    PUTC 0x43               # C
    PUTC 0x31               # 1
    PUTC 0x3A               # :
    PUTC 0x20               # (space)
    PUTC 0x52               # R
    PUTC 0x43               # C
    PUTC 0x56               # V
    PUTC 0x44               # D
    PUTC 0x20               # (space)
    PUTC 0x38               # 8
    PUTC 0x0A               # \n

    # ---- "C1: SENT 16\n" ----
    PUTC 0x43               # C
    PUTC 0x31               # 1
    PUTC 0x3A               # :
    PUTC 0x20               # (space)
    PUTC 0x53               # S
    PUTC 0x45               # E
    PUTC 0x4E               # N
    PUTC 0x54               # T
    PUTC 0x20               # (space)
    PUTC 0x31               # 1
    PUTC 0x36               # 6
    PUTC 0x0A               # \n
    TXIDLE                  # drain before handing UART back to Core 0

    # ---- Pong: payload = 2 * ping, then raise flag ----
    slli s8, s7, 1          # 8 -> 16
    sw   s8, 0(s5)
    li   t0, 1
    sw   t0, 0(s6)

done:
    j    done
