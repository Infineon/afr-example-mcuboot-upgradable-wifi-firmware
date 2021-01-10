/******************************************************************************
* File Name:   main.c
*
* Description:
* This is the source code for CE231678. AWS IoT and FreeRTOS for PSoC 6 MCU:
* MCUboot based bootloader with built-in support for up to 2 updateable
* firmware images
*
* Related Document: See README.md
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

/* Standard headers. */
#include <stdio.h>

/* Driver header files. */
#include "cy_pdl.h"
#include "cycfg.h"
#include "cy_result.h"
#include "cy_retarget_io_pdl.h"

#include "cycfg_clocks.h"
#include "cycfg_peripherals.h"
#include "cycfg_pins.h"

/* MCUboot header files. */
#include "bootutil/image.h"
#include "bootutil/bootutil.h"
#include "bootutil/sign_key.h"
#include "bootutil/bootutil_log.h"

/*  Flash access headers. */
#include "flash_map_backend/flash_map_backend.h"
#include "cy_smif_psoc6.h"
#include "sysflash.h"

/*******************************************************************************
* Macros
********************************************************************************/
/* Delay for which CM0+ waits before enabling CM4 so that the messages printed
 * by CM0+ do not go unnoticed by the user since these messages may be
 * overwritten by CM4.
 */
#define CM4_BOOT_DELAY_MS       (100UL)

/* Slave Select line to which the external memory is connected.
 * Acceptable values are:
 * 0 - SMIF disabled (no external memory)
 * 1, 2, 3, or 4 - slave select line to which the memory module is connected.
 */
#define QSPI_SLAVE_SELECT_LINE  (1UL)

/*******************************************************************************
* Function Prototypes
********************************************************************************/
static void do_boot(struct boot_rsp *rsp, char *msg);
static void deinit_hw(void);

/******************************************************************************
 * Function Name: deinit_hw
 ******************************************************************************
 * Summary:
 * This function performs the necessary hardware de-initialization.
 ******************************************************************************/
static void deinit_hw(void)
{
    cy_retarget_io_pdl_deinit();
    Cy_GPIO_Port_Deinit(CYBSP_UART_RX_PORT);
    Cy_GPIO_Port_Deinit(CYBSP_UART_TX_PORT);
    qspi_deinit(QSPI_SLAVE_SELECT_LINE);
}

/******************************************************************************
 * Function Name: do_boot
 ******************************************************************************
 * Summary:
 *  This function extracts the image address and enables CM4 to let it boot
 *  from that address.
 *
 * Parameters:
 *  rsp - Pointer to a structure holding the address to boot from.
 *  msg - String used for intuitive indications to user.
 *
 ******************************************************************************/
static void do_boot(struct boot_rsp *rsp, char *msg)
{
    uint32_t app_addr = (rsp->br_image_off + rsp->br_hdr->ih_hdr_size);

    CY_ASSERT(msg != NULL);

    BOOT_LOG_INF("Starting %s on CM4. Please wait...", msg);

    cy_retarget_io_wait_tx_complete(CYBSP_UART_HW, CM4_BOOT_DELAY_MS);

    deinit_hw();

    Cy_SysEnableCM4(app_addr);
}

/******************************************************************************
 * Function Name: main
 ******************************************************************************
 * Summary:
 *  System entrance point. This function initializes system resources & 
 *  peripherals, retarget IO and user button. Boots to application,
 *  if a valid image is present. Performs the rollback, if requested by the user.
 *
 ******************************************************************************/
int main(void)
{
    struct boot_rsp rsp;
    cy_rslt_t result = CY_RSLT_SUCCESS;

    /* Initialize system resources and peripherals.
     * Do not call init_cycfg_system() as the system clocks and resources will
     * be initialized by CM4.
     */
    init_cycfg_clocks();
    init_cycfg_peripherals();
    init_cycfg_pins();

    /* Initialize retarget-io to redirect the printf output. */
    cy_retarget_io_pdl_init(CY_RETARGET_IO_BAUDRATE);

    /* Enable interrupts. */
    __enable_irq();

    /* Initialize QSPI NOR flash using SFDP. */
    result = qspi_init_sfdp(QSPI_SLAVE_SELECT_LINE);
    if( result == CY_RSLT_SUCCESS)
    {
        BOOT_LOG_INF("External Memory initialization using SFDP mode.");
    }
    else
    {
        BOOT_LOG_ERR("External Memory initialization using SFDP Failed 0x%08x", (int)result);

        /* Critical error: asserting. */
        CY_ASSERT(0);
    }

    /* Perform a pending upgrade (if any) and validate images on primary slot */
    if (boot_go(&rsp) == 0)
    {
        BOOT_LOG_INF("Application validated successfully !");

        /* Boot to application. */
        do_boot(&rsp, "Application");

        while (true)
        {
            Cy_SysPm_CpuEnterDeepSleep(CY_SYSPM_WAIT_FOR_INTERRUPT);
        }
    }
    else
    {
       /* Put MCU in WFI mode when application for CM4 is invalid. */
        while (true)
        {
            __WFI();
        }

    }

    return 0;
}
    
/* [] END OF FILE */
