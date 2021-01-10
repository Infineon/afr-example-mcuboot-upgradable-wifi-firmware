# This file contains the description of sources that are required to enable the OTA
# feature in amazon-freertos.

################################################################################
# Additional Source files and includes needed for OTA support
################################################################################

# OTA / MCUBoot defines
#
# IMPORTANT NOTE: These defines are also used in the building of MCUBOOT
#                 they must EXACTLY match the values added to
#                 mcuboot/boot/cypress/MCUBootApp/MCUBootApp.mk
#
# Must be a multiple of 1024 (must leave __vectors on a 1k boundary)
ifneq ($(CY_TFM_PSA_SUPPORTED),1)
    # Non secure flow
    MCUBOOT_MAX_IMG_SECTORS=$(MAX_IMG_SECTORS)
    MCUBOOT_IMAGE_NUMBER=2
    CY_BOOT_SCRATCH_SIZE=$(MCUBOOT_SCRATCH_SIZE)
    MCUBOOT_BOOTLOADER_SIZE=$(BOOTLOADER_APP_FLASH_SIZE)
    CY_BOOT_BOOTLOADER_SIZE=$(MCUBOOT_BOOTLOADER_SIZE)
    CY_BOOT_PRIMARY_1_START=$(APP1_PRIMARY_SLOT_START_OFFSET)
    CY_BOOT_PRIMARY_1_SIZE=$(MCUBOOT_APP1_SLOT_SIZE)
    CY_BOOT_SECONDARY_1_SIZE=$(MCUBOOT_APP1_SLOT_SIZE)
    CY_BOOT_PRIMARY_2_SIZE=$(MCUBOOT_APP2_SLOT_SIZE)
    CY_BOOT_SECONDARY_2_SIZE=$(MCUBOOT_APP2_SLOT_SIZE)
    CY_BOOT_SECONDARY_1_START=$(APP1_SECONDARY_START_OFFSET)
    CY_BOOT_PRIMARY_2_START=$(APP2_PRIMARY_SLOT_START_OFFSET)
    CY_BOOT_SECONDARY_2_START=$(APP2_SECONDARY_SLOT_START_OFFSET)
else
    $(error "Secure flow not supported !")
endif # CY_TFM_PSA_SUPPORTED

DEFINES+=OTA_SUPPORT=1 \
    MCUBOOT_HEADER_SIZE=$(MCUBOOT_HEADER_SIZE) \
    MCUBOOT_MAX_IMG_SECTORS=$(MCUBOOT_MAX_IMG_SECTORS) \
    CY_BOOT_SCRATCH_SIZE=$(CY_BOOT_SCRATCH_SIZE) \
    MCUBOOT_BOOTLOADER_SIZE=$(MCUBOOT_BOOTLOADER_SIZE) \
    CY_BOOT_BOOTLOADER_SIZE=$(CY_BOOT_BOOTLOADER_SIZE) \
    CY_BOOT_PRIMARY_1_START=$(CY_BOOT_PRIMARY_1_START) \
    CY_BOOT_PRIMARY_1_SIZE=$(CY_BOOT_PRIMARY_1_SIZE) \
    CY_BOOT_SECONDARY_1_SIZE=$(CY_BOOT_PRIMARY_1_SIZE) \
    MCUBOOT_IMAGE_NUMBER=$(MCUBOOT_IMAGE_NUMBER)\
    CY_BOOT_SECONDARY_1_START=$(CY_BOOT_SECONDARY_1_START)

ifeq ($(MCUBOOT_IMAGE_NUMBER),2)
# extra defines for Primary slot 2 and Secondary Slot 2
# Secondary_1 is same size as Primary_1
# Secondary_2 is same size as Primary_2
DEFINES+=\
    CY_BOOT_PRIMARY_2_SIZE=$(CY_BOOT_PRIMARY_2_SIZE) \
    CY_BOOT_SECONDARY_2_SIZE=$(CY_BOOT_PRIMARY_2_SIZE) \
    CY_BOOT_PRIMARY_2_START=$(CY_BOOT_PRIMARY_2_START)\
    CY_BOOT_SECONDARY_2_START=$(CY_BOOT_SECONDARY_2_START)

endif

ifeq ($(OTA_USE_EXTERNAL_FLASH),1)
    # non-zero for secondary slot in external FLASH
    CY_FLASH_ERASE_VALUE=1

    DEFINES+= \
        CY_FLASH_ERASE_VALUE=$(CY_FLASH_ERASE_VALUE)
else
    # zero for secondary slot in internal FLASH
    CY_FLASH_ERASE_VALUE=0

    DEFINES+= \
        CY_FLASH_ERASE_VALUE=$(CY_FLASH_ERASE_VALUE)
endif

# Paths for OTA support

# for if using mcuboot directly
# CY_AFR_MCUBOOT_SCRIPT_FILE_DIR=$(CY_AFR_ROOT)/../mcuboot1.6/scripts
# CY_AFR_MCUBOOT_KEY_DIR=$(CY_AFR_ROOT)/../mcuboot1.6/boot/cypress/keys
# CY_AFR_MCUBOOT_CYFLASH_PAL_DIR=$(CY_AFR_ROOT)/../mcuboot1.6/boot/cypress/cy_flash_pal
# CY_AFR_MCUBOOT_CYFLASH_PAL_DIR=$(CY_AFR_ROOT)/vendors/cypress/common/mcuboot/cy_flash_pal
CY_AFR_OTA_DIR=$(CY_EXTAPP_PATH)/port_support/ota
CY_AFR_MCUBOOT_DIR=$(CY_AFR_OTA_DIR)/mcuboot

# Set default python path.
PYTHON_PATH=python3

ifeq ($(OS),Windows_NT)
    #
    # CygWin/MSYS ?
    #
    CY_WHICH_CYGPATH:=$(shell which cygpath)
    # Override python path based on Host OS.
    PYTHON_PATH=python
ifneq ($(CY_WHICH_CYGPATH),)
    CY_AFR_MCUBOOT_DIR:=$(shell cygpath -m --absolute $(subst \,/,$(CY_AFR_MCUBOOT_DIR)))
    CY_BUILD_LOCATION:=$(shell cygpath -m --absolute $(subst \,/,$(CY_BUILD_LOCATION)))
else
    CY_AFR_MCUBOOT_DIR:=$(subst \,/,$(CY_AFR_MCUBOOT_DIR))
endif
endif

CY_AFR_MCUBOOT_CYFLASH_PAL_DIR=$(CY_AFR_MCUBOOT_DIR)/cy_flash_pal
CY_OUTPUT_FILE_PATH=$(CY_BUILD_LOCATION)/$(APPNAME)/$(TARGET)/$(CONFIG)
CY_INPUT_WIFI_BLOB_LOC=$(CY_BUILD_LOCATION)/../../vendors/cypress/MTB/libraries/wifi-host-driver/WiFi_Host_Driver/resources/firmware/$(CY_COMPONENT)
CY_INPUT_WIFI_BLOB=$(CY_INPUT_WIFI_BLOB_LOC)/$(CY_WIFI_BLOB_NAME).bin
CY_INPUT_WIFI_CLM_BLOB_SRC=$(CY_BUILD_LOCATION)/../../vendors/cypress/MTB/libraries/wifi-host-driver/WiFi_Host_Driver/resources/firmware/$(CY_COMPONENT)/$(CY_WIFI_BLOB_NAME)_clm_blob.txt
CY_OUTPUT_WIFI_CLM_BLOB_BIN=$(CY_OUTPUT_FILE_PATH)/${CY_WIFI_BLOB_NAME}_clm_blob.bin
CY_AFR_SCRIPT_PATH=$(CY_BUILD_LOCATION)/../../projects/cypress/$(PROJ_NAME)/$(APPNAME)/script

# Get the file size of Wi-Fi blob.
WIFI_INPUT_BLOB_SIZE=$(shell ls -g -o $(CY_INPUT_WIFI_BLOB) | awk '{printf $$3}')
CY_PAD_BYTES=$(shell echo $$(( $(ALIGN_BYTES) - ($(WIFI_INPUT_BLOB_SIZE) % $(ALIGN_BYTES)) )) )
DEFINES+=CY_WIFI_BLOB_SIZE=$(WIFI_INPUT_BLOB_SIZE)
DEFINES+=CY_PAD_BYTES=$(CY_PAD_BYTES)

# Convert all .c files to .txt in the given path. 
# This step is not really necessary. However, it is in-place to be compatible with CMake build process. 
# We are using .txt in place of .c in "CY_INPUT_WIFI_CLM_BLOB_SRC" because of this. 
ops:=$(shell $(PYTHON_PATH) script/rename.py --file_dir $(CY_INPUT_WIFI_BLOB_LOC) --in_ext ".c" --out_ext ".txt" )

# Generate CLM blob from source. 
ops:=$(shell mkdir -p $(CY_OUTPUT_FILE_PATH) )
ops:=$(shell $(PYTHON_PATH) script/src_to_bin.py --clm_blob $(CY_INPUT_WIFI_CLM_BLOB_SRC) --out $(CY_OUTPUT_WIFI_CLM_BLOB_BIN) )
# Leave it here for debug.
#$(info $(ops))

# Get the CLM blob size.
CY_WIFI_CLM_BLOB_SIZE=$(shell ls -g -o $(CY_OUTPUT_WIFI_CLM_BLOB_BIN) | awk '{printf $$3}')
DEFINES+=CY_WIFI_CLM_BLOB_SIZE=$(CY_WIFI_CLM_BLOB_SIZE)

# Signing scripts and keys from MCUBoot
IMGTOOL_SCRIPT_NAME=./imgtool.py

# Use "Create" for PSoC 062 instead of "sign", and no key path (use a space " " for keypath to keep batch happy)
# MCUBoot must also be modified to skip checking the signature
#   Comment out and re-build MCUBootApp
#   <mcuboot>/boot/cypress/MCUBootApp/config/mcuboot_config/mcuboot_config.h
#   line 37, 38, 77
# 37: //#define MCUBOOT_SIGN_EC256
# 38: //#define NUM_ECC_BYTES (256 / 8)   // P-256 curve size in bytes, rnok: to make compilable
# 77: //#define MCUBOOT_VALIDATE_PRIMARY_SLOT
ifneq ($(CY_TFM_PSA_SUPPORTED),1)
CY_AFR_MCUBOOT_SCRIPT_FILE_DIR=$(CY_AFR_OTA_DIR)/scripts
CY_AFR_MCUBOOT_KEY_DIR=$(CY_AFR_MCUBOOT_DIR)/keys
CY_AFR_SIGN_SCRIPT_FILE_PATH=./script/sign_script.bash
IMGTOOL_COMMAND_ARG=create
CY_SIGNING_KEY_ARG=" "
else
CY_AFR_MCUBOOT_SCRIPT_FILE_DIR=$(CY_EXTAPP_PATH)/psoc6/psoc64tfm/security
CY_AFR_MCUBOOT_KEY_DIR=$(CY_AFR_MCUBOOT_SCRIPT_FILE_DIR)/keys
CY_AFR_SIGN_SCRIPT_FILE_PATH=$(CY_AFR_OTA_DIR)/scripts/sign_tar.bash
MCUBOOT_KEY_FILE=$(CY_AFR_MCUBOOT_KEY_DIR)/cypress-test-ec-p256.pem
IMGTOOL_COMMAND_ARG=sign
CY_SIGNING_KEY_ARG="-k $(MCUBOOT_KEY_FILE)"
endif

# Path to the linker script to use (if empty, use the default linker script).
# Resolve toolchain name
ifeq ($(TOOLCHAIN),GCC_ARM)
    # for ELF -> HEX conversion
    CY_ELF_TO_HEX=$(CY_CROSSPATH)/bin/arm-none-eabi-objcopy
    ifeq ($(HEADER_OFFSET),)
        CY_ELF_TO_HEX_OPTIONS="-O ihex"
    else
        CY_ELF_TO_HEX_OPTIONS="--change-addresses=$(HEADER_OFFSET) -O ihex"
    endif

    CY_ELF_TO_HEX_FILE_ORDER="elf_first"

else ifeq ($(TOOLCHAIN),IAR)
    # for ELF -> HEX conversion
    CY_ELF_TO_HEX=$(CY_CROSSPATH)/bin/ielftool
    CY_ELF_TO_HEX_OPTIONS="--ihex"
    CY_ELF_TO_HEX_FILE_ORDER="elf_first"
else ifeq ($(TOOLCHAIN),ARM)
    # for ELF -> HEX conversion
    CY_ELF_TO_HEX=$(CY_CROSSPATH)/bin/fromelf
    CY_ELF_TO_HEX_OPTIONS="--i32 --output"
    CY_ELF_TO_HEX_FILE_ORDER="hex_first"

endif

# Define CY_TEST_APP_VERSION_IN_TAR in Application Makefile
# to test application version in TAR archive at start of OTA image download.
#
ifneq ($(CY_TEST_APP_VERSION_IN_TAR),)
DEFINES+=\
    CY_TEST_APP_VERSION_IN_TAR=1\
    APP_VERSION_MAJOR=$(APP_VERSION_MAJOR)\
    APP_VERSION_MINOR=$(APP_VERSION_MINOR)\
    APP_VERSION_BUILD=$(APP_VERSION_BUILD)

    CY_BUILD_VERSION=$(APP_VERSION_MAJOR).$(APP_VERSION_MINOR).$(APP_VERSION_BUILD)

    # tarbal supports only a single version number.
    # If both Wi-Fi blob and app are included together in tha tabal,
    # both firmwares expected to have same version numbers.
    # Override the wi-fi blob version with app version
    CY_WIFI_FW_BLOB_VERSION=$(APP_VERSION_MAJOR).$(APP_VERSION_MINOR).$(APP_VERSION_BUILD)

else

# Default value for scripts if CY_TEST_APP_VERSION_IN_TAR not defined
CY_BUILD_VERSION=0.9.0
CY_WIFI_FW_BLOB_VERSION=0.9.0

endif

# Hex file to BIN conversion
# Toolchain path will always point to MTB toolchain
# Once we have a HEX file, we can make a bin - compiler option not important
CY_OBJ_COPY=$(CY_COMPILER_GCC_ARM_DIR)/bin/arm-none-eabi-objcopy

ifneq ($(CY_TFM_PSA_SUPPORTED),1)
POSTBUILD+=$(CY_AFR_SIGN_SCRIPT_FILE_PATH) $(CY_OUTPUT_FILE_PATH) $(CY_AFR_BUILD)\
    $(CY_ELF_TO_HEX) $(CY_ELF_TO_HEX_OPTIONS) $(CY_ELF_TO_HEX_FILE_ORDER)\
    $(CY_AFR_MCUBOOT_SCRIPT_FILE_DIR) $(IMGTOOL_SCRIPT_NAME) $(IMGTOOL_COMMAND_ARG) $(CY_FLASH_ERASE_VALUE) $(MCUBOOT_HEADER_SIZE)\
    $(MCUBOOT_MAX_IMG_SECTORS) $(CY_BUILD_VERSION) $(CY_BOOT_PRIMARY_1_START) $(CY_BOOT_PRIMARY_1_SIZE)\
    $(CY_SIGNING_KEY_ARG) $(CY_OBJ_COPY) $(TAR_INC_MAIN_APP) $(TAR_INC_WIFI_BLOB) $(CY_INPUT_WIFI_BLOB) $(CY_WIFI_BLOB_NAME).bin \
    $(CY_BOOT_PRIMARY_2_SIZE) $(CY_OUTPUT_WIFI_CLM_BLOB_BIN) $(CY_PAD_BYTES) $(CY_WIFI_FW_BLOB_VERSION)
else
POSTBUILD+=$(CY_AFR_SIGN_SCRIPT_FILE_PATH) $(CY_OUTPUT_FILE_PATH) $(CY_AFR_BUILD) $(CY_OBJ_COPY)\
    $(CY_AFR_MCUBOOT_SCRIPT_FILE_DIR) $(IMGTOOL_SCRIPT_NAME) $(IMGTOOL_COMMAND_ARG) $(CY_FLASH_ERASE_VALUE) $(MCUBOOT_HEADER_SIZE)\
    $(CY_BUILD_VERSION) $(CY_BOOT_PRIMARY_1_START) $(CY_BOOT_PRIMARY_1_SIZE)\
    $(CY_BOOT_PRIMARY_2_SIZE) $(CY_BOOT_SECONDARY_1_START)\
    $(CY_AFR_MCUBOOT_KEY_DIR) $(CY_SIGNING_KEY_ARG)
endif

# MCUBoot location
SOURCES+=\
    $(wildcard $(CY_AFR_BOARD_PATH)/ports/ota/*.c)\
    $(wildcard $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/src/http/*.c)\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/src/aws_iot_ota_agent.c\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/src/http/aws_iot_ota_http.c\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/src/mqtt/aws_iot_ota_mqtt.c\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/src/mqtt/aws_iot_ota_cbor.c\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/src/aws_iot_ota_interface.c\
    $(CY_AFR_ROOT)/libraries/3rdparty/jsmn/jsmn.c\
    $(CY_AFR_MCUBOOT_CYFLASH_PAL_DIR)/cy_flash_map.c\
    $(CY_AFR_MCUBOOT_CYFLASH_PAL_DIR)/cy_flash_psoc6.c\
    $(CY_AFR_MCUBOOT_DIR)/bootutil/src/bootutil_misc.c\
    $(CY_EXTAPP_PATH)/libraries/connectivity-utilities/JSON_parser/cy_json_parser.c\
    $(CY_EXTAPP_PATH)/port_support/untar/untar.c\

ifneq ($(CY_TFM_PSA_SUPPORTED),1)
SOURCES+=\
    $(CY_AFR_BOARD_PATH)/ports/ota/aws_ota_pal.c
else
SOURCES+=\
    $(wildcard $(CY_AFR_OTA_DIR)/ports/$(CY_AFR_TARGET)/*.c)
endif

ifeq ($(OTA_USE_EXTERNAL_FLASH),1)
SOURCES+=\
    $(CY_AFR_MCUBOOT_CYFLASH_PAL_DIR)/cy_smif_psoc6.c\
    $(CY_AFR_MCUBOOT_CYFLASH_PAL_DIR)/flash_qspi/flash_qspi.c
endif

INCLUDES+=\
    $(CY_AFR_MCUBOOT_DIR)\
    $(CY_AFR_MCUBOOT_DIR)/config\
    $(CY_AFR_MCUBOOT_DIR)/mcuboot_header\
    $(CY_AFR_MCUBOOT_DIR)/bootutil/include\
    $(CY_AFR_MCUBOOT_DIR)/sysflash\
    $(CY_AFR_MCUBOOT_CYFLASH_PAL_DIR)\
    $(CY_AFR_MCUBOOT_CYFLASH_PAL_DIR)/include\
    $(CY_AFR_MCUBOOT_CYFLASH_PAL_DIR)/include/flash_map_backend\
    $(CY_AFR_MCUBOOT_CYFLASH_PAL_DIR)/flash_qspi\
    $(CY_EXTAPP_PATH)/libraries/connectivity-utilities/JSON_parser\
    $(CY_EXTAPP_PATH)/port_support/untar\
    $(CY_EXTAPP_PATH)/libraries/connectivity-utilities\
    $(CY_AFR_BOARD_PATH)/ports/ota\
    $(CY_AFR_ROOT)/libraries/freertos_plus/standard/crypto/include\
    $(CY_AFR_ROOT)/libraries/3rdparty/jsmn\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/include\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/src\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/src/http\
    $(CY_AFR_ROOT)/libraries/abstractions/wifi/include

ifeq ($(CY_AFR_IS_TESTING), 1)
# Test code
SOURCES+=\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/test/aws_test_ota_agent.c\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/test/aws_test_ota_pal.c

INCLUDES+=\
    $(CY_AFR_ROOT)/libraries/freertos_plus/aws/ota/test
else
SOURCES+=\
    $(wildcard $(CY_AFR_ROOT)/demos/ota/*.c)
endif