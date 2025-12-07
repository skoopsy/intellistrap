PROJECT   = intellistrap_firmware
BUILD_DIR = build

# --- libopencm3 paths & settings ---
OPENCM3_DIR  = ext_libraries/libopencm3
OPENCM3_LIB  = opencm3_stm32f1
OPENCM3_DEFS = -DSTM32F1

# --- Target device ---
DEVICE    = stm32f103cbt6
OOCD_FILE = board/stm32f1x.cfg

# --- CPU arch flags (F1 = Cortex-M3) ---
ARCH_FLAGS = -mthumb -mcpu=cortex-m3

# --- Source files ---
CFILES = src/main.c
CFILES += src/bsp/bsp_usart.c

# --- Include paths (your own headers) ---
INCLUDES += -Isrc
INCLUDES += -Isrc/bsp
INCLUDES += -Iinclude

# --- libopencm3 genlink + rules ---
include $(OPENCM3_DIR)/mk/genlink-config.mk
include rules.mk
include $(OPENCM3_DIR)/mk/genlink-rules.mk
