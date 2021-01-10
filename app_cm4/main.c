/******************************************************************************
* File Name:   main.c
*
* Description:
* This is the source code for CE231678 - AWS IoT and FreeRTOS for PSoC 6 MCU -
* Detaching Wi-Fi blob and Application firmware and performing OTA upgrade.
*
* Related Document: See Readme.md
*
*
*******************************************************************************
* (c) 2020-2021, Cypress Semiconductor Corporation. All rights reserved.
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

/* FreeRTOS includes. */
#include "FreeRTOS.h"

#include "task.h"
#include "flash_qspi.h"
#include "cy_smif_psoc6.h"
#include "cy_serial_flash_qspi.h"
#include "cycfg_qspi_memslot.h"

#ifdef CY_USE_LWIP
#include "lwip/tcpip.h"
#endif

/* BSP & Abstraction includes. */
#include "cybsp.h"
#include "cyhal_gpio.h"
#include "cy_retarget_io.h"

/* Local includes. */
#include "led.h"

/* AWS library includes. */
#include "iot_system_init.h"
#include "iot_logging_task.h"
#include "iot_wifi.h"
#include "iot_network_manager_private.h"
#include "aws_clientcredential.h"
#include "aws_dev_mode_key_provisioning.h"

/* AWS demo include. */
#include "aws_demo.h"

/*******************************************************************************
* Macros
********************************************************************************/
/* Logging Task Defines. */
#define mainLOGGING_MESSAGE_QUEUE_LENGTH    (200)
#define mainLOGGING_TASK_STACK_SIZE         (configMINIMAL_STACK_SIZE * 8)

/* Unit test defines. */
#define mainTEST_RUNNER_TASK_STACK_SIZE     (configMINIMAL_STACK_SIZE * 16)

/* The task delay for allowing the lower priority logging task to print out Wi-Fi
 * failure status before blocking indefinitely. */
#define mainLOGGING_WIFI_STATUS_DELAY       (pdMS_TO_TICKS(1000u))

/* IP Size in bytes. */
#define IPCFG_SIZE_IN_BYTES                 (4)

/* Network connection retry count. */
#define NETWORK_CONN_MAX_RETRY              (5)

/* QSPI bus frequency set to 50MHz. */
#define QSPI_FREQ_IN_HZ                     (50000000lu)

#ifdef BOOT_IMG
    #define LED_TOGGLE_INTERVAL_MS          (pdMS_TO_TICKS(5000u))
#elif defined(UPGRADE_IMG)
    #define LED_TOGGLE_INTERVAL_MS          (pdMS_TO_TICKS(250u))
#else
    #error "[app_cm4]: Please specify type of image: BOOT_IMG or UPGRADE_IMG\n"
#endif

/*******************************************************************************
* Function prototypes
********************************************************************************/
void vApplicationDaemonTaskStartupHook( void );
static void prvMiscInitialization( void );
static void prvWifiConnect(void);
static void prvWifiPowerOn(void);

/*******************************************************************************
* Global variables
********************************************************************************/
extern int uxTopUsedPriority;

/*-----------------------------------------------------------*/

/**
 * @brief Application runtime entry point.
 */
int main( void )
{
    /* Perform any hardware initialization that does not require the RTOS to be
     * running.  */
    prvMiscInitialization();

    /* Create tasks that are not dependent on the Wi-Fi being initialized. */
    xLoggingTaskInitialize( mainLOGGING_TASK_STACK_SIZE,
                            tskIDLE_PRIORITY,
                            mainLOGGING_MESSAGE_QUEUE_LENGTH );

    /* Start the scheduler.  Initialization that requires the OS to be running,
     * including the Wi-Fi initialization, is performed in the RTOS daemon task
     * startup hook. */
    vTaskStartScheduler();

    return 0;
}
/*-----------------------------------------------------------*/

/**
 * @brief Board initialization. LED and UART initialized on
 * bootup.
 */
static void prvMiscInitialization( void )
{
    cy_rslt_t result = cybsp_init();

    if (result != CY_RSLT_SUCCESS)
    {
        configASSERT(0);
    }

    result = cy_retarget_io_init(CYBSP_DEBUG_UART_TX, CYBSP_DEBUG_UART_RX, CY_RETARGET_IO_BAUDRATE);
    if (result != CY_RSLT_SUCCESS)
    {
        configASSERT(0);
    }

    printf( "Retarget IO initialized.\r\n" );

    /* Initialize the User LED. */
    cyhal_gpio_init((cyhal_gpio_t) CYBSP_USER_LED, CYHAL_GPIO_DIR_OUTPUT,
            CYHAL_GPIO_DRIVE_STRONG, CYBSP_LED_STATE_OFF);

    /* Start with clear screen. Printing app details on console. */
    printf("\r\n");
    printf("**Booting to Application.");
    printf("Version: %d.%d.%d ** \r\n \r\n", APP_VERSION_MAJOR, APP_VERSION_MINOR, APP_VERSION_BUILD );

}

/**
 * @brief User defined Application startup hook.
 * All initialization which requires RTOS to be active will go here.
 */
void vApplicationDaemonTaskStartupHook( void )
{
    /* Need to export this var to elf so that debugger can work properly. */
    (void)uxTopUsedPriority;

    /* FIX ME: Perform any hardware initialization, that require the RTOS to be
     * running, here. */

    __enable_irq();

    /* FIX ME: If your MCU is using Wi-Fi, delete surrounding compiler directives to
     * enable the unit tests and after MQTT, Bufferpool, and Secure Sockets libraries
     * have been imported into the project. If you are not using Wi-Fi, see the
     * vApplicationIPNetworkEventHook function. */
    if( SYSTEM_Init() == pdPASS )
    {
#ifdef CY_USE_LWIP
        /* Initialize lwIP stack and spawns tcp_ip thread.
         * This needs the RTOS to be up to be able to start the threads.
         */
        tcpip_init(NULL, NULL);
#endif
    }

    /* Power On Wi-Fi. */
    prvWifiPowerOn();

    /* Initialize the QSPI. */
    if ( psoc6_qspi_init() != 0 )
    {
       printf("psoc6_qspi_init() FAILED !\r\n");
    }

    /* Connect to the Wi-Fi before running the tests. */
    prvWifiConnect();

    /* Provision the device with AWS certificate and private key. */
    vDevModeKeyProvisioning();

    /* Start the demo task. Demo is configure to run MQTT. */
    DEMO_RUNNER_RunDemos();

}
/*-----------------------------------------------------------*/

/**
 * @brief User defined Idle task function.
 *
 * @note Do not make any blocking operations in this function.
 */
void vApplicationIdleHook( void )
{
    /* Toggle the led. */
    toggle_user_led((const uint32_t)LED_TOGGLE_INTERVAL_MS);
}
/*-----------------------------------------------------------*/
/**
 * @brief User defined tick hook function.
 */
void vApplicationTickHook()
{
    /* Do nothing for now ! */
}

/*-----------------------------------------------------------*/
/**
 * @brief User defined assertion call. This function is plugged into configASSERT.
 * See FreeRTOSConfig.h to define configASSERT to something different.
 */
void vAssertCalled(const char * pcFile, uint32_t ulLine)
{
    /* FIX ME. If necessary, update to applicable assertion routine actions. */

    const uint32_t ulLongSleep = 1000UL;
    volatile uint32_t ulBlockVariable = 0UL;
    volatile char * pcFileName = (volatile char *)pcFile;
    volatile uint32_t ulLineNumber = ulLine;

    (void)pcFileName;
    (void)ulLineNumber;

    printf("vAssertCalled %s, %ld\n", pcFile, (long)ulLine);
    fflush(stdout);

    /* Setting ulBlockVariable to a non-zero value in the debugger will allow
    * this function to be exited. */
    taskDISABLE_INTERRUPTS();
    {
        while (ulBlockVariable == 0UL)
        {
            vTaskDelay( pdMS_TO_TICKS( ulLongSleep ) );
        }
    }
    taskENABLE_INTERRUPTS();
}
/*-----------------------------------------------------------*/
/**
 * @brief Turn on Wi-Fi Module
 */
static void prvWifiPowerOn(void)
{
    WIFIReturnCode_t wifi_status = eWiFiSuccess;
    const uint32_t bus_frequency = QSPI_FREQ_IN_HZ ;
    cy_rslt_t result = CY_RSLT_SUCCESS;

    /* Idea of this code example is to place the Wi-Fi firmware blob on QSPi memory
     * and access it during the Init. To do so,we need to have QSPI initialized before
     * Wi-Fi module.
     */
    result = cy_serial_flash_qspi_init (smifMemConfigs [ 0 ], CYBSP_QSPI_D0, CYBSP_QSPI_D1,
                                        CYBSP_QSPI_D2, CYBSP_QSPI_D3, NC, NC, NC, NC,
                                        CYBSP_QSPI_SCK, CYBSP_QSPI_SS, bus_frequency);
    configASSERT(result == CY_RSLT_SUCCESS);

    /* Enable XIP mode. */
    result = cy_serial_flash_qspi_enable_xip ( true );
    configASSERT(result == CY_RSLT_SUCCESS);

    wifi_status = WIFI_On();

    /* Configure QSPI flash back to normal mode. */
    result = cy_serial_flash_qspi_enable_xip ( false );
    configASSERT(result == CY_RSLT_SUCCESS);

    /* QSPI not needed for Wi-Fi module anymore. Releasing the resources acquired. */
    cy_serial_flash_qspi_deinit();

    if (wifi_status != eWiFiSuccess)
    {
        configPRINTF(( "Asserting: Wi-Fi module failed to initialize.\r\n" ));

        /* Delay to allow the lower priority logging task to print the above status.
         * The while loop below will block the above printing. */
        vTaskDelay( mainLOGGING_WIFI_STATUS_DELAY);

        configASSERT(0);
    }

    configPRINTF(( "Wi-Fi module initialized... \r\n" ));

    /* Delay to allow the lower priority logging task to print the above status.
     * The while loop below will block the above printing. */
    vTaskDelay( mainLOGGING_WIFI_STATUS_DELAY);
}
/*-----------------------------------------------------------*/ 
/**
 * @brief Function to connect to AP using the configured parameters
 */
static void prvWifiConnect(void)
{
    WIFINetworkParams_t network_params;
    WIFIReturnCode_t wifi_status;
    uint8_t temp_ip[IPCFG_SIZE_IN_BYTES] = { 0 };
    uint32_t nw_retry_count = 1 ;

    /* Setup parameters. */
    network_params.pcSSID = clientcredentialWIFI_SSID;
    network_params.ucSSIDLength = sizeof( clientcredentialWIFI_SSID) - 1;
    network_params.pcPassword = clientcredentialWIFI_PASSWORD;
    network_params.ucPasswordLength = sizeof( clientcredentialWIFI_PASSWORD) - 1;
    network_params.xSecurity = clientcredentialWIFI_SECURITY;
    network_params.cChannel = 0;

    while ( nw_retry_count < NETWORK_CONN_MAX_RETRY )
    {
        configPRINTF(("Wi-Fi connecting to AP %s.\r\n", network_params.pcSSID));
        wifi_status = WIFI_ConnectAP(&(network_params));

        if (wifi_status == eWiFiSuccess)
        {
            configPRINTF(("Wi-Fi Connected to AP. Creating tasks which use network...\r\n"));

            wifi_status = WIFI_GetIP(temp_ip);

            if (eWiFiSuccess == wifi_status)
            {
                configPRINTF(("IP Address acquired %d.%d.%d.%d\r\n", temp_ip[0], temp_ip[1], temp_ip[2], temp_ip[3]));
            }

            vTaskDelay( mainLOGGING_WIFI_STATUS_DELAY);

            break;
        }
        else
        {
            nw_retry_count++;

            /* Connection failed.  */
            configPRINTF(("Wi-Fi failed to connect to AP %s. (Connection attempt %d)\r\n", network_params.pcSSID, nw_retry_count));

            vTaskDelay( mainLOGGING_WIFI_STATUS_DELAY);

            if(nw_retry_count >= NETWORK_CONN_MAX_RETRY)
            {
                configPRINTF(("Asserting: Wi-Fi connection retry count(%d) exceeded the max limit\r\n",nw_retry_count));

                vTaskDelay( mainLOGGING_WIFI_STATUS_DELAY);

                configASSERT(0);
            }
        }
    }

    configPRINTF(("Wi-Fi configuration successful. \r\n"));

    vTaskDelay( mainLOGGING_WIFI_STATUS_DELAY);
}

/*-----------------------------------------------------------*/
