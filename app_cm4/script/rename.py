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
from os import path
import re

def main():
    parser = argparse.ArgumentParser(description="Script to rename files in a given directory")
    
    parser.add_argument("--file_dir", required=True,metavar="Path to directory to change all file names")
    parser.add_argument("--in_ext", required=True,metavar="extension or pattern of input files to be renamed")
    parser.add_argument("--out_ext", required=True,metavar="extension or patter to rename")

    # Start arg parser.
    args = parser.parse_args()
    
    if path.exists(args.file_dir) :
        for index, filename in enumerate(os.listdir(args.file_dir)):
            name = os.path.splitext(filename)[0]
            ext = os.path.splitext(filename)[-1]
            # Rename only if the file extension matches the --in_ext argument. 
            if ext == args.in_ext :
                newname=name + args.out_ext
                src=args.file_dir + '/' + filename
                dst=args.file_dir + '/' + newname
                # Leave it here for debug 
                #print(src)
                #print(dst)
                os.rename(src, dst)
    else :
        print("Specified path is not valid")
        print(args.file_dir)

if __name__ == "__main__":
    main()