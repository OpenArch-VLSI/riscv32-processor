#include "uart.h"

void putchar(char c) {
    // Wait until TX is not busy
    while ((UART_STATUS_REG & UART_TX_BUSY_BIT) != 0) {
        // Poll
    }
    UART_TX_REG = c;
}

char getchar(void) {
    // Wait until a received byte is available (reading RX clears the flag)
    while ((UART_STATUS_REG & UART_RX_VLD_BIT) == 0) {
        // Poll
    }
    return (char)(UART_RX_REG & 0xFF);
}
