###############################################################################
# libopencm3 generic rules
#
# REQUIRED (set these in your project Makefile before including this file):
#   OPENCM3_DIR   - path to libopencm3 root
#   PROJECT       - basename of the output (no extension)
#   CFILES        - C source files (e.g. main.c src/foo.c)
#   CXXFILES      - C++ source files (must use .cxx suffix)
#   DEVICE        - full device name (e.g. stm32f103cbt6)
#       OR
#   LDSCRIPT      - full path to a linker script
#   OPENCM3_LIB   - libopencm3 variant (e.g. opencm3_stm32f1)
#   OPENCM3_DEFS  - target defines (e.g. -DSTM32F1)
#   ARCH_FLAGS    - CPU arch flags (e.g. -mthumb -mcpu=cortex-m3 ...)
#
# OPTIONAL:
#   INCLUDES      - extra include paths, e.g. -Isrc -Iinclude
#   BUILD_DIR     - build output directory (default: bin)
#   OPT           - optimisation flag (default: -Os)
#   CSTD          - C standard (default: -std=c99)
#   CXXSTD        - C++ standard
#   OOCD_INTERFACE, OOCD_TARGET, OOCD_FILE - OpenOCD config for "make flash"
###############################################################################

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------

BUILD_DIR ?= bin
OPT       ?= -Os
CSTD      ?= -std=c99

CXXFILES  ?=
AFILES    ?=

# ---------------------------------------------------------------------------
# Verbosity
#   make V=0  (default)  quiet
#   make V=1            show compile/link commands
#   make V=99           extra linker info
# ---------------------------------------------------------------------------

V ?= 0

ifeq ($(V),0)
Q    := @
NULL := 2>/dev/null
endif

# ---------------------------------------------------------------------------
# Toolchain
# ---------------------------------------------------------------------------

PREFIX  ?= arm-none-eabi-
CC      := $(PREFIX)gcc
CXX     := $(PREFIX)g++
LD      := $(PREFIX)gcc
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
OOCD    ?= openocd

# ---------------------------------------------------------------------------
# Includes
# ---------------------------------------------------------------------------

OPENCM3_INC := $(OPENCM3_DIR)/include

# libopencm3 includes + any user-provided includes
INCLUDES += -I$(OPENCM3_INC)

# ---------------------------------------------------------------------------
# Object lists
# ---------------------------------------------------------------------------

OBJS  := $(CFILES:%.c=$(BUILD_DIR)/%.o)
OBJS  += $(CXXFILES:%.cxx=$(BUILD_DIR)/%.o)
OBJS  += $(AFILES:%.S=$(BUILD_DIR)/%.o)

GENERATED_BINS := $(PROJECT).elf \
                  $(PROJECT).bin \
                  $(PROJECT).map \
                  $(PROJECT).list \
                  $(PROJECT).lss

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------

# Preprocessor / common C/C++ flags
TGT_CPPFLAGS += -MD
TGT_CPPFLAGS += -Wall -Wundef
TGT_CPPFLAGS += $(INCLUDES)
TGT_CPPFLAGS += $(OPENCM3_DEFS)

# C flags
TGT_CFLAGS  += $(OPT) $(CSTD) -ggdb3
TGT_CFLAGS  += $(ARCH_FLAGS)
TGT_CFLAGS  += -fno-common
TGT_CFLAGS  += -ffunction-sections -fdata-sections
TGT_CFLAGS  += -Wextra -Wshadow -Wno-unused-variable -Wimplicit-function-declaration
TGT_CFLAGS  += -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes

# C++ flags
TGT_CXXFLAGS  += $(OPT) $(CXXSTD) -ggdb3
TGT_CXXFLAGS  += $(ARCH_FLAGS)
TGT_CXXFLAGS  += -fno-common
TGT_CXXFLAGS  += -ffunction-sections -fdata-sections
TGT_CXXFLAGS  += -Wextra -Wshadow -Wredundant-decls -Weffc++

# Assembler flags
TGT_ASFLAGS  += $(OPT) $(ARCH_FLAGS) -ggdb3

# Linker flags
TGT_LDFLAGS  += -T$(LDSCRIPT)
TGT_LDFLAGS  += -L$(OPENCM3_DIR)/lib
TGT_LDFLAGS  += -nostartfiles
TGT_LDFLAGS  += $(ARCH_FLAGS)
TGT_LDFLAGS  += -specs=nano.specs
TGT_LDFLAGS  += -Wl,--gc-sections
#TGT_LDFLAGS += -Wl,-Map=$(PROJECT).map

ifeq ($(V),99)
TGT_LDFLAGS  += -Wl,--print-gc-sections
endif

# Link against libopencm3 when not using the generator-based DEVICE flow
ifeq (,$(DEVICE))
LDLIBS += -l$(OPENCM3_LIB)
endif

LDLIBS += -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group

# ---------------------------------------------------------------------------
# Suffixes / implicit rules
# ---------------------------------------------------------------------------

.SUFFIXES:
.SUFFIXES: .c .S .h .o .cxx .elf .bin .list .lss

# ---------------------------------------------------------------------------
# Top-level targets
# ---------------------------------------------------------------------------

.PHONY: all clean flash

all: $(PROJECT).elf $(PROJECT).bin

flash: $(PROJECT).flash

# ---------------------------------------------------------------------------
# Linker script handling
# ---------------------------------------------------------------------------

ifeq (,$(DEVICE))

$(LDSCRIPT):
ifeq (,$(wildcard $(LDSCRIPT)))
	$(error Unable to find specified linker script: $(LDSCRIPT))
endif

else
# if linker script generator was used, make sure it's cleaned.
GENERATED_BINS += $(LDSCRIPT)
endif

# ---------------------------------------------------------------------------
# Compile rules
# ---------------------------------------------------------------------------

$(BUILD_DIR)/%.o: %.c
	@printf "  CC\t$<\n"
	@mkdir -p $(dir $@)
	$(Q)$(CC) $(TGT_CFLAGS) $(CFLAGS) $(TGT_CPPFLAGS) $(CPPFLAGS) -o $@ -c $<

$(BUILD_DIR)/%.o: %.cxx
	@printf "  CXX\t$<\n"
	@mkdir -p $(dir $@)
	$(Q)$(CXX) $(TGT_CXXFLAGS) $(CXXFLAGS) $(TGT_CPPFLAGS) $(CPPFLAGS) -o $@ -c $<

$(BUILD_DIR)/%.o: %.S
	@printf "  AS\t$<\n"
	@mkdir -p $(dir $@)
	$(Q)$(CC) $(TGT_ASFLAGS) $(ASFLAGS) $(TGT_CPPFLAGS) $(CPPFLAGS) -o $@ -c $<

# ---------------------------------------------------------------------------
# Linking / binary generation
# ---------------------------------------------------------------------------

$(PROJECT).elf: $(OBJS) $(LDSCRIPT) $(LIBDEPS)
	@printf "  LD\t$@\n"
	$(Q)$(LD) $(TGT_LDFLAGS) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $@

%.bin: %.elf
	@printf "  OBJCOPY\t$@\n"
	$(Q)$(OBJCOPY) -O binary $< $@

%.lss: %.elf
	$(OBJDUMP) -h -S $< > $@

%.list: %.elf
	$(OBJDUMP) -S $< > $@

%.flash: %.bin
	@printf "  FLASH\t$<\n"
	st-flash write $< 0x08000000

# ---------------------------------------------------------------------------
# Housekeeping
# ---------------------------------------------------------------------------

clean:
	rm -rf $(BUILD_DIR) $(GENERATED_BINS)

# Include dependency files generated by -MD
-include $(OBJS:.o=.d)
