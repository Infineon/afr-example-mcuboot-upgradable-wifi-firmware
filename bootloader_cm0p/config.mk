################################################################################
# \file shared_config.mk
# \version 1.0
#
# \brief
# Holds configuration and error checking that are common to all three application.
# Ensure that this file is included in the application's
# Makefile after other application-specific variables such as TARGET, 
# USE_EXT_FLASH are defined. 
#
################################################################################
# \copyright
# Copyright 2021 Cypress Semiconductor Corporation
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

# NOTE: Following variables are passed as options to the linker. 
# Ensure that the values have no trailing white space. Linker will throw error
# otherwise. 

# The bootloader app is run by CM0+. Therefore, the scratch size and the
# bootloader size are used with the linker script for the bootloader app. 
# The slot sizes (primary_1, secondary_1, primary_2, and secondary_2) are used
# with the linker script for the applications run by CM4.

# Flash size of MCUBoot Bootloader app run by CM0+
BOOTLOADER_APP_FLASH_SIZE=0x18000

# RAM size of MCUBoot Bootloader app run by CM0+
BOOTLOADER_APP_RAM_SIZE=0x20000

# Scratchpad area.
MCUBOOT_SCRATCH_SIZE=0x1000

# MCUBoot header size
# Header size is used in two places. 
# 1. The location of CM4 image is offset by the header size from the ORIGIN
# value specified in the linker script. 
# 2. Passed to the imgtool while signing the image. The imgtool fills the space
# of this size with zeroes and then adds the actual header starting from address zero. 
MCUBOOT_HEADER_SIZE=0x400

# Define MCUBoot specific parameters for flash layout.
# One slot = MCUboot Header + App + TLV + Trailer (Trailer is not present for BOOT image).
#
# Defines the MCUBoot slot sizes for app1 (slot1 and Slot-2), 1.75MB.
MCUBOOT_APP1_SLOT_SIZE=0x1C0000
# Defines the MCUBoot slot sizes for app2 (slot1 and Slot-2), 768KB.
MCUBOOT_APP2_SLOT_SIZE=0x80000
# MCUBOOT_SLOT_SIZE/FLASH_SECTOR_SIZE. Value is configured for larget slot size.
MAX_IMG_SECTORS=3584
# External flash sector size, 1 erase sector is 256KB for the selected flash. Change this as per your external memory part selected.
EXTERNAL_FLASH_SECTOR_SIZE=0x40000


# Define the offset of each slot w.r.t. beginning of internal flash.
# Offsets are derived based on the size of bootloader and respective slot sizes defined above.
# App1 primary slot start offset.
APP1_PRIMARY_SLOT_START_OFFSET=$(BOOTLOADER_APP_FLASH_SIZE)
# App1 secondary slot start offset (Offset corresponds to start of external flash memory).
APP1_SECONDARY_START_OFFSET=0x8000000
# App2 primary slot start offset.
APP2_PRIMARY_SLOT_START_OFFSET=0x81C0000
# App2 secondary slot start offset.
APP2_SECONDARY_SLOT_START_OFFSET=0x8240000
