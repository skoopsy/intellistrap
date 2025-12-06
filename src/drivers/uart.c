#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/usart.h>

#include "drivers/uart.h"

void uart_init(void){
    // Initialise the uart port

    // Enable the peripheral clock that the USART1 IO pins are on.
    rcc_periph_clock_enable(RCC_GPIOA);
    
    // Enable the peripheral clock specifically for the USART port
    rcc_periph_clock_enable(RCC_USART1);

    // Set the chosen USART GPIO pins to work with UART, note the ALTFN_PUSHPULL, this is specifically for UART
    gpio_set_mode(GPIOA,
                  GPIO_MODE_OUTPUT_50_MHZ,
                  GPIO_CNF_OUTPUT_ALTFN_PUSHPULL,
                  GPIO9 // GPIO_USART1_TX
                  );

    // Initialise USART protocol configuration using libopencm3
    usart_set_baudrate(USART1, 9600);
    usart_set_databits(USART1, 8);
    usart_set_stopbits(USART1, USART_STOPBITS_1);
    usart_set_parity(USART1, USART_PARITY_NONE);
    usart_set_flow_control(USART1, USART_FLOWCONTROL_NONE);
    usart_set_mode(USART1, USART_MODE_TX); // A simple asynchronous transmit only mode.
    usart_enable(USART1);
}


void uart_send_char(char c){
    // Sends a byte via USART1
    usart_send_blocking(USART1, c);
}


void uart_send_string(const char *str){
    // Sends each char (byte) one by one using the previous function
    while (*str) {
        uart_send_char(*str++);
    }
}


