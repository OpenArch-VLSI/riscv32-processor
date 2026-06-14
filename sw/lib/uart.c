#include "uart.h"

void putchar(char c) {
    // Wait until TX is not busy
    while ((UART_STATUS_REG & UART_TX_BUSY_BIT) != 0) {
        // Poll
    }
    UART_TX_REG = c;
}
