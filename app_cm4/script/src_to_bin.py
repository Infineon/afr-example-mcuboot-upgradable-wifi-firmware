# (c) 2021, Cypress Semiconductor Corporation. All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#     http://www.apache.org/licenses/LICENSE-2.0
# or in the "license" file accompanying this file. This file is distributed 
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either 
# express or implied. See the License for the specific language governing 
# permissions and limitations under the License.
#

import sys
import argparse
import os
import os.path
from os import path
import re

# Set pre known paths.
KEY="wifi_firmware_clm_blob_image_data"

def main():
    parser = argparse.ArgumentParser(description="Script to convert clm blob from .c source to binary file")

    parser.add_argument("--clm_blob", required=True,metavar="CLM Blob file with absolute path")

    parser.add_argument("--out", required=True,metavar="Output binary file with absolute path")

    # Start arg parser.
    args = parser.parse_args()

    # Absolute path of original Wi-Fi blob.
    INPUT_WIFI_CLM_ARR_ABS=args.clm_blob

    # Absolute path for placing output binaries.
    OUTPUT_CLM_BIN_PATH=args.out

    # Leave it here for debug.
    #print ("***************************************************************")
    #print(args)
    #print(INPUT_WIFI_CLM_ARR_ABS)
    #print(OUTPUT_CLM_BIN_PATH)
    #print ("***************************************************************")

    out_file=open(OUTPUT_CLM_BIN_PATH,"wb")
    
    BIN_ARR_SZ = 0 #Size of the array. 
    if path.exists(INPUT_WIFI_CLM_ARR_ABS) :
        with open(INPUT_WIFI_CLM_ARR_ABS) as src_file:
            # Now process entire fie till the end of the data array.
            process_data = False 
            for line in src_file:
                if KEY in line:     # Find array size and start sequence.
                    BIN_ARR_SZ=re.search("[0-9]{4,9}(?!\d)",line)[0]
                    #print (BIN_ARR_SZ)
                    start_seq=re.search("[=]\s[{]",line)[0]
                    if start_seq is None :
                        print ("Can't find a valid sequence")
                        src_file.close()
                        out_file.close();
                        exit()
                    else :
                        process_data = True
                        continue # Read next line
                if process_data == True :
                    # Is this end of the array ?. Check before data parsing.  
                    end_seq=re.search("[}][;]",line)
                    if end_seq :
                        process_data = False
                        break; # break from loop and free-up the resources.
                    
                    # Data parsing 
                    data_list=re.split(',|, |,\n| |\n',line)
                    new_list = list(filter(None, data_list))
                    for element in new_list :
                        if element == '\n' :
                            break;
                        elif element.isdigit():
                            num=int(element)
                            out_file.write(num.to_bytes(1,'little'))
        # Done with ops.
            src_file.close()
            out_file.close();
    else :
        out_file.close();
        print("Specified path 'INPUT_WIFI_CLM_ARR_ABS' is not valid")
    
    # Leave it here for debug.
    #print ("***************************************************************")
    #print(HEADER_SIZE)
    #print(NUM_SECTORS)
    #print(SLOT_SIZE)
    #print ("***************************************************************")

if __name__ == "__main__":
    main()