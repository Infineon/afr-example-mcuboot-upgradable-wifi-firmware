################################################################################
# \file Makefile
# \version 1.0
#
# \brief
# Top-level application make file.
#
################################################################################
# \copyright
# Copyright 2018-2021 Cypress Semiconductor Corporation
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

# Name of example.
CY_AFR_BUILD=app_cm4

# Project name, where all the sample applications resides in.
PROJ_NAME=afr-example-mcuboot-upgradable-wifi-firmware

# Root location of AFR directory
CY_AFR_ROOT=../../../..

# Define Image type. Default to Upgrade. Supported UPGRADE and BOOT.
IMG_TYPE?=BOOT

# Default build configuration. Options include:
#
# Debug   -- build with minimal optimizations, focus on debugging.
# Release -- build with full optimizations
CONFIG?=Debug

# Build artifact location
CY_BUILD_RELATIVE_LOCATION=$(CY_AFR_ROOT)/build/$(IMG_TYPE)
CY_BUILD_LOCATION=$(abspath $(CY_BUILD_RELATIVE_LOCATION))

BOOTLOADER_LOCATION=../bootloader_cm0p
################################################################################
# Basic Configuration
################################################################################

# Target board/hardware
TARGET=CY8CPROTO-062-4343W

# Name of application (used to derive name of final linked file).
APPNAME=$(CY_AFR_BUILD)

# Name of toolchain to use. Options include:
#
# GCC_ARM -- GCC 7.2.1, provided with ModusToolbox IDE
# ARM     -- ARM Compiler (must be installed separately)
# IAR     -- IAR Compiler (must be installed separately)
#
# See also: CY_COMPILER_PATH below
TOOLCHAIN=GCC_ARM

# If set to "true" or "1", display full command-lines when building.
VERBOSE=

# Disable BLE_SUPPORT. This code example doesn't support BLE.
BLE_SUPPORT=0

# Set this to 0, if Wi-Fi blob has to be excluded from tarbal. 
TAR_INC_WIFI_BLOB ?= 1

################################################################################
# Advanced Configuration
################################################################################

# Enable optional code that is ordinarily disabled by default.
#
# Available components depend on the specific targeted hardware and firmware
# in use. In general, if you have
#
#    COMPONENTS=foo bar
#
# ... then code in directories named COMPONENT_foo and COMPONENT_bar will be
# added to the build
#
COMPONENTS=FREERTOS

# Like COMPONENTS, but disable optional code that was enabled by default.
DISABLE_COMPONENTS=

# By default the build system automatically looks in the Makefile's directory
# tree for source code and builds it. The SOURCES variable can be used to
# manually add source code to the build process from a location not searched
# by default, or otherwise not found by the build system.
SOURCES=

# Like SOURCES, but for include directories. Value should be paths to
# directories (without a leading -I).
INCLUDES=

# Add additional defines to the build process (without a leading -D).
DEFINES=MBEDTLS_USER_CONFIG_FILE=\"mbedtls_user_config_afr.h\" MBEDTLS_CONFIG_FILE=\"aws_mbedtls_config.h\"

# Select softfp or hardfp floating point. Default is softfp.
VFP_SELECT=

# Additional / custom C compiler flags.
#
# NOTE: Includes and defines should use the INCLUDES and DEFINES variable
# above.
CFLAGS=

# Additional / custom C++ compiler flags.
#
# NOTE: Includes and defines should use the INCLUDES and DEFINES variable
# above.
CXXFLAGS=

# Additional / custom assembler flags.
#
# NOTE: Includes and defines should use the INCLUDES and DEFINES variable
# above.
ASFLAGS=

# Additional / custom linker flags.
LDFLAGS=

# Path to the linker script to use (if empty, use the default linker script).
LINKER_SCRIPT=

# Custom pre-build commands to run.
PREBUILD=

# Custom post-build commands to run.
POSTBUILD=

################################################################################
# OTA Configuration
################################################################################

# Main app is part of the tarbal always. 
TAR_INC_MAIN_APP:=1

# Set to 1 to add OTA defines, sources, and libraries (must be used with MCUBoot).
# NOTE: Extra code must be called from your app to initialize AFR OTA Agent.
OTA_SUPPORT:=1

# Default configured to use EXTERNAL FLASH for secondary slot.
# make sure this is set to 1, if OTA support is enabled.
OTA_USE_EXTERNAL_FLASH:=1

# Check for default Version values
CY_TEST_APP_VERSION_IN_TAR:=1
ifeq ($(IMG_TYPE),UPGRADE)
    # Application version
    DEFINES+=UPGRADE_IMG
    APP_VERSION_MAJOR:=2
    APP_VERSION_MINOR:=0
    APP_VERSION_BUILD:=0
else
    # Application version
    DEFINES+=BOOT_IMG
    APP_VERSION_MAJOR:=1
    APP_VERSION_MINOR:=0
    APP_VERSION_BUILD:=0
endif

################################################################################
# Additional configurations.
################################################################################

# This CE requires OTA_SUPPORT to be enabled by default.
# With OTA_SUPPORT enabled, it is mandatory  to use External Flash for secondary slot.
ifeq ($(OTA_SUPPORT),1)
    ifneq ($(OTA_USE_EXTERNAL_FLASH),1)
        $(error OTA_USE_EXTERNAL_FLASH must be set to 1)
    else
        # Use external flash map.
        CY_FLASH_MAP_EXT_DESC=1
        DEFINES+=CY_FLASH_MAP_EXT_DESC=$(CY_FLASH_MAP_EXT_DESC)     # Enable external flash map description.
        DEFINES+=CY_BOOT_USE_EXTERNAL_FLASH                         # Set use external flash by default.
    endif
endif

# Select Wi-Fi blob and size based on TARGET selected. 
ifeq ($(TARGET),CY8CPROTO-062-4343W)
    CY_WIFI_BLOB_NAME=4343WA1
    CY_COMPONENT=COMPONENT_4343W
else ifeq ($(TARGET), CY8CKIT-062S2-43012)
    CY_WIFI_BLOB_NAME=43012C0
    CY_COMPONENT=COMPONENT_43012
else
    $(error Unsupported Target $(TARGET) )
endif

# Define Wi-Fi blob alignment bytes.
# Blobs has to start with 256B or 1KB aligned address. 
ALIGN_BYTES=1024

################################################################################
# Paths
################################################################################

# Include make config.
include $(BOOTLOADER_LOCATION)/config.mk

# Include AFR configuration make file
include ./make_support/afr.mk

# Relative path to the project directory (default is the Makefile's directory).
# This controls where automatic source code discovery looks for code.
CY_APP_PATH=

# Relative path to the "base" library. It provides the core makefile build
# infrastructure.
CY_BASELIB_PATH=$(CY_AFR_ROOT)/vendors/cypress/MTB/psoc6/psoc6make

# Absolute path to the compiler's "bin" directory.
#
# The default depends on the selected TOOLCHAIN (GCC_ARM uses the ModusToolbox
# IDE provided compiler by default).
CY_COMPILER_PATH=

################################################################################
# Tools path
################################################################################

# Locate ModusToolbox IDE helper tools folders in default installation
# locations for Windows, Linux, and macOS.
CY_WIN_HOME=$(subst \,/,$(USERPROFILE))
CY_TOOLS_PATHS ?= $(wildcard \
    $(CY_WIN_HOME)/ModusToolbox/tools_* \
    $(HOME)/ModusToolbox/tools_* \
    /Applications/ModusToolbox/tools_*)

# If you install ModusToolbox IDE in a custom location, add the path to its
# "tools_X.Y" folder (where X and Y are the version number of the tools
# folder).
CY_TOOLS_PATHS+=

# Default to the newest installed tools folder, or the users override (if it's
# found).
CY_TOOLS_DIR=$(lastword $(sort $(wildcard $(CY_TOOLS_PATHS))))

ifeq ($(CY_TOOLS_DIR),)
$(error Unable to find any of the available CY_TOOLS_PATHS -- $(CY_TOOLS_PATHS))
endif

$(info Tools Directory: $(CY_TOOLS_DIR))
include $(CY_TOOLS_DIR)/make/start.mk