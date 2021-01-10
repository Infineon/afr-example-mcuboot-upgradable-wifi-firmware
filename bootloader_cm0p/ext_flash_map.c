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
#include "mcuboot_config/mcuboot_config.h"

#ifndef CY_BOOTLOADER_START_ADDRESS
#define CY_BOOTLOADER_START_ADDRESS        (0x10000000)
#endif

#ifdef MCUBOOT_HAVE_ASSERT_H
#include "mcuboot_config/mcuboot_assert.h"
#else
#include <assert.h>
#endif

#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>

#include "bootutil/bootutil_log.h"

#include "cy_pdl.h"

#ifdef CY_BOOT_USE_EXTERNAL_FLASH
#include "cy_smif_psoc6.h"
#endif

/*
 * For now, we only support one flash device.
 *
 * Pick a random device ID for it that's unlikely to collide with
 * anything "real".
 */
#define FLASH_DEVICE_ID                         (111)
#define FLASH_MAP_ENTRY_MAGIC                   (0xd00dbeef)

#define FLASH_AREA_IMAGE_SECTOR_SIZE            (FLASH_AREA_IMAGE_SCRATCH_SIZE)

#ifndef CY_BOOTLOADER_START_ADDRESS
#define CY_BOOTLOADER_START_ADDRESS             (0x10000000)
#endif

#ifndef CY_BOOT_INTERNAL_FLASH_ERASE_VALUE
/* This is the value of internal flash bytes after an erase. */
#define CY_BOOT_INTERNAL_FLASH_ERASE_VALUE      (0x00)
#endif

#ifndef CY_BOOT_EXTERNAL_FLASH_ERASE_VALUE
/* This is the value of external flash bytes after an erase. */
#define CY_BOOT_EXTERNAL_FLASH_ERASE_VALUE      (0xff)
#endif

#ifndef CY_EXTERNAL_FLASH_SECTOR_SIZE
/* Set external flash sector size to 256 KB by default. */
#define CY_EXTERNAL_FLASH_SECTOR_SIZE           (0x40000)
#endif

#if defined(CY_FLASH_MAP_EXT_DESC) 

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

/* Returns device flash start based on supported fa_id */
int flash_device_base(uint8_t fd_id, uintptr_t *ret)
{
    if (fd_id != FLASH_DEVICE_INTERNAL_FLASH) {
        BOOT_LOG_ERR("invalid flash ID %d; expected %d",
                     fd_id, FLASH_DEVICE_INTERNAL_FLASH);
        return -1;
    }
    *ret = CY_FLASH_DEVICE_BASE;
    return 0;
}

/* Opens the area for use. id is one of the `fa_id`s */
int flash_area_open(uint8_t id, const struct flash_area **fa)
{
    int ret = -1;
    uint32_t i = 0;

    while(NULL != boot_area_descs[i])
    {
        if(id == boot_area_descs[i]->fa_id)
        {
            *fa = boot_area_descs[i];
            ret = 0;
            break;
        }
        i++;
    }
    return ret;
}

void flash_area_close(const struct flash_area *fa)
{
    (void)fa;/* Nothing to do there */
}

/*
* Reads `len` bytes of flash memory at `off` to the buffer at `dst`
*/
int flash_area_read(const struct flash_area *fa, uint32_t off, void *dst,
                     uint32_t len)
{
    int rc = 0;
    size_t addr;

    /* check if requested offset not less then flash area (fa) start */
    assert(off < fa->fa_off);
    assert(off + len < fa->fa_off);
    /* convert to absolute address inside a device*/
        addr = fa->fa_off + off;

    if (fa->fa_device_id == FLASH_DEVICE_INTERNAL_FLASH)
    {
        /* flash read by simple memory copying */
        memcpy((void *)dst, (const void*)addr, (size_t)len);
    }
#ifdef CY_BOOT_USE_EXTERNAL_FLASH
    else if ((fa->fa_device_id & FLASH_DEVICE_EXTERNAL_FLAG) == FLASH_DEVICE_EXTERNAL_FLAG)
    {
        rc = psoc6_smif_read(fa, addr, dst, len);
    }
#endif
    else
    {
        /* incorrect/non-existing flash device id */
        rc = -1;
    }

    if (rc != 0) {
        BOOT_LOG_ERR("Flash area read error, rc = %d", (int)rc);
    }
    return rc;
}

/*
* Writes `len` bytes of flash memory at `off` from the buffer at `src`
 */
int flash_area_write(const struct flash_area *fa, uint32_t off,
                     const void *src, uint32_t len)
{
    cy_en_flashdrv_status_t rc = CY_FLASH_DRV_SUCCESS;
    size_t write_start_addr;
    size_t write_end_addr;
    const uint32_t * row_ptr = NULL;

    assert(off < fa->fa_off);
    assert(off + len < fa->fa_off);

    /* convert to absolute address inside a device */
    write_start_addr = fa->fa_off + off;
    write_end_addr = fa->fa_off + off + len;

    if (fa->fa_device_id == FLASH_DEVICE_INTERNAL_FLASH)
    {
        uint32_t row_number = 0;
        uint32_t row_addr = 0;

        assert(!(len % CY_FLASH_SIZEOF_ROW));
        assert(!(write_start_addr % CY_FLASH_SIZEOF_ROW));

        row_number = (write_end_addr - write_start_addr) / CY_FLASH_SIZEOF_ROW;
        row_addr = write_start_addr;

        row_ptr = (uint32_t *) src;

        for (uint32_t i = 0; i < row_number; i++)
        {
            rc = Cy_Flash_WriteRow(row_addr, row_ptr);

            row_addr += (uint32_t) CY_FLASH_SIZEOF_ROW;
            row_ptr = row_ptr + CY_FLASH_SIZEOF_ROW / 4;
        }
    }
#ifdef CY_BOOT_USE_EXTERNAL_FLASH
    else if ((fa->fa_device_id & FLASH_DEVICE_EXTERNAL_FLAG) == FLASH_DEVICE_EXTERNAL_FLAG)
    {
        rc = psoc6_smif_write(fa, write_start_addr, src, len);
    }
#endif
    else
    {
        /* incorrect/non-existing flash device id */
        rc = -1;
    }

    return (int) rc;
}

/*< Erases `len` bytes of flash memory at `off` */
int flash_area_erase(const struct flash_area *fa, uint32_t off, uint32_t len)
{
    cy_en_flashdrv_status_t rc = CY_FLASH_DRV_SUCCESS;
    size_t erase_start_addr;
    size_t erase_end_addr;

    assert(off < fa->fa_off);
    assert(off + len < fa->fa_off);
    assert(!(len % CY_FLASH_SIZEOF_ROW));

    /* convert to absolute address inside a device*/
    erase_start_addr = fa->fa_off + off;
    erase_end_addr = fa->fa_off + off + len;

    if (fa->fa_device_id == FLASH_DEVICE_INTERNAL_FLASH)
    {
        int row_number = 0;
        uint32_t row_addr = 0;

        row_number = (erase_end_addr - erase_start_addr) / CY_FLASH_SIZEOF_ROW;

        while (row_number != 0)
        {
            row_number--;
            row_addr = erase_start_addr + row_number * (uint32_t) CY_FLASH_SIZEOF_ROW;
            rc = Cy_Flash_EraseRow(row_addr);
        }
    }
#ifdef CY_BOOT_USE_EXTERNAL_FLASH
    else if ((fa->fa_device_id & FLASH_DEVICE_EXTERNAL_FLAG) == FLASH_DEVICE_EXTERNAL_FLAG)
    {
        rc = psoc6_smif_erase(erase_start_addr, len);
    }
#endif
    else
    {
        /* incorrect/non-existing flash device id */
        rc = -1;
    }
    return (int) rc;
}

/*< Returns this `flash_area`s alignment */
size_t flash_area_align(const struct flash_area *fa)
{
    int ret = -1;
    if (fa->fa_device_id == FLASH_DEVICE_INTERNAL_FLASH)
    {
        ret = CY_FLASH_ALIGN;
    }
#ifdef CY_BOOT_USE_EXTERNAL_FLASH
    else if ((fa->fa_device_id & FLASH_DEVICE_EXTERNAL_FLAG) == FLASH_DEVICE_EXTERNAL_FLAG)
    {
        return qspi_get_prog_size();
    }
#endif
    else
    {
        /* incorrect/non-existing flash device id */
        ret = -1;
    }
    return ret;
}

#ifdef MCUBOOT_USE_FLASH_AREA_GET_SECTORS
/*< Initializes an array of flash_area elements for the slot's sectors */
int     flash_area_to_sectors(int idx, int *cnt, struct flash_area *fa)
{
    int rc = 0;

    if (fa->fa_device_id == FLASH_DEVICE_INTERNAL_FLASH)
    {
        (void)idx;
        (void)cnt;
        rc = 0;
    }
#ifdef CY_BOOT_USE_EXTERNAL_FLASH
    else if ((fa->fa_device_id & FLASH_DEVICE_EXTERNAL_FLAG) == FLASH_DEVICE_EXTERNAL_FLAG)
    {
        (void)idx;
        (void)cnt;
        rc = 0;
    }
#endif
    else
    {
        /* incorrect/non-existing flash device id */
        rc = -1;
    }
    return rc;
}
#endif

/*
 * This depends on the mappings defined in sysflash.h.
 * MCUBoot uses continuous numbering for the primary slot, the secondary slot,
 * and the scratch while zephyr might number it differently.
 */
int flash_area_id_from_multi_image_slot(int image_index, int slot)
{
    switch (slot) {
    case 0: return FLASH_AREA_IMAGE_PRIMARY(image_index);
    case 1: return FLASH_AREA_IMAGE_SECONDARY(image_index);
    case 2: return FLASH_AREA_IMAGE_SCRATCH;
    }

    return -1; /* flash_area_open will fail on that */
}

int flash_area_id_from_image_slot(int slot)
{
    return flash_area_id_from_multi_image_slot(0, slot);
}

int flash_area_id_to_multi_image_slot(int image_index, int area_id)
{
    if (area_id == FLASH_AREA_IMAGE_PRIMARY(image_index)) {
        return 0;
    }
    if (area_id == FLASH_AREA_IMAGE_SECONDARY(image_index)) {
        return 1;
    }

    return -1;
}

int flash_area_id_to_image_slot(int area_id)
{
    return flash_area_id_to_multi_image_slot(0, area_id);
}

uint8_t flash_area_erased_val(const struct flash_area *fap)
{
    int ret = 0;

    if (fap->fa_device_id == FLASH_DEVICE_INTERNAL_FLASH)
    {
        ret = CY_BOOT_INTERNAL_FLASH_ERASE_VALUE;
    }
#ifdef CY_BOOT_USE_EXTERNAL_FLASH
    else if ((fap->fa_device_id & FLASH_DEVICE_EXTERNAL_FLAG) == FLASH_DEVICE_EXTERNAL_FLAG)
    {
        ret = CY_BOOT_EXTERNAL_FLASH_ERASE_VALUE;
    }
#endif
    else
    {
        assert(false) ;
    }

    return ret ;
}

int flash_area_read_is_empty(const struct flash_area *fa, uint32_t off,
        void *dst, uint32_t len)
{
    uint8_t *mem_dest;
    int rc;

    mem_dest = (uint8_t *)dst;
    rc = flash_area_read(fa, off, dst, len);
    if (rc) {
        return -1;
    }

    for (uint8_t i = 0; i < len; i++) {
        if (mem_dest[i] != flash_area_erased_val(fa)) {
            return 0;
        }
    }
    return 1;
}

#ifdef MCUBOOT_USE_FLASH_AREA_GET_SECTORS
int flash_area_get_sectors(int idx, uint32_t *cnt, struct flash_sector *ret)
{
    int rc = 0;
    uint32_t i = 0;
    struct flash_area *fa = NULL;

    while(NULL != boot_area_descs[i])
    {
        if(idx == boot_area_descs[i]->fa_id)
        {
            fa = boot_area_descs[i];
            break;
        }
        i++;
    }

    if(NULL != boot_area_descs[i])
    {
        size_t sector_size = 0;

        if(fa->fa_device_id == FLASH_DEVICE_INTERNAL_FLASH)
        {
            sector_size = CY_FLASH_SIZEOF_ROW;
        }
#ifdef CY_BOOT_USE_EXTERNAL_FLASH
        else if((fa->fa_device_id & FLASH_DEVICE_EXTERNAL_FLAG) == FLASH_DEVICE_EXTERNAL_FLAG)
        {
            /* Implement for SMIF. */
            sector_size = CY_EXTERNAL_FLASH_SECTOR_SIZE;
        }
#endif
        else
        {
            rc = -1;
        }

        if(0 == rc)
        {
            uint32_t addr = 0;
            size_t sectors_n = 0;

            sectors_n = (fa->fa_size + (sector_size - 1)) / sector_size;
            assert(sectors_n <= *cnt);

            addr = fa->fa_off;
            for(i = 0; i < sectors_n; i++)
            {
                ret[i].fs_size = sector_size ;
                ret[i].fs_off = addr ;
                addr += sector_size ;
            }

            *cnt = sectors_n;
        }
    }
    else
    {
        rc = -1;
    }

    return rc;
}
#endif