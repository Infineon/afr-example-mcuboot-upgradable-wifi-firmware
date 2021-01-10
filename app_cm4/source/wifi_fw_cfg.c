/******************************************************************************
* File Name:   wifi_fw_cfg.c
*
* Description:
* This file defines the Wi-Fi firmware resource structure. Structure points to 
* a defined location on external memory that contains a valid Wi-Fi firmware. 
* Firmware will be loaded on to the Wi-Fi module during every power on.
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

#include "wiced_resource.h"
#include "sysflash.h"
#include "cy_pdl.h"

/* Location of Wi-Fi firmware blob in memory. */
#define CY_WIFI_FW_ADDR             (CY_FLASH_DEVICE_BASE + CY_BOOT_PRIMARY_2_START + MCUBOOT_HEADER_SIZE)

/* Location of Wi-Fi CLM blob in memory.
 * Note: CLM blob should be placed immediate next to Wi-Fi blob..
 */
#define CY_WIFI_CLM_BLOB_ADDR       (CY_WIFI_FW_ADDR + CY_WIFI_BLOB_SIZE + CY_PAD_BYTES)

/* 40 bytes of signature attached by the imgtool. */
#define IMG_SIGN_SZ                 (0x28)

/* Check firmware size limits. */
#if ( (MCUBOOT_HEADER_SIZE + CY_WIFI_BLOB_SIZE + \
       CY_PAD_BYTES + CY_WIFI_CLM_BLOB_SIZE + \
       IMG_SIGN_SZ ) > CY_BOOT_PRIMARY_2_SIZE )
    #error "Size of Wi-Fi blobs exceeds the max allowed limits"
#endif


/*
 * Below section facilitates software to either use Wi-Fi firmware meant for 
 * production or for manufacturing tests based on 'WLAN_MFG_FIRMWARE'.
 * By default, WLAN_MFG_FIRMWARE is not defined and application is built for
 * production firmware. 
 * Please refer vendors/cypress/MTB/libraries/wifi-host-driver/WiFi_Host_Driver/resources/firmware/
 * directory and look for your respective component/module firmware binary & source files 
 * for further details.
 * Below definition uses the following:
 * CY_WIFI_FW_ADDR, derived based on the user configurations. 
 * CY_WIFI_BLOB_SIZE, derived automatically by the build system based on the component/bin file selected
 * Please refer the application Makefile for firmware blob selection.
 */
#ifdef WLAN_MFG_FIRMWARE 
const resource_hnd_t wifi_mfg_firmware_image    = { RESOURCE_IN_MEMORY, CY_WIFI_BLOB_SIZE, {.mem = { (const char *) CY_WIFI_FW_ADDR }}};
const resource_hnd_t wifi_mfg_firmware_clm_blob = { RESOURCE_IN_MEMORY, CY_WIFI_CLM_BLOB_SIZE, {.mem = { (const char *) CY_WIFI_CLM_BLOB_ADDR }}};
#else
const resource_hnd_t wifi_firmware_image    = { RESOURCE_IN_MEMORY, CY_WIFI_BLOB_SIZE, {.mem = { (const char *)CY_WIFI_FW_ADDR }}};
const resource_hnd_t wifi_firmware_clm_blob = { RESOURCE_IN_MEMORY, CY_WIFI_CLM_BLOB_SIZE, {.mem = { (const char *) CY_WIFI_CLM_BLOB_ADDR }}};
#endif
