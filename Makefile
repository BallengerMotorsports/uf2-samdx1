#BOARD=controller_m0
BOARD=sign_m0
-include Makefile.user
include boards/$(BOARD)/board.mk
#CC=arm-none-eabi-gcc

ifeq ($(CHIP_FAMILY), samd21)
COMMON_FLAGS = -mthumb -mcpu=cortex-m0plus -Os -g -DSAMD21
endif
ifeq ($(CHIP_FAMILY), samd51)
COMMON_FLAGS = -mthumb -mcpu=cortex-m4 -O2 -g -DSAMD51
endif
WFLAGS = \
-Werror -Wall -Wstrict-prototypes \
-Werror-implicit-function-declaration -Wpointer-arith -std=gnu99 \
-ffunction-sections -fdata-sections -Wchar-subscripts -Wcomment -Wformat=2 \
-Wimplicit-int -Wmain -Wparentheses -Wsequence-point -Wreturn-type -Wswitch \
-Wtrigraphs -Wunused -Wuninitialized -Wunknown-pragmas -Wfloat-equal -Wno-undef \
-Wbad-function-cast -Wwrite-strings -Waggregate-return \
-Wformat -Wmissing-format-attribute \
-Wno-deprecated-declarations -Wpacked -Wredundant-decls -Wnested-externs \
-Wlong-long -Wunreachable-code -Wcast-align \
-Wno-missing-braces -Wno-overflow -Wno-shadow -Wno-attributes -Wno-packed -Wno-pointer-sign
CFLAGS = $(COMMON_FLAGS) \
-x c -c -pipe -nostdlib \
--param max-inline-insns-single=500 \
-fno-strict-aliasing -fdata-sections -ffunction-sections \
-D__$(CHIP_VARIANT)__ \
$(WFLAGS)

UF2_VERSION_BASE = $(shell git describe --dirty --always --tags)
#UF2_VERSION_BASE = 1

ifeq ($(CHIP_FAMILY), samd21)
LINKER_SCRIPT=scripts/samd21j18a.ld
BOOTLOADER_SIZE=8192
SELF_LINKER_SCRIPT=scripts/samd21j18a_self.ld
endif

ifeq ($(CHIP_FAMILY), samd51)
LINKER_SCRIPT=scripts/samd51j19a.ld
BOOTLOADER_SIZE=16384
SELF_LINKER_SCRIPT=scripts/samd51j19a_self.ld
endif

MODULE_PATH?=$(LOCALAPPDATA)/Arduino15/packages/$(CORE_VENDOR)
MODULE_PATH_ARDUINO?=$(LOCALAPPDATA)/Arduino15/packages/arduino
RM=del
SEP=\\
PATHSEP=$(strip $(SEP))
ARM_GCC_PATH?=$(MODULE_PATH_ARDUINO)/tools/arm-none-eabi-gcc/7-2017q4/bin/arm-none-eabi-
BUILD_DIR=build
CC=$(ARM_GCC_PATH)gcc
OBJCOPY=$(ARM_GCC_PATH)objcopy
NM=$(ARM_GCC_PATH)nm
SIZE=$(ARM_GCC_PATH)size

LDFLAGS= $(COMMON_FLAGS) \
-Wall -Wl,--cref -Wl,--check-sections -Wl,--gc-sections -Wl,--unresolved-symbols=report-all -Wl,--warn-common \
-Wl,--warn-section-align \
-save-temps -nostartfiles \
--specs=nano.specs --specs=nosys.specs
#BUILD_PATH=build/$(BOARD)
INCLUDES = -I. -I./inc -I./inc/preprocessor
INCLUDES += -I./boards/$(BOARD) -Ilib/cmsis/CMSIS/Include -Ilib/usb_msc
INCLUDES += -I$(BUILD_DIR)


ifeq ($(CHIP_FAMILY), samd21)
INCLUDES += -Ilib/samd21/samd21a/include/
endif

ifeq ($(CHIP_FAMILY), samd51)
ifeq ($(findstring SAME51,$(CHIP_VARIANT)),SAME51)
INCLUDES += -Ilib/same51/include/
else
ifeq ($(findstring SAME54,$(CHIP_VARIANT)),SAME54)
INCLUDES += -Ilib/same54/include/
else
INCLUDES += -Ilib/samd51/include/
endif
endif
endif

COMMON_SRC = \
	src/flash_$(CHIP_FAMILY).c \
	src/init_$(CHIP_FAMILY).c \
	src/startup_$(CHIP_FAMILY).c \
	src/usart_sam_ba.c \
	src/screen.c \
	src/images.c \
	src/utils.c

SOURCES = $(COMMON_SRC) \
	src/cdc_enumerate.c \
	src/fat.c \
	src/main.c \
	src/msc.c \
	src/sam_ba_monitor.c \
	src/uart_driver.c \
	src/hid.c \

SELF_SOURCES = $(COMMON_SRC) \
	src/selfmain.c

OBJECTS = $(patsubst src/%.c,$(BUILD_DIR)/%.o,$(SOURCES))
SELF_OBJECTS = $(patsubst src/%.c,$(BUILD_DIR)/%.o,$(SELF_SOURCES)) $(BUILD_DIR)/selfdata.o

NAME=bootloader-$(BOARD)-$(UF2_VERSION_BASE)
#NAME=bootloader
EXECUTABLE=$(BUILD_DIR)/$(NAME).bin
SELF_EXECUTABLE=$(BUILD_DIR)/update-$(NAME).uf2
SELF_EXECUTABLE_INO=$(BUILD_DIR)/update-$(NAME).ino

SUBMODULES = lib/uf2/README.md

all: $(SUBMODULES) dirs $(EXECUTABLE) $(SELF_EXECUTABLE)

dirs:
	@echo "Building $(BOARD)"
	-mkdir "$(BUILD_DIR)"

$(EXECUTABLE): $(OBJECTS)
	$(CC) -L$(BUILD_DIR) $(LDFLAGS) \
		 -T$(LINKER_SCRIPT) \
		 -Wl,-Map,$(BUILD_DIR)/$(NAME).map -o $(BUILD_DIR)/$(NAME).elf $(OBJECTS)
	$(OBJCOPY) -O binary $(BUILD_DIR)/$(NAME).elf $@
	@echo
	-@$(SIZE) $(BUILD_DIR)/$(NAME).elf | awk '{ s=$$1+$$2; print } END { print ""; print "Space left: " ($(BOOTLOADER_SIZE)-s) }'
	@echo

$(BUILD_DIR)/uf2_version.h: Makefile
	echo #define UF2_VERSION_BASE $(UF2_VERSION_BASE) > $@

$(SELF_EXECUTABLE): $(SELF_OBJECTS)
	$(CC) -L$(BUILD_DIR) $(LDFLAGS) \
		 -T$(SELF_LINKER_SCRIPT) \
		 -Wl,-Map,$(BUILD_DIR)/update-$(NAME).map -o $(BUILD_DIR)/update-$(NAME).elf $(SELF_OBJECTS)
	$(OBJCOPY) -O binary $(BUILD_DIR)/update-$(NAME).elf $(BUILD_DIR)/update-$(NAME).bin
	py lib/uf2/utils/uf2conv.py -b $(BOOTLOADER_SIZE) -c -o $@ $(BUILD_DIR)/update-$(NAME).bin

$(BUILD_DIR)/%.o: src/%.c $(wildcard inc/*.h boards/*/*.h) $(BUILD_DIR)/uf2_version.h
	echo "$<"
	$(CC) $(CFLAGS) $(BLD_EXTA_FLAGS) $(INCLUDES) $< -o $@

$(BUILD_DIR)/%.o: $(BUILD_DIR)/%.c
	$(CC) $(CFLAGS) $(BLD_EXTA_FLAGS) $(INCLUDES) $< -o $@

$(BUILD_DIR)/selfdata.c: $(EXECUTABLE) scripts/gendata.py src/sketch.cpp
	py scripts/gendata.py $(BOOTLOADER_SIZE) $(EXECUTABLE)

clean:
	del -rf build

gdb:
	arm-none-eabi-gdb $(BUILD_DIR)/$(NAME).elf

tui:
	arm-none-eabi-gdb -tui $(BUILD_DIR)/$(NAME).elf

%.asmdump: %.o
	arm-none-eabi-objdump -d $< > $@

applet0: $(BUILD_DIR)/flash.asmdump
	node scripts/genapplet.js $< flash_write

applet1: $(BUILD_DIR)/utils.asmdump
	node scripts/genapplet.js $< resetIntoApp

drop-board: all
	@echo "*** Copy files for $(BOARD)"
	mkdir -p build/drop
	del -rf build/drop/$(BOARD)
	mkdir -p build/drop/$(BOARD)
	cp $(SELF_EXECUTABLE) build/drop/$(BOARD)/
	cp $(EXECUTABLE) build/drop/$(BOARD)/
# .ino works only for SAMD21 right now; suppress for SAMD51
ifeq ($(CHIP_FAMILY),samd21)
	cp $(SELF_EXECUTABLE_INO) build/drop/$(BOARD)/
	cp boards/$(BOARD)/board_config.h build/drop/$(BOARD)/
endif

drop-pkg:
	mv build/drop build/uf2-samd21-$(UF2_VERSION_BASE)
	cp bin-README.md build/uf2-samd21-$(UF2_VERSION_BASE)/README.md
	cd build; 7z a uf2-samd21-$(UF2_VERSION_BASE).zip uf2-samd21-$(UF2_VERSION_BASE)
	del -rf build/uf2-samd21-$(UF2_VERSION_BASE)

all-boards:
	for f in `cd boards; ls` ; do "$(MAKE)" BOARD=$$f drop-board || break -1; done

drop: all-boards drop-pkg

$(SUBMODULES):
	git submodule update --init --recursive
