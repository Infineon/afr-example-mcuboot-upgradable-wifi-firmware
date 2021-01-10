#!/bin/bash
#
# This file is used by make to create the build commands to sign an OTA image
#
# Modify at your peril !
#
# The output files will be in the same directory as the .elf, .hex, etc files
#
(set -o igncr) 2>/dev/null && set -o igncr; # this comment is required
set -e

# Arguments
# We have a lot
#
CY_OUTPUT_PATH=$1
shift
CY_OUTPUT_NAME=$1
shift
CY_ELF_TO_HEX=$1
shift
CY_ELF_TO_HEX_OPTIONS=$1
shift
CY_ELF_TO_HEX_FILE_ORDER=$1
shift
MCUBOOT_SCRIPT_FILE_DIR=$1
shift
IMGTOOL_SCRIPT_NAME=$1
shift
IMGTOOL_COMMAND_ARG=$1
shift
FLASH_ERASE_VALUE=$1
shift
MCUBOOT_HEADER_SIZE=$1
shift
MCUBOOT_MAX_IMG_SECTORS=$1
shift
CY_BUILD_VERSION=$1
shift
CY_BOOT_PRIMARY_1_START=$1
shift
CY_BOOT_PRIMARY_1_SIZE=$1
shift
CY_SIGNING_KEY_ARG=$1
shift
CY_OBJ_COPY=$1
shift
CY_INC_MAIN_APP_IN_TAR=$1
shift
CY_INC_WIFI_BLOB_IN_TAR=$1
shift
CY_INPUT_WIFI_FW_BLOB=$1
shift
CY_OUTPUT_WIFI_BLOB_NAME_BIN=$1
shift
CY_BOOT_PRIMARY_2_SIZE=$1
shift
CY_WIFI_CLM_BLOB=$1
shift
CY_PAD_BYTES=$1
shift
CY_WIFI_FW_BLOB_VERSION=$1

# Export these values for python3 click module
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
    
CY_OUTPUT_BIN=$CY_OUTPUT_PATH/$CY_OUTPUT_NAME.bin
CY_OUTPUT_ELF=$CY_OUTPUT_PATH/$CY_OUTPUT_NAME.elf
CY_OUTPUT_HEX=$CY_OUTPUT_PATH/$CY_OUTPUT_NAME.unsigned.hex
CY_OUTPUT_FILE_NAME_BIN=$CY_OUTPUT_NAME.bin
CY_OUTPUT_FILE_NAME_TAR=$CY_OUTPUT_NAME.tar
CY_OUTPUT_SIGNED_HEX=$CY_OUTPUT_PATH/$CY_OUTPUT_NAME.hex
CY_OUTPUT_FILE_PATH_WILD=$CY_OUTPUT_PATH/$CY_OUTPUT_NAME.*
CY_OUTPUT_WIFI_BLOB_LOC=$CY_OUTPUT_PATH/$CY_OUTPUT_WIFI_BLOB_NAME_BIN
CY_OUTPUT_WIFI_CLM_BLOB_BIN=$CY_WIFI_CLM_BLOB

CY_COMPONENTS_JSON_NAME=components.json

#
# For elf -> hex conversion
#
if [ "$CY_ELF_TO_HEX_FILE_ORDER" == "elf_first" ]
then
    CY_ELF_TO_HEX_FILE_1=$CY_OUTPUT_ELF
    CY_ELF_TO_HEX_FILE_2=$CY_OUTPUT_HEX
else
    CY_ELF_TO_HEX_FILE_1=$CY_OUTPUT_HEX
    CY_ELF_TO_HEX_FILE_2=$CY_OUTPUT_ELF
fi

# For FLASH_ERASE_VALUE
# If value is 0x00, we need to specify "-R 0"
# If value is 0xFF, we do not specify anything!
#
FLASH_ERASE_ARG=
if [ $FLASH_ERASE_VALUE -eq 0 ]
then 
FLASH_ERASE_ARG="-R 0"
fi

# set Python executable based on Host OS
PYTHON_PATH=python3
if [[ "$OS" = "Windows_NT" ]]
then
    PYTHON_PATH=python
fi

# Make a copy of input file.
CY_OUTPUT_WIFI_FW_BLOB_PAD=$CY_OUTPUT_WIFI_BLOB_LOC.input.tmp.bin
cp $CY_INPUT_WIFI_FW_BLOB $CY_OUTPUT_WIFI_FW_BLOB_PAD

# Now, pad the Wi-Fi Fimrware Blob.
dd if=/dev/zero bs=1 count=$CY_PAD_BYTES >> $CY_OUTPUT_WIFI_FW_BLOB_PAD

# Combine CLM & Wi-Fi firmware blobs to a temporary file.
CY_OUTPUT_WIFI_FW_BLOB_TMP=$CY_OUTPUT_WIFI_BLOB_LOC.tmp.bin
cat $CY_OUTPUT_WIFI_FW_BLOB_PAD $CY_OUTPUT_WIFI_CLM_BLOB_BIN > $CY_OUTPUT_WIFI_FW_BLOB_TMP

echo "Create  $CY_OUTPUT_HEX"
"$CY_ELF_TO_HEX" $CY_ELF_TO_HEX_OPTIONS $CY_ELF_TO_HEX_FILE_1 $CY_ELF_TO_HEX_FILE_2

echo  "$IMGTOOL_COMMAND_ARG Hex, creating bin."
cd $MCUBOOT_SCRIPT_FILE_DIR
echo "$IMGTOOL_SCRIPT_NAME $IMGTOOL_COMMAND_ARG $FLASH_ERASE_ARG -e little --pad-header --align 8 -H $MCUBOOT_HEADER_SIZE -M $MCUBOOT_MAX_IMG_SECTORS -v $CY_BUILD_VERSION -L $CY_BOOT_PRIMARY_1_START -S $CY_BOOT_PRIMARY_1_SIZE $CY_SIGNING_KEY_ARG $CY_OUTPUT_HEX $CY_OUTPUT_SIGNED_HEX"
$PYTHON_PATH $IMGTOOL_SCRIPT_NAME $IMGTOOL_COMMAND_ARG $FLASH_ERASE_ARG -e little --pad-header --align 8 -H $MCUBOOT_HEADER_SIZE -M $MCUBOOT_MAX_IMG_SECTORS -v $CY_BUILD_VERSION -L $CY_BOOT_PRIMARY_1_START -S $CY_BOOT_PRIMARY_1_SIZE $CY_SIGNING_KEY_ARG $CY_OUTPUT_HEX $CY_OUTPUT_SIGNED_HEX

# Signing Wi-Fi blob.
echo "$IMGTOOL_SCRIPT_NAME $IMGTOOL_COMMAND_ARG $FLASH_ERASE_ARG -e little --pad-header --align 8 -H $MCUBOOT_HEADER_SIZE -M $MCUBOOT_MAX_IMG_SECTORS -v $CY_WIFI_FW_BLOB_VERSION -S $CY_BOOT_PRIMARY_2_SIZE $CY_SIGNING_KEY_ARG $CY_OUTPUT_WIFI_FW_BLOB_TMP $CY_OUTPUT_WIFI_BLOB_LOC"
$PYTHON_PATH $IMGTOOL_SCRIPT_NAME $IMGTOOL_COMMAND_ARG $FLASH_ERASE_ARG -e little --pad-header --align 8 -H $MCUBOOT_HEADER_SIZE -M $MCUBOOT_MAX_IMG_SECTORS -v $CY_WIFI_FW_BLOB_VERSION -S $CY_BOOT_PRIMARY_2_SIZE $CY_SIGNING_KEY_ARG $CY_OUTPUT_WIFI_FW_BLOB_TMP $CY_OUTPUT_WIFI_BLOB_LOC

# Remove the temp file. 
rm $CY_OUTPUT_WIFI_FW_BLOB_TMP
rm $CY_OUTPUT_WIFI_FW_BLOB_PAD

# back to our build directory
cd $CY_OUTPUT_PATH

#
# Convert signed hex file to Binary for AWS uploading
"$CY_OBJ_COPY" --input-target=ihex --output-target=binary $CY_OUTPUT_SIGNED_HEX $CY_OUTPUT_BIN

echo  " Done."

# get size of binary files for components.json
if [[ $CY_INC_MAIN_APP_IN_TAR -eq 1 ]]
then
    BIN_SIZE=$(ls -g -o $CY_OUTPUT_BIN | awk '{printf $3}')
fi

if [[ $CY_INC_WIFI_BLOB_IN_TAR -eq 1 ]]
then
    WIFI_BLOB_BIN_SIZE=$(ls -g -o $CY_OUTPUT_WIFI_BLOB_NAME_BIN | awk '{printf $3}')
fi

# Create component .json.
# Note: we don't create a tar file when none of the following conditions are met.
if [[ $CY_INC_MAIN_APP_IN_TAR -eq 1 ]] && [[ $CY_INC_WIFI_BLOB_IN_TAR -eq 1 ]]
then
    echo "{\"numberOfComponents\":\"3\",\"version\":\"$CY_BUILD_VERSION\",\"files\":["                                    >  $CY_COMPONENTS_JSON_NAME
    echo "{\"fileName\":\"components.json\",\"fileType\": \"component_list\"},"                                           >> $CY_COMPONENTS_JSON_NAME
    echo "{\"fileName\":\"$CY_OUTPUT_FILE_NAME_BIN\",\"fileType\": \"NSPE\",\"fileSize\":\"$BIN_SIZE\"},"                 >> $CY_COMPONENTS_JSON_NAME
    echo "{\"fileName\":\"$CY_OUTPUT_WIFI_BLOB_NAME_BIN\",\"fileType\": \"SPE\",\"fileSize\":\"$WIFI_BLOB_BIN_SIZE\"}]}"  >> $CY_COMPONENTS_JSON_NAME
    tar -cvf $CY_OUTPUT_FILE_NAME_TAR $CY_COMPONENTS_JSON_NAME $CY_OUTPUT_FILE_NAME_BIN $CY_OUTPUT_WIFI_BLOB_NAME_BIN
elif [[ $CY_INC_MAIN_APP_IN_TAR -eq 1 ]] && [[ $CY_INC_WIFI_BLOB_IN_TAR -eq 0 ]]
then
    echo "{\"numberOfComponents\":\"2\",\"version\":\"$CY_BUILD_VERSION\",\"files\":["                                    >  $CY_COMPONENTS_JSON_NAME
    echo "{\"fileName\":\"components.json\",\"fileType\": \"component_list\"},"                                           >> $CY_COMPONENTS_JSON_NAME
    echo "{\"fileName\":\"$CY_OUTPUT_FILE_NAME_BIN\",\"fileType\": \"NSPE\",\"fileSize\":\"$BIN_SIZE\"}]}"                >> $CY_COMPONENTS_JSON_NAME
    tar -cvf $CY_OUTPUT_FILE_NAME_TAR $CY_COMPONENTS_JSON_NAME $CY_OUTPUT_FILE_NAME_BIN
fi

echo "Application binaries                     : $CY_OUTPUT_FILE_NAME_BIN"
echo "                                         : $CY_OUTPUT_WIFI_BLOB_NAME_BIN"
echo "Primary 1 Slot Start                     : $CY_BOOT_PRIMARY_1_START"
echo "Primary 1 Slot Size                      : $CY_BOOT_PRIMARY_1_SIZE"
echo "Primary 2 Slot Size                      : $CY_BOOT_PRIMARY_2_SIZE"
echo "FLASH ERASE Value (NOTE: Empty for 0xff) : $FLASH_ERASE_VALUE"
echo "Cypress MCUBoot Header size              : $MCUBOOT_HEADER_SIZE"
echo "Max 512 bytes sectors for Application    : $MCUBOOT_MAX_IMG_SECTORS"
if [ "$SIGNING_KEY_PATH" != "" ]
then
    echo "Signing key: $SIGNING_KEY_PATH"
fi
echo ""

#
ls -l $CY_OUTPUT_FILE_PATH_WILD
ls -l $CY_OUTPUT_WIFI_BLOB_LOC
echo ""

if [[ $CY_INC_MAIN_APP_IN_TAR == 1 ]]
then
    echo "$CY_OUTPUT_FILE_NAME_TAR File List"
    # print tar file list
    tar -t -f $CY_OUTPUT_FILE_NAME_TAR
fi

echo ""
