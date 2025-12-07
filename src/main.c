#include "bsp/bsp_usart.h"

int main(void){
    uart_init();
        do{
            uart_send_string("Testing uart\r");
        } while(1);

    return 0;
}
