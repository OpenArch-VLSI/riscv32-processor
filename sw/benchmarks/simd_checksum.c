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
    // Ensure 4-byte alignment
    uint32_t data32_array[64];
    uint8_t* data = (uint8_t*)data32_array;
    
    // Initialize data to small values to prevent 8-bit lane overflow in SIMD
    for (int i = 0; i < 256; i++) {
        data[i] = i % 4;
    }
    
    // Start measuring
    uint32_t start_cycles = PERF_CYCLES;
    uint32_t start_instrs = PERF_INSTRS;
    
    // Compute checksum using SIMD PADD8
    uint32_t simd_sum = 0;
    uint32_t* data32 = (uint32_t*)data;
    
    for (int i = 0; i < 64; i++) {
        uint32_t val = data32[i];
        // PADD8: Custom-0 (0x0B), funct3=0, funct7=0
        asm volatile (
            ".insn r 0x0B, 0, 0, %0, %1, %2"
            : "=r" (simd_sum)
            : "r" (simd_sum), "r" (val)
        );
    }
    
    // Horizontal reduction of the 4 packed bytes
    uint32_t sum = (simd_sum & 0xFF) + 
                   ((simd_sum >> 8) & 0xFF) + 
                   ((simd_sum >> 16) & 0xFF) + 
                   ((simd_sum >> 24) & 0xFF);
                   
    uint32_t end_cycles = PERF_CYCLES;
    uint32_t end_instrs = PERF_INSTRS;
    
    // Print SUM
    putchar('S'); putchar('U'); putchar('M'); putchar(':'); putchar(' ');
    print_hex(sum); putchar('\r'); putchar('\n');
    
    // Print Perf
    putchar('D'); putchar('C'); putchar('Y'); putchar('C'); putchar(':'); putchar(' ');
    print_hex(end_cycles - start_cycles); putchar('\r'); putchar('\n');
    
    putchar('D'); putchar('I'); putchar('N'); putchar('S'); putchar(':'); putchar(' ');
    print_hex(end_instrs - start_instrs); putchar('\r'); putchar('\n');
    
    return 0;
}
