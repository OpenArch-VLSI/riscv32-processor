#include "../lib/uart.h"

#define PERF_CYCLES (*(volatile uint32_t*)0xC0000000)
#define PERF_INSTRS (*(volatile uint32_t*)0xC0000004)
#define PERF_STALLS (*(volatile uint32_t*)0xC0000008)
#define PERF_FLUSH  (*(volatile uint32_t*)0xC000000C)

void print_hex(uint32_t val) {
    for (int i = 7; i >= 0; i--) {
        uint32_t nibble = (val >> (i * 4)) & 0xF;
        if (nibble < 10) putchar('0' + nibble);
        else putchar('A' + (nibble - 10));
    }
}

int main() {
    uint32_t data[64];
    
    // Initialize data in descending order (worst case for branching)
    for (int i = 0; i < 64; i++) {
        data[i] = 64 - i;
    }
    
    uint32_t start_cycles = PERF_CYCLES;
    uint32_t start_instrs = PERF_INSTRS;
    uint32_t start_stalls = PERF_STALLS;
    uint32_t start_flushes = PERF_FLUSH;
    
    // Bubble sort
    for (int i = 0; i < 64 - 1; i++) {
        for (int j = 0; j < 64 - i - 1; j++) {
            if (data[j] > data[j+1]) {
                uint32_t tmp = data[j];
                data[j] = data[j+1];
                data[j+1] = tmp;
            }
        }
    }
    
    uint32_t end_cycles = PERF_CYCLES;
    uint32_t end_instrs = PERF_INSTRS;
    uint32_t end_stalls = PERF_STALLS;
    uint32_t end_flushes = PERF_FLUSH;
    
    // Print Perf
    putchar('D'); putchar('C'); putchar('Y'); putchar('C'); putchar(':'); putchar(' ');
    print_hex(end_cycles - start_cycles); putchar('\r'); putchar('\n');
    
    putchar('D'); putchar('I'); putchar('N'); putchar('S'); putchar(':'); putchar(' ');
    print_hex(end_instrs - start_instrs); putchar('\r'); putchar('\n');
    
    putchar('D'); putchar('S'); putchar('T'); putchar('L'); putchar(':'); putchar(' ');
    print_hex(end_stalls - start_stalls); putchar('\r'); putchar('\n');
    
    putchar('D'); putchar('F'); putchar('L'); putchar('S'); putchar(':'); putchar(' ');
    print_hex(end_flushes - start_flushes); putchar('\r'); putchar('\n');
    
    return 0;
}
