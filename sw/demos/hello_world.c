#include "../lib/uart.h"

// Note: Because this soft-core architecture currently uses separate ROM and RAM blocks
// that both map to 0x00000000 without a unified bus or ROM-to-RAM copy mechanism,
// we cannot use string literals like "Hello" directly since they go into .rodata,
// which ends up in instruction memory but cannot be read by LBU (data memory).
// We build the string on the stack to ensure it lives in data memory.

int main() {
    // Call putchar directly to avoid .rodata section generation.
    // In a strict Harvard architecture without a ROM-to-RAM copier,
    // we cannot read initialized string data from the instruction ROM.
    putchar('H');
    putchar('e');
    putchar('l');
    putchar('l');
    putchar('o');
    putchar(' ');
    putchar('W');
    putchar('o');
    putchar('r');
    putchar('l');
    putchar('d');
    putchar('!');
    putchar('\r');
    putchar('\n');

    return 0;
}
