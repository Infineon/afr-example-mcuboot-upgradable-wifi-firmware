/******************************************************************************
* File Name:   ext_flash_map.c
*
* Description:
* This file defines the application specific custom flash map and the API's to
* access the flash memory. File contents are originally obtained from
* "cy_flash_map.c" and customized to meet application's requirements.
*
*******************************************************************************
* (c) 2021, Cypress Semiconductor Corporation. All rights reserved.
*******************************************************************************
* This software, including source code, documentation and related materials
* ("Software"), is owned by Cypress Semiconductor Corporation or one of its
* subsidiaries ("Cypress") and is protected by and subject to worldwide patent
* protection (United States and foreign), United States copyright laws and
* international treaty provisions. Therefore, you may use this Software only
* as provided in the license agreement accompanying the software package from
* which you obtained this Software ("EULA").
*
* If no EULA applies, Cypress hereby grants you a personal, non-exclusive,
* non-transferable license to copy, modify, and compile the Software source
* code solely for use in connection with Cypress's integrated circuit products.
* Any reproduction, modification, translation, compilation, or representation
* of this Software except as specified above is prohibited without the express
* written permission of Cypress.
*
* Disclaimer: THIS SOFTWARE IS PROVIDED AS-IS, WITH NO WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, NONINFRINGEMENT, IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Cypress
* reserves the right to make changes to the Software without notice. Cypress
* does not assume any liability arising out of the application or use of the
* Software or any product or circuit described in the Software. Cypress does
* not authorize its products for use in any products where a malfunction or
* failure of the Cypress product may reasonably be expected to result in
* significant property damage, injury or death ("High Risk Product"). By
* including Cypress's product in a High Risk Product, the manufacturer of such
* system or application assumes all risk of such use and in doing so agrees to
* indemnify Cypress against all liability.
*******************************************************************************/

/* Header file for flash configuration. */
#include "flash_map_backend/flash_map_backend.h"
#include "sysflash.h"

#if defined(CY_FLASH_MAP_EXT_DESC)

#ifndef CY_EXTERNAL_FLASH_SECTOR_SIZE
/* Set external flash sector size to 256 KB by default. */
#define CY_EXTERNAL_FLASH_SECTOR_SIZE           (0x40000)
#endif

#ifndef CY_BOOTLOADER_START_ADDRESS
#define CY_BOOTLOADER_START_ADDRESS             (0x10000000)
#endif

/* External flash map definition. */
static struct flash_area bootloader =
{
    .fa_id = FLASH_AREA_BOOTLOADER,
    .fa_device_id = FLASH_DEVICE_INTERNAL_FLASH,
    .fa_off = CY_BOOTLOADER_START_ADDRESS,
    .fa_size = CY_BOOT_BOOTLOADER_SIZE
};

static struct flash_area primary_1 =
{
    .fa_id = FLASH_AREA_IMAGE_PRIMARY(0),
    .fa_device_id = FLASH_DEVICE_INTERNAL_FLASH,
    .fa_off = CY_FLASH_DEVICE_BASE + \
              CY_BOOT_PRIMARY_1_START,
    .fa_size = CY_BOOT_PRIMARY_1_SIZE
};

static struct flash_area secondary_1 =
{
    .fa_id = FLASH_AREA_IMAGE_SECONDARY(0),
    .fa_device_id = FLASH_DEVICE_EXTERNAL_FLASH(CY_BOOT_EXTERNAL_DEVICE_INDEX),
    .fa_off = CY_FLASH_DEVICE_BASE + \
              CY_BOOT_SECONDARY_1_START,
    .fa_size = CY_BOOT_SECONDARY_1_SIZE
};

static struct flash_area primary_2 =
{
    .fa_id = FLASH_AREA_IMAGE_PRIMARY(1),
    .fa_device_id = FLASH_DEVICE_EXTERNAL_FLASH(CY_BOOT_EXTERNAL_DEVICE_INDEX),
    .fa_off = CY_FLASH_DEVICE_BASE + \
              CY_BOOT_PRIMARY_2_START,
    .fa_size = CY_BOOT_PRIMARY_2_SIZE
};

static struct flash_area secondary_2 =
{
    .fa_id = FLASH_AREA_IMAGE_SECONDARY(1),
    .fa_device_id = FLASH_DEVICE_EXTERNAL_FLASH(CY_BOOT_EXTERNAL_DEVICE_INDEX),
    .fa_off = CY_FLASH_DEVICE_BASE + \
              CY_BOOT_SECONDARY_2_START,
    .fa_size = CY_BOOT_SECONDARY_2_SIZE
};

struct flash_area *boot_area_descs[] =
{
    &bootloader,
    &primary_1,
    &secondary_1,
    &primary_2,
    &secondary_2,
    NULL
};

#else
    #error "CY_FLASH_MAP_EXT_DESC not defined !!"
#endif /* CY_FLASH_MAP_EXT_DESC */
