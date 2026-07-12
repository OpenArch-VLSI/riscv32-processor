#ifndef UART_H
#define UART_H

#include <stdint.h>

#define UART_STATUS_REG (*(volatile uint32_t*)0x80000000)
#define UART_TX_REG     (*(volatile uint32_t*)0x80000004)
#define UART_RX_REG     (*(volatile uint32_t*)0x80000008)

#define UART_TX_BUSY_BIT 0x01
#define UART_RX_VLD_BIT  0x02

void putchar(char c);
char getchar(void);

#endif
