#-------------------------------------------------------------------------------
# To build, run the following commands in current directory:
# cmake -DVENDOR=cypress -DBOARD=CY8CPROTO_062_4343W -DCOMPILER=arm-gcc -S . -B ../../../../build/<boot or upgrade> -G Ninja -DCMAKE_TOOLCHAIN_FILE=../../../../tools/cmake/toolchains/arm-gcc.cmake
# cmake --build ../../../../build/<boot or upgrade>
#-------------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.13)

# Configure compiler assembler for code outside amazon-freertos source tree.
enable_language(C)
enable_language(ASM)

set(afr_app_name "app_cm4")

project(${afr_app_name})

set(AFR_PATH "${CMAKE_SOURCE_DIR}/../../../..")
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
set(OTA_SUPPORT "1")

#-------------------------------------------------------------------------------
# Convert from "_" to "-" in the target board name in order to be compatible 
# with GNU Make based approach.
#-------------------------------------------------------------------------------
string(REPLACE "_" "-" APP_BOARD_NAME "${BOARD}")

#-------------------------------------------------------------------------------
# Get the application directory path.
#-------------------------------------------------------------------------------
get_filename_component(CY_APP_DIR "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
set(AFR_BOARD "${VENDOR}.${BOARD}" CACHE INTERNAL "")
set(AFR_TOOLCHAIN "${COMPILER}" CACHE INTERNAL "")
#-------------------------------------------------------------------------------
# Configure include for freertos config files, aws config files, and cypress
# psoc6_core header files before add_subdirectory.
#-------------------------------------------------------------------------------
set(BOARD_DEMO_DIR "${AFR_PATH}/vendors/cypress/boards/${BOARD}/aws_demos")
set(BOARD_CY_CODE_DIR "${BOARD_DEMO_DIR}/application_code/cy_code")

#-------------------------------------------------------------------------------
# Takes custom design files if it's defined. Uncomment the following lines to 
# take custom BSP design files. Make sure that the path to custom BSP design
# files are provided in CY_APP_DESIGN_MODUS_DIR.
#-------------------------------------------------------------------------------
# option(CUSTOM_DESIGN_MODUS "Use custom design configuration.")
# add_definitions( -DCUSTOM_DESIGN_MODUS )
# set(CY_APP_DESIGN_MODUS_DIR "${CY_APP_DIR}/COMPONENT_CUSTOM_DESIGN_MODUS/TARGET_${APP_BOARD_NAME}/GeneratedSource" )
#-------------------------------------------------------------------------------
# External FLASH Defaults to ON
#
# FLASH layout is handled in vendors/cypress/<board>/CMakeLists.txt
# as it is common between all apps using external FLASH on a specific board.
set(ENV{OTA_USE_EXTERNAL_FLASH}     "1")

# Add external flash map description to override the default memory layout.
if ($ENV{OTA_USE_EXTERNAL_FLASH} STREQUAL "1")
    add_definitions(-DCY_FLASH_MAP_EXT_DESC)
endif()

# With OTA enabled, OTA_USE_EXTERNAL_FLASH must be set to "1" for this code example.
if ("${OTA_SUPPORT}" STREQUAL "1")
    if (NOT $ENV{OTA_USE_EXTERNAL_FLASH} STREQUAL "1")
        message(FATAL_ERROR "OTA_USE_EXTERNAL_FLASH must be set to 1")
    endif()
endif()
#-------------------------------------------------------------------------------
# Define application memory map conjunction with MCUboot.  
#-------------------------------------------------------------------------------
# Define environment configurations.
set(ENV{MCUBOOT_HEADER_SIZE}         "0x400")           # Must be a multiple of 1024
set(ENV{MCUBOOT_MAX_IMG_SECTORS}     "3584")            # Max. image sectors supported.
set(ENV{MCUBOOT_IMAGE_NUMBER}        "2")               # 2 images (primary_1 and primary_2).
set(ENV{CY_BOOT_SCRATCH_SIZE}        "0x00001000" )     # Scratch pad size.
set(ENV{CY_BOOT_BOOTLOADER_SIZE}     "0x000018000" )    # Size of the bootloader.
set(ENV{CY_BOOT_PRIMARY_1_START}     "0x000018000" )    # Offset of primary_1, starting from base address of internal flash. 
set(ENV{CY_BOOT_SECONDARY_1_START}   "0x8000000" )      # Start of secondary_1, aligned to starting address of external flash. 
set(ENV{CY_BOOT_PRIMARY_1_SIZE}      "0x1C0000" )       # Size of primary_1 slot.
set(ENV{CY_BOOT_SECONDARY_1_SIZE}    "0x1C0000" )       # Size of secondary_1 slot.
set(ENV{CY_BOOT_PRIMARY_2_START}     "0x81C0000" )      # Start offset of primary_2 slot. 
set(ENV{CY_BOOT_SECONDARY_2_START}   "0x8240000" )      # Start offset of secondary_2 slot. 
set(ENV{CY_BOOT_PRIMARY_2_SIZE}      "0x80000" )        # Size of primary_2 slot.
set(ENV{CY_BOOT_SECONDARY_2_SIZE}    "0x80000" )        # Size of secondary_2 slot.
#-------------------------------------------------------------------------------
# Set IMG_TYPE as BOOT or UPGRADE to change led blink frequency and default 
# application versions.
#
# You can over-ride from command line when running CMake.
# ex: "export IMG_TYPE=UPGRADE"
#-------------------------------------------------------------------------------
# Set IMG_TYPE to BOOT, if not defined already.
if("$ENV{IMG_TYPE}" STREQUAL "UPGRADE")
    message("IMG_TYPE set to UPGRADE")
    add_definitions( -DUPGRADE_IMG=1 )
    # Set application version. Defaults to V2.0.0.
    set(CY_TEST_APP_VERSION_IN_TAR         "1")
    if (("$ENV{APP_VERSION_MAJOR}" STREQUAL "") OR
        ("$ENV{APP_VERSION_MINOR}" STREQUAL "") OR
        ("$ENV{APP_VERSION_BUILD}" STREQUAL "") )
        set(APP_VERSION_MAJOR   "2")
        set(APP_VERSION_MINOR   "0")
        set(APP_VERSION_BUILD   "0")
    endif()
else()
    message("IMG_TYPE set to BOOT")
    add_definitions( -DBOOT_IMG=1 )
    # Set application version. Defaults to V1.0.0.
    set(ENV{CY_TEST_APP_VERSION_IN_TAR}     "1")
    if (("$ENV{APP_VERSION_MAJOR}" STREQUAL "") OR
        ("$ENV{APP_VERSION_MINOR}" STREQUAL "") OR
        ("$ENV{APP_VERSION_BUILD}" STREQUAL "") )
        set(APP_VERSION_MAJOR   "1")
        set(APP_VERSION_MINOR   "0")
        set(APP_VERSION_BUILD   "0")
    endif()
endif()


#-------------------------------------------------------------------------------
# Define the TAR options, if not defined by the user. 
# Default, include both app and Wi-Fi blob as part of the tarbal.
#-------------------------------------------------------------------------------
set(CY_INC_MAIN_APP_IN_TAR      	"1")

if(NOT DEFINED ENV{TAR_INC_WIFI_BLOB})
    set(CY_INC_WIFI_BLOB_IN_TAR     "1")
else()
	set(CY_INC_WIFI_BLOB_IN_TAR     "$ENV{TAR_INC_WIFI_BLOB}")
endif()
#-------------------------------------------------------------------------------
# CY_INCLUDE_DIRS must be set when building in LIB_MODE.
#-------------------------------------------------------------------------------
set(additional_include_dirs "${BOARD_CY_CODE_DIR}"
                            "${AFR_PATH}/libraries/c_sdk/standard/mqtt/include"
                            "${AFR_PATH}/libraries/c_sdk/standard/https/include"
                            "${CMAKE_SOURCE_DIR}/config_files"
                            "${CMAKE_SOURCE_DIR}/include"
                            "${CMAKE_SOURCE_DIR}/source")

if (DEFINED CUSTOM_DESIGN_MODUS)
    list(APPEND additional_include_dirs "${CY_APP_DESIGN_MODUS_DIR}")
else()
    list(APPEND additional_include_dirs "${BOARD_CY_CODE_DIR}/GeneratedSource")
endif()

if (EXISTS "${BOARD_CY_CODE_DIR}/SDIO_HOST")
    list(APPEND additional_include_dirs "${BOARD_CY_CODE_DIR}/SDIO_HOST")
endif()

set(CY_INCLUDE_DIRS ${additional_include_dirs} CACHE INTERNAL "")

#-------------------------------------------------------------------------------
# Define name and path of Wi-Fi firmware blob and clm blob. 
#-------------------------------------------------------------------------------
# Define component and firmware name.
if("${BOARD}" STREQUAL "CY8CPROTO_062_4343W")
    set(CY_WIFI_BLOB_NAME "4343WA1")
    set(CY_COMPONENT "COMPONENT_4343W")
elseif("${BOARD}" STREQUAL "CY8CKIT_062S2_43012")
    set(CY_WIFI_BLOB_NAME "43012C0")
    set(CY_COMPONENT "COMPONENT_43012")
else()
    message(FATAL_ERROR "BOARD ${BOARD} not supported !")
endif()

# Wi-Fi FW blob name and path definitions.
# CY_INPUT_WIFI_BLOB_LOC     		: Wi-Fi blob and clm source location.
# CY_INPUT_WIFI_FW_BLOB     		: Absolute path of the Wi-Fi FW blob.
# CY_INPUT_WIFI_CLM_BLOB_SRC 		: Absolute path of the Wi-Fi clm source.
# CY_OUTPUT_WIFI_CLM_BLOB_BIN		: Absolute path of the Wi-Fi clm output binary. 
# CY_OUTPUT_WIFI_FW_BLOB     		: Name of the final combined image.
set(CY_INPUT_WIFI_BLOB_LOC          "${AFR_PATH}/vendors/cypress/MTB/libraries/wifi-host-driver/WiFi_Host_Driver/resources/firmware/${CY_COMPONENT}")
set(CY_INPUT_WIFI_FW_BLOB           "${CY_INPUT_WIFI_BLOB_LOC}/${CY_WIFI_BLOB_NAME}.bin")
set(CY_INPUT_WIFI_CLM_BLOB_SRC      "${CY_INPUT_WIFI_BLOB_LOC}/${CY_WIFI_BLOB_NAME}_clm_blob.txt")
set(CY_OUTPUT_WIFI_CLM_BLOB_BIN     "${CMAKE_BINARY_DIR}/${CY_WIFI_BLOB_NAME}_clm_blob.bin")
set(CY_OUTPUT_WIFI_FW_BLOB          "${CMAKE_BINARY_DIR}/${CY_WIFI_BLOB_NAME}.bin")

# Name of the blob with .bin extension. 
set (CY_WIFI_BLOB_NAME_BIN  "${CY_WIFI_BLOB_NAME}.bin")

#-------------------------------------------------------------------------------
# Determine python path based on Host OS.
#-------------------------------------------------------------------------------
set(PYTHON_PATH         "python3")
if( $ENV{OS} MATCHES "Windows_NT" )
    set(PYTHON_PATH     "python")
endif()

#-------------------------------------------------------------------------------
# Removing WHD driver source files, which are not needed for the build. These 
# Wi-Fi blob configurations are included explicitly in source/wifi_fw_cfg.c
# python rename.py --file_dir <path> --in_ext .txt --out_ext .c
#-------------------------------------------------------------------------------
execute_process(COMMAND ${PYTHON_PATH} ${CMAKE_SOURCE_DIR}/script/rename.py
                        --file_dir ${CY_INPUT_WIFI_BLOB_LOC}
                        --in_ext ".c"
                        --out_ext ".txt" )

#-------------------------------------------------------------------------------
# Create the clm bin from source.
#-------------------------------------------------------------------------------
execute_process(COMMAND ${PYTHON_PATH} ${CMAKE_SOURCE_DIR}/script/src_to_bin.py
                        --clm_blob ${CY_INPUT_WIFI_CLM_BLOB_SRC} 
                        --out ${CY_OUTPUT_WIFI_CLM_BLOB_BIN})

# Define firmware alignment bytes.
set(ALIGN_BYTES          "1024")

#-------------------------------------------------------------------------------
# Get size of Wi-Fi firmware blob, clm blob.
#-------------------------------------------------------------------------------
# Wi-Fi firmware blob.
file(SIZE ${CY_INPUT_WIFI_FW_BLOB} blob_size)
math(EXPR fw_blob_size "${blob_size} * 0x1" OUTPUT_FORMAT HEXADECIMAL)
math(EXPR pad_bytes "${ALIGN_BYTES}-(${fw_blob_size}%${ALIGN_BYTES})")
add_definitions( -DCY_WIFI_BLOB_SIZE=${fw_blob_size} )
add_definitions( -DCY_PAD_BYTES=${pad_bytes} )
set(CY_PAD_BYTES			"${pad_bytes}")

# CLM blob.
file(SIZE ${CY_OUTPUT_WIFI_CLM_BLOB_BIN} clm_size)
math(EXPR clm_blob_size "${clm_size} * 0x1" OUTPUT_FORMAT HEXADECIMAL)
add_definitions( -DCY_WIFI_CLM_BLOB_SIZE=${clm_blob_size} )

#-------------------------------------------------------------------------------
# Removing modules that are not needed by the example.
#-------------------------------------------------------------------------------
set(CY_APP_DISABLE_AFR_MODULES
    "defender"
    "greengrass"
    "shadow"
    )

#-------------------------------------------------------------------------------
# Build amazon-freertos as library
#-------------------------------------------------------------------------------
set(LIB_MODE 1)
add_subdirectory(${AFR_PATH} "${AFR_PATH}/Lib")

#-------------------------------------------------------------------------------
# Include .cmake files that contain definitions of functions and variables.
#-------------------------------------------------------------------------------
include("${AFR_PATH}/vendors/cypress/MTB/psoc6/cmake/cy_defines.cmake")
include("${CMAKE_SOURCE_DIR}/cy_helper.cmake")
#-------------------------------------------------------------------------------
# Add board specific files (taken from amazon-freertos/vendors/cypress/boards
# /${BOARD}/aws_demos/application_code/cy_code). Customize as necessary or 
# replace with another cypress board. The code in ${BSP_DIR}/GeneratedSource is
# generated by our configurators when saving ${BSP_DIR}/design.modus.
#-------------------------------------------------------------------------------
cy_find_files(exe_glob_files DIRECTORY "${BOARD_CY_CODE_DIR}")
if (DEFINED CUSTOM_DESIGN_MODUS)
    foreach(item ${exe_glob_files})
        message ("${item}")
        if(${item} MATCHES "GeneratedSource")
            list(REMOVE_ITEM exe_glob_files ${item})
        endif(${item} MATCHES "GeneratedSource")
    endforeach()
endif()
cy_get_src(exe_source_files ITEMS "${exe_glob_files}")

#-------------------------------------------------------------------------------
# add executable target source files.
#-------------------------------------------------------------------------------
add_executable(${afr_app_name} "${CMAKE_SOURCE_DIR}/main.c"
                "${CMAKE_SOURCE_DIR}/source/led.c"
                "${CMAKE_SOURCE_DIR}/source/wifi_fw_cfg.c"
                "${CMAKE_SOURCE_DIR}/source/ext_flash_map.c"
                "${exe_source_files}"
                )

target_include_directories(${afr_app_name} PUBLIC "${CY_INCLUDE_DIRS}")

#-------------------------------------------------------------------------------
# Additional compiler definitions.
#-------------------------------------------------------------------------------
target_compile_definitions(${afr_app_name} PUBLIC
    "-DCY_RETARGET_IO_CONVERT_LF_TO_CRLF"
    )

#-------------------------------------------------------------------------------
# Add linker script and map file generation.
#-------------------------------------------------------------------------------
cy_add_linker_options(EXE_APP_NAME ${afr_app_name})

#-------------------------------------------------------------------------------
# Set up dependent linked libraries.
#-------------------------------------------------------------------------------
target_link_libraries(${afr_app_name}  PUBLIC
    AFR::common
    AFR::utils
    AFR::wifi
    AFR::wifi::mcu_port
    psoc6_core # Pulls in defines, includes, source code for psoc6 devices
    AFR::demo_base
)

#    AFR::dev_mode_key_provisioning
#    AFR::https
#    AFR::ota

#-------------------------------------------------------------------------------
# Configure OTA specific compile definitions.
#-------------------------------------------------------------------------------
cy_custom_config_ota_exe_target(EXE_APP_NAME ${afr_app_name})

#-------------------------------------------------------------------------------
# Configure signing script for generating signed hex and corresponding bin
# files to upload to AWS.
#-------------------------------------------------------------------------------
cy_create_images(EXE_APP_NAME ${afr_app_name})

#END OF FILE.
