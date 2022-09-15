#ifndef BOARD_CONFIG_H
#define BOARD_CONFIG_H

#define VENDOR_NAME "Flagtronics"
#define PRODUCT_NAME "Controller M0"
#define VOLUME_LABEL "FT-Cont-BL"
#define INDEX_URL "https://flagtronics.com/"
#define BOARD_ID "Controller-v0.1"

#define USB_VID 0x04D8
#define USB_PID 0xE7F3

#define NO_DBL_TAP_BOOT
#define PWR_PIN PIN_PA17    //Controller self-on power pin, pull high to stay on. 
#endif
