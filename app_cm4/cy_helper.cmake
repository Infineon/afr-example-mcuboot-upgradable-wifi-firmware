# -------------------------------------------------------------------------------------------------
# For OTA_SUPPORT, we need to sign the Hex output for use with cy_mcuboot
# This is used in a POST BUILD Step (see bottom of function(cy_kit_generate) )
# -------------------------------------------------------------------------------------------------
# These can be defined before calling to over-ride
#      - define in <application>/CMakeLists.txt )
#
#   CMake Variable                  Default
#   --------------                  -------
# IMGTOOL_SCRIPT_NAME       "./imgtool.py"
# MCUBOOT_SCRIPT_FILE_DIR   "${cy_port_support_dir}/ota/scripts"
# MCUBOOT_KEY_DIR           "${cy_port_support_dir}/ota/mcuboot/keys"
# MCUBOOT_KEY_FILE          "cypress-test-ec-p256.pem"
#
function(config_cy_mcuboot_create_script)
    # Python script for the image signing

    # signing scripts and keys from MCUBoot
    if((NOT IMGTOOL_SCRIPT_NAME) OR ("${IMGTOOL_SCRIPT_NAME}" STREQUAL ""))
        set(IMGTOOL_SCRIPT_NAME     "./imgtool.py")
    endif()
    if((NOT MCUBOOT_SCRIPT_FILE_DIR) OR ("${MCUBOOT_SCRIPT_FILE_DIR}" STREQUAL ""))
        set(MCUBOOT_SCRIPT_FILE_DIR     "${cy_port_support_dir}/ota/scripts")
    endif()
    if((NOT MCUBOOT_KEY_DIR) OR ("${MCUBOOT_KEY_DIR}" STREQUAL ""))
        set(MCUBOOT_KEY_DIR             "${cy_port_support_dir}/ota/mcuboot/keys")
    endif()
    if((NOT MCUBOOT_KEY_FILE) OR ("${MCUBOOT_KEY_FILE}" STREQUAL ""))
        set(MCUBOOT_KEY_FILE  "cypress-test-ec-p256.pem")
    endif()
    if((NOT CLM_BLOB_CRETAE_SCRIPT) OR ("${CLM_BLOB_CRETAE_SCRIPT}" STREQUAL ""))
        set(CLM_BLOB_CRETAE_SCRIPT     "${CMAKE_SOURCE_DIR}/script/src_to_bin.py")
    endif()

    set(IMGTOOL_SCRIPT_PATH     "${MCUBOOT_SCRIPT_FILE_DIR}/imgtool.py")

    # cy_mcuboot key file
    set(SIGNING_KEY_PATH         "${MCUBOOT_KEY_DIR}/${MCUBOOT_KEY_FILE}")

    # Is flash erase value defined ?
    # NOTE: For usage in imgtool.py, no value defaults to an erase value of 0xff
    # NOTE: Default for internal FLASH is 0x00
    if((NOT $ENV{CY_FLASH_ERASE_VALUE}) OR ("${CY_FLASH_ERASE_VALUE}" STREQUAL "0") OR ("${CY_FLASH_ERASE_VALUE}" STREQUAL "0x00"))
        set(FLASH_ERASE_VALUE "-R 0")
    else()
        set(FLASH_ERASE_VALUE "")
    endif()

    # Slot Start
    if(NOT $ENV{CY_BOOT_PRIMARY_1_START})
        message(FATAL_ERROR "You must define CY_BOOT_PRIMARY_1_START in your board CMakeLists.txt for OTA_SUPPORT")
    endif()

    if(NOT $ENV{CY_BOOT_PRIMARY_1_SIZE})
        message(FATAL_ERROR "You must define CY_BOOT_PRIMARY_1_SIZE in your board CMakeLists.txt for OTA_SUPPORT")
    endif()

    if(NOT $ENV{CY_BOOT_SECONDARY_1_START})
        message(FATAL_ERROR "You must define CY_BOOT_SECONDARY_1_START in your board CMakeLists.txt for OTA_SUPPORT")
    endif()

    if(NOT $ENV{CY_BOOT_SECONDARY_1_SIZE})
        message(FATAL_ERROR "You must define CY_BOOT_SECONDARY_1_SIZE in your board CMakeLists.txt for OTA_SUPPORT")
    endif()
    
    if(NOT $ENV{CY_BOOT_PRIMARY_2_START})
        message(FATAL_ERROR "You must define CY_BOOT_PRIMARY_2_START in your board CMakeLists.txt for OTA_SUPPORT")
    endif()

    if(NOT $ENV{CY_BOOT_PRIMARY_2_SIZE})
        message(FATAL_ERROR "You must define CY_BOOT_PRIMARY_2_SIZE in your board CMakeLists.txt for OTA_SUPPORT")
    endif()

    if(NOT $ENV{CY_BOOT_SECONDARY_2_START})
        message(FATAL_ERROR "You must define CY_BOOT_SECONDARY_2_START in your board CMakeLists.txt for OTA_SUPPORT")
    endif()

    if(NOT $ENV{CY_BOOT_SECONDARY_2_SIZE})
        message(FATAL_ERROR "You must define CY_BOOT_SECONDARY_2_SIZE in your board CMakeLists.txt for OTA_SUPPORT")
    endif()
    
    if(NOT $ENV{MCUBOOT_HEADER_SIZE})
        message(FATAL_ERROR "You must define MCUBOOT_HEADER_SIZE in your board CMakeLists.txt for OTA_SUPPORT")
    endif()

    if(NOT $ENV{MCUBOOT_MAX_IMG_SECTORS})
        message(FATAL_ERROR "You must define MCUBOOT_MAX_IMG_SECTORS in your board CMakeLists.txt for OTA_SUPPORT")
    endif()

        if ( ("${APP_VERSION_MAJOR}" STREQUAL "") OR
             ("${APP_VERSION_MINOR}" STREQUAL "") OR
             ("${APP_VERSION_BUILD}" STREQUAL "") )
            message(FATAL_ERROR "Define version in application make file")
        else()
            add_definitions(-DAPP_VERSION_MAJOR=${APP_VERSION_MAJOR})
            add_definitions(-DAPP_VERSION_MINOR=${APP_VERSION_MINOR})
            add_definitions(-DAPP_VERSION_BUILD=${APP_VERSION_BUILD})
            set(CY_BUILD_VERSION "${APP_VERSION_MAJOR}.${APP_VERSION_MINOR}.${APP_VERSION_BUILD}")

            # The tarball supports only a single version number. 
            # If both Wi-Fi blob and app are included together in the taball, 
            # version of both of these must be same.
            # Override the wi-fi blob version with app version here to enforce
            # above requirement.
            # TODO: Decouple CY_WIFI_FW_BLOB_VERSION from App version in future, 
            # when AFRSDK adds the support.
            set(CY_WIFI_FW_BLOB_VERSION "${APP_VERSION_MAJOR}.${APP_VERSION_MINOR}.${APP_VERSION_BUILD}")
        endif()

    # set env variables as local for the configure_file() call
    set(CY_ELF_TO_HEX "$ENV{CY_ELF_TO_HEX}")
    set(CY_ELF_TO_HEX_OPTIONS "$ENV{CY_ELF_TO_HEX_OPTIONS}")
    if("$ENV{CY_ELF_TO_HEX_FILE_ORDER}" STREQUAL "elf_first")
        set(CY_ELF_TO_HEX_FILE_1 "${CY_OUTPUT_FILE_PATH_ELF}")
        set(CY_ELF_TO_HEX_FILE_2 "${CY_OUTPUT_FILE_PATH_UNSIGNED_HEX}")
    else()
        set(CY_ELF_TO_HEX_FILE_1 "${CY_OUTPUT_FILE_PATH_UNSIGNED_HEX}")
        set(CY_ELF_TO_HEX_FILE_2 "${CY_OUTPUT_FILE_PATH_ELF}")
    endif()

    # If PSoC 062 board, use "create" instead of "sign"; do not pass in CY_SIGNING_KEY_ARG
    # MCUBoot must also be modified to skip checking the signature
    #   Comment out and re-build MCUBootApp
    #   <mcuboot>/boot/cypress/MCUBootApp/config/mcuboot_config/mcuboot_config.h
    #   line 37, 38, 77
    # 37: //#define MCUBOOT_SIGN_EC256
    # 38: //#define NUM_ECC_BYTES (256 / 8)   // P-256 curve size in bytes, rnok: to make compilable
    # 77: //#define MCUBOOT_VALIDATE_PRIMARY_SLOT
    if("${CY_BOOT_SECURE_BOOT}" STREQUAL "sign")
        set(IMGTOOL_SCRIPT_COMMAND "sign")
        set(CY_SIGNING_KEY_ARG   "-k ${SIGNING_KEY_PATH}")
    else()
        set(IMGTOOL_SCRIPT_COMMAND "create")
        set(CY_SIGNING_KEY_ARG   " ")
        set(SIGNING_KEY_PATH     "")
    endif()

    # set these ENV vars locally for configure_file
    set(AFR_TARGET_APP_NAME ${ARG_EXE_APP_NAME})
    set(MCUBOOT_HEADER_SIZE $ENV{MCUBOOT_HEADER_SIZE})
    set(MCUBOOT_MAX_IMG_SECTORS $ENV{MCUBOOT_MAX_IMG_SECTORS})
    set(CY_BOOT_PRIMARY_1_START $ENV{CY_BOOT_PRIMARY_1_START})
    set(CY_BOOT_PRIMARY_1_SIZE $ENV{CY_BOOT_PRIMARY_1_SIZE})
    set(CY_BOOT_PRIMARY_2_START $ENV{CY_BOOT_PRIMARY_2_START})
    set(CY_BOOT_PRIMARY_2_SIZE $ENV{CY_BOOT_PRIMARY_2_SIZE})
    set(CY_BOOT_SECONDARY_1_START $ENV{CY_BOOT_SECONDARY_1_START})
    set(CY_BOOT_SECONDARY_2_START $ENV{CY_BOOT_SECONDARY_2_START})
    set(CY_APP_DIRECTORY ${CMAKE_SOURCE_DIR})
    configure_file("${CMAKE_SOURCE_DIR}/script/sign_script.sh.in" "${SIGN_SCRIPT_FILE_PATH}" @ONLY NEWLINE_STYLE LF)

endfunction(config_cy_mcuboot_create_script)

function(cy_create_images)
    cmake_parse_arguments(
    PARSE_ARGV 0
    "ARG"
    ""
    "EXE_APP_NAME"
    ""
    )
    if(NOT(CY_TFM_PSA_SUPPORTED) AND OTA_SUPPORT)
        # non-TFM signing
        #------------------------------------------------------------
        # Create our script filename in this scope
        set(SIGN_SCRIPT_FILE_NAME             "sign_${ARG_EXE_APP_NAME}.sh")
        set(SIGN_SCRIPT_FILE_PATH             "${CMAKE_BINARY_DIR}/${SIGN_SCRIPT_FILE_NAME}")
        set(SIGN_SCRIPT_FILE_PATH_TMP         "${CMAKE_BINARY_DIR}/tmp/${SIGN_SCRIPT_FILE_NAME}")
        set(CY_OUTPUT_FILE_PATH               "${CMAKE_BINARY_DIR}/${ARG_EXE_APP_NAME}")
        set(CY_OUTPUT_FILE_PATH_ELF           "${CY_OUTPUT_FILE_PATH}.elf")
        set(CY_OUTPUT_FILE_PATH_HEX           "${CY_OUTPUT_FILE_PATH}.hex")
        set(CY_OUTPUT_FILE_NAME_UNSIGNED_HEX  "${ARG_EXE_APP_NAME}.unsigned.hex")
        set(CY_OUTPUT_FILE_PATH_UNSIGNED_HEX  "${CY_OUTPUT_FILE_PATH}.unsigned.hex")
        set(CY_OUTPUT_FILE_NAME_BIN           "${ARG_EXE_APP_NAME}.bin")
        set(CY_OUTPUT_FILE_PATH_BIN           "${CY_OUTPUT_FILE_PATH}.bin")
        set(CY_OUTPUT_FILE_PATH_TAR           "${CY_OUTPUT_FILE_PATH}.tar")
        set(CY_OUTPUT_FILE_PATH_WILD          "${CY_OUTPUT_FILE_PATH}.*")
        set(CY_COMPONENTS_JSON_NAME           "components.json")
        set(CY_OUTPUT_FILE_NAME_TAR           "${ARG_EXE_APP_NAME}.tar")
        set(CY_WIFI_BLOB_OUT_PATH             "${CMAKE_BINARY_DIR}/${CY_WIFI_BLOB_NAME_BIN}")

        # We can use objcopy for .hex to .bin for all toolchains
        find_program(GCC_OBJCOPY arm-none-eabi-objcopy HINT "${AFR_TOOLCHAIN_PATH}")
        if(NOT GCC_OBJCOPY )
            message(FATAL_ERROR "Cannot find arm-none-eabi-objcopy.")
        endif()

        if("${AFR_TOOLCHAIN}" STREQUAL "arm-gcc")
            # Generate HEX file
            add_custom_command(
                TARGET "${ARG_EXE_APP_NAME}" POST_BUILD
                COMMAND "${GCC_OBJCOPY}" -O ihex "${CMAKE_BINARY_DIR}/${ARG_EXE_APP_NAME}.elf" "${CMAKE_BINARY_DIR}/${CY_OUTPUT_FILE_NAME_UNSIGNED_HEX}"
            )
        else ()
            message(FATAL_ERROR "Toolchain ${AFR_TOOLCHAIN} is not supported ")
        endif()

        # creates the script to call imgtool.py to sign the image
        config_cy_mcuboot_create_script("${CMAKE_BINARY_DIR}")

        add_custom_command(
            TARGET "${ARG_EXE_APP_NAME}" POST_BUILD
            WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
            COMMAND "bash" "${SIGN_SCRIPT_FILE_PATH}"
        )
    endif()
endfunction(cy_create_images)

function(cy_custom_config_ota_exe_target)
    cmake_parse_arguments(
    PARSE_ARGV 0
    "ARG"
    ""
    "EXE_APP_NAME"
    ""
    )

    if ("$ENV{MCUBOOT_IMAGE_NUMBER}" STREQUAL "")
        message(FATAL_ERROR "MCUBOOT_IMAGE_NUMBER must be defined.")
    endif()

    # Add OTA defines
    target_compile_definitions(${ARG_EXE_APP_NAME} PUBLIC
        "-DOTA_SUPPORT=1"
        "-DMCUBOOT_KEY_FILE=${MCUBOOT_KEY_FILE}"
        "-DCY_FLASH_ERASE_VALUE=$ENV{CY_FLASH_ERASE_VALUE}"
        "-DMCUBOOT_HEADER_SIZE=$ENV{MCUBOOT_HEADER_SIZE}"
        "-DMCUBOOT_MAX_IMG_SECTORS=$ENV{MCUBOOT_MAX_IMG_SECTORS}"
        "-DMCUBOOT_IMAGE_NUMBER=$ENV{MCUBOOT_IMAGE_NUMBER}"
        "-DCY_BOOT_SCRATCH_SIZE=$ENV{CY_BOOT_SCRATCH_SIZE}"
        "-DCY_BOOT_BOOTLOADER_SIZE=$ENV{MCUBOOT_BOOTLOADER_SIZE}"
        "-DMCUBOOT_BOOTLOADER_SIZE=$ENV{MCUBOOT_BOOTLOADER_SIZE}"
        "-DCY_BOOT_PRIMARY_1_START=$ENV{CY_BOOT_PRIMARY_1_START}"
        "-DCY_BOOT_PRIMARY_1_SIZE=$ENV{CY_BOOT_PRIMARY_1_SIZE}"
        "-DCY_BOOT_SECONDARY_1_SIZE=$ENV{CY_BOOT_PRIMARY_1_SIZE}"
        "-DCY_RETARGET_IO_CONVERT_LF_TO_CRLF=1"
        "-DCY_BOOT_SECONDARY_1_START=$ENV{CY_BOOT_SECONDARY_1_START}"
        )

    # is CY_BOOT_USE_EXTERNAL_FLASH supported?
    if(("${CY_BOOT_USE_EXTERNAL_FLASH}" STREQUAL "1" ) OR ("$ENV{CY_BOOT_USE_EXTERNAL_FLASH}" STREQUAL "1"))
        target_compile_definitions(${ARG_EXE_APP_NAME} PUBLIC "-DCY_BOOT_USE_EXTERNAL_FLASH=$ENV{CY_BOOT_USE_EXTERNAL_FLASH}" )
    endif()

    # Multi-image mcuboot macro definition. 
    if("$ENV{MCUBOOT_IMAGE_NUMBER}" STREQUAL "2" )
        target_compile_definitions(${ARG_EXE_APP_NAME} PUBLIC
            "-DCY_BOOT_PRIMARY_2_START=$ENV{CY_BOOT_PRIMARY_2_START}"
            "-DCY_BOOT_PRIMARY_2_SIZE=$ENV{CY_BOOT_PRIMARY_2_SIZE}"
            "-DCY_BOOT_SECONDARY_2_SIZE=$ENV{CY_BOOT_PRIMARY_2_SIZE}"
            "-DCY_BOOT_SECONDARY_2_START=$ENV{CY_BOOT_SECONDARY_2_START}"
        )
    endif()
    #----------------------------------------------------------------
    # Add Linker options
    #
    if($ENV{MCUBOOT_HEADER_SIZE})
        if ("${AFR_TOOLCHAIN}" STREQUAL "arm-gcc")
            target_link_options(${ARG_EXE_APP_NAME} PUBLIC "-Wl,--defsym,MCUBOOT_HEADER_SIZE=$ENV{MCUBOOT_HEADER_SIZE}")
        elseif("${AFR_TOOLCHAIN}" STREQUAL "arm-armclang")
            target_link_options(${ARG_EXE_APP_NAME} PUBLIC "--pd=\"-DMCUBOOT_HEADER_SIZE=$ENV{MCUBOOT_HEADER_SIZE}\"")
        elseif("${AFR_TOOLCHAIN}" STREQUAL "arm-iar")
            target_link_options(${ARG_EXE_APP_NAME} PUBLIC "SHELL:--config_def MCUBOOT_HEADER_SIZE=$ENV{MCUBOOT_HEADER_SIZE}")
        endif()
    endif()
    if($ENV{MCUBOOT_BOOTLOADER_SIZE})
        if ("${AFR_TOOLCHAIN}" STREQUAL "arm-gcc")
            target_link_options(${ARG_EXE_APP_NAME} PUBLIC "-Wl,--defsym,MCUBOOT_BOOTLOADER_SIZE=$ENV{MCUBOOT_BOOTLOADER_SIZE}")
        elseif("${AFR_TOOLCHAIN}" STREQUAL "arm-armclang")
            target_link_options(${ARG_EXE_APP_NAME} PUBLIC "--pd=\"-DMCUBOOT_BOOTLOADER_SIZE=$ENV{MCUBOOT_BOOTLOADER_SIZE}\"")
        elseif("${AFR_TOOLCHAIN}" STREQUAL "arm-iar")
            target_link_options(${ARG_EXE_APP_NAME} PUBLIC "SHELL: --config_def MCUBOOT_BOOTLOADER_SIZE=$ENV{MCUBOOT_BOOTLOADER_SIZE}")
        endif()
    endif()
    if($ENV{CY_BOOT_PRIMARY_1_SIZE})
        if ("${AFR_TOOLCHAIN}" STREQUAL "arm-gcc")
            target_link_options(${ARG_EXE_APP_NAME} PUBLIC "-Wl,--defsym,CY_BOOT_PRIMARY_1_SIZE=$ENV{CY_BOOT_PRIMARY_1_SIZE}")
        elseif("${AFR_TOOLCHAIN}" STREQUAL "arm-armclang")
            target_link_options(${ARG_EXE_APP_NAME} PUBLIC "--pd=\"-DCY_BOOT_PRIMARY_1_SIZE=$ENV{CY_BOOT_PRIMARY_1_SIZE}\"")
        elseif("${AFR_TOOLCHAIN}" STREQUAL "arm-iar")
            target_link_options(${ARG_EXE_APP_NAME} PUBLIC "SHELL: --config_def CY_BOOT_PRIMARY_1_SIZE=$ENV{CY_BOOT_PRIMARY_1_SIZE}")
        endif()
    endif()
endfunction(cy_custom_config_ota_exe_target)