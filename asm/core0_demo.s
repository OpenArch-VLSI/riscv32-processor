# Phase 13 dual-core demo — Core 0 (master)
#
# Protocol (verified by tb_phase13):
#   1. Print "C0: SENT 8"      then send payload 8 via mailbox, raise ping flag
#   2. Wait for pong flag from Core 1, read payload (expect 16 = 2*8)
#   3. Print "C0: ACK RCVD"
#   4. If payload == 16 print "C0: DUAL-CORE OK", else "C0: ERR"
#   5. Park forever
#
# UART is shared: a core may only transmit while it "owns" the line.
# Ownership is handed over through the mailbox flags, and each core
# drains its own transmitter (TXIDLE) before handing over.

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

    # ---- "C0: SENT 8\n" ----
    PUTC 0x43               # C
    PUTC 0x30               # 0
    PUTC 0x3A               # :
    PUTC 0x20               # (space)
    PUTC 0x53               # S
    PUTC 0x45               # E
    PUTC 0x4E               # N
    PUTC 0x54               # T
    PUTC 0x20               # (space)
    PUTC 0x38               # 8
    PUTC 0x0A               # \n
    TXIDLE                  # drain before handing UART to Core 1

    # ---- Ping: payload 8, then raise flag ----
    li   t1, 8
    sw   t1, 0(s3)
    li   t1, 1
    sw   t1, 0(s4)

    # ---- Wait for pong from Core 1 ----
wait_pong:
    lw   t0, 0(s6)
    andi t0, t0, 1
    beqz t0, wait_pong

    lw   s7, 0(s5)          # pong payload, expect 16
    sw   zero, 0(s6)        # clear pong flag

    # ---- "C0: ACK RCVD\n" ----
    PUTC 0x43               # C
    PUTC 0x30               # 0
    PUTC 0x3A               # :
    PUTC 0x20               # (space)
    PUTC 0x41               # A
    PUTC 0x43               # C
    PUTC 0x4B               # K
    PUTC 0x20               # (space)
    PUTC 0x52               # R
    PUTC 0x43               # C
    PUTC 0x56               # V
    PUTC 0x44               # D
    PUTC 0x0A               # \n

    # ---- Verify payload ----
    li   t0, 16
    bne  s7, t0, data_err

    # ---- "C0: DUAL-CORE OK\n" ----
    PUTC 0x43               # C
    PUTC 0x30               # 0
    PUTC 0x3A               # :
    PUTC 0x20               # (space)
    PUTC 0x44               # D
    PUTC 0x55               # U
    PUTC 0x41               # A
    PUTC 0x4C               # L
    PUTC 0x2D               # -
    PUTC 0x43               # C
    PUTC 0x4F               # O
    PUTC 0x52               # R
    PUTC 0x45               # E
    PUTC 0x20               # (space)
    PUTC 0x4F               # O
    PUTC 0x4B               # K
    PUTC 0x0A               # \n
    TXIDLE
    j    done

data_err:
    # ---- "C0: ERR\n" ----
    PUTC 0x43               # C
    PUTC 0x30               # 0
    PUTC 0x3A               # :
    PUTC 0x20               # (space)
    PUTC 0x45               # E
    PUTC 0x52               # R
    PUTC 0x52               # R
    PUTC 0x0A               # \n
    TXIDLE

done:
    j    done
