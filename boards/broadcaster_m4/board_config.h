#ifndef BOARD_CONFIG_H
#define BOARD_CONFIG_H

#define VENDOR_NAME "Flagtronics"
#define PRODUCT_NAME "Flagtronics M4"
#define VOLUME_LABEL "FT-DeviceBL"
#define INDEX_URL "https://flagtronics.com/"
#define BOARD_ID "Flagtronics-4ch-v1"

#define CRYSTALLESS    1

#define USB_VID 0x04D8
#define USB_PID 0xE7F3

#define BOOT_USART_MODULE                 SERCOM5
#define BOOT_USART_MASK                   APBAMASK
#define BOOT_USART_BUS_CLOCK_INDEX        MCLK_APBDMASK_SERCOM5
#define BOOT_USART_PAD_SETTINGS           UART_RX_PAD1_TX_PAD0
#define BOOT_USART_PAD3                   PINMUX_UNUSED
#define BOOT_USART_PAD2                   PINMUX_UNUSED
#define BOOT_USART_PAD1                   PINMUX_PB03D_SERCOM5_PAD1
#define BOOT_USART_PAD0                   PINMUX_PB02D_SERCOM5_PAD0
#define BOOT_GCLK_ID_CORE                 SERCOM0_GCLK_ID_CORE
#define BOOT_GCLK_ID_SLOW                 SERCOM0_GCLK_ID_SLOW

#endif
