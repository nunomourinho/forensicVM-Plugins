#!/bin/bash -

PLUGIN_NAME="Bypass windows password - Patch NtlmShared.dll"
PLUGIN_DESCRIPTION="Patches the NtlmShared.dll to modify its behavior"
OS_NAME="windows"
OS_VERSION=("xp" "7" "8" "8.1" "10" "11")
AUTHOR="Nuno Mourinho"
VERSION="1.0"
LICENSE="GPL"

TEMP_DIR="/tmp/ntlm_patch"
TARGET_FILE_PATH="/Windows/System32/NtlmShared.dll"
EXTRACTED_FILE="$TEMP_DIR/NtlmShared.dll"
SIGNATURE_FILE="unlock-win10.sig"

function get_plugin_info() {
  # Build JSON object
  json="{"
  json+="\"plugin_name\":\"$PLUGIN_NAME\","
  json+="\"plugin_description\":\"$PLUGIN_DESCRIPTION\","
  json+="\"os_name\":\"$OS_NAME\","
  json+="\"os_version\":\"$OS_VERSION\","
  json+="\"author\":\"$AUTHOR\","
  json+="\"version\":\"$VERSION\","
  json+="\"license\":\"$LICENSE\""
  json+="}"

  # Return JSON object
  echo $json
}


function patch_file() {
    SEARCH_OFFSET=$1
    SEARCH_DATA=$2
    REPLACE_OFFSET=$3
    REPLACE_DATA=$4

    # Check if any of the inputs are empty
    if [ -z "$SEARCH_OFFSET" ] || [ -z "$SEARCH_DATA" ] || [ -z "$REPLACE_OFFSET" ] || [ -z "$REPLACE_DATA" ]; then
        echo "Error: Missing data. Skipping patch..."
        return 1
    fi

    # Convert ASCIIHEX to binary
    if [[ "$SEARCH_DATA" =~ ^[0-9A-Fa-f]+$ ]]; then
        SEARCH_DATA=$(echo $SEARCH_DATA | xxd -r -p)
    fi

    if [[ "$REPLACE_DATA" =~ ^[0-9A-Fa-f]+$ ]]; then
        REPLACE_DATA=$(echo $REPLACE_DATA | xxd -r -p)
    fi

    # Use dd to check if the SEARCH_DATA exists at the given OFFSET
    CURRENT_DATA=$(dd if="$TARGET_FILE" bs=1 skip=$((16#$SEARCH_OFFSET)) count=${#SEARCH_DATA} 2>/dev/null)
    if [ "$CURRENT_DATA" == "$SEARCH_DATA" ]; then
        echo "Data matches at offset $SEARCH_OFFSET. Patching..."
        echo -n "$REPLACE_DATA" | dd of="$TARGET_FILE" bs=1 seek=$((16#$REPLACE_OFFSET)) count=${#REPLACE_DATA} conv=notrunc &>/dev/null
    else
        echo "Data mismatch at offset $SEARCH_OFFSET. Skipping patch..."
    fi
}

function patch_dll() {
    while IFS= read -r line; do
        # Ignore comment lines
        if [[ "$line" =~ ^#.* ]]; then
            continue
        fi

        IFS=',' read -ra CHUNKS <<< "$line"
        for ((i=0; i<${#CHUNKS[@]}; i+=4)); do
            SEARCH_OFFSET=${CHUNKS[i]}
            SEARCH_DATA=${CHUNKS[i+1]}
            REPLACE_OFFSET=${CHUNKS[i+2]}
            REPLACE_DATA=${CHUNKS[i+3]}

            patch_file "$SEARCH_OFFSET" "$SEARCH_DATA" "$REPLACE_OFFSET" "$REPLACE_DATA"
        done
    done < "$SIGNATURE_FILE"
    echo "Patching complete."
}




function run_plugin() {
set -e

/forensicVM/bin/remove-hibernation.sh $1
guestfile="$1"

mkdir -p $TEMP_DIR

guestfish --rw -i $guestfile <<EOF
   download $TARGET_FILE_PATH $EXTRACTED_FILE
   exit
EOF

patch_dll

if [ $? -eq 0 ]; then
  guestfish --rw -i $guestfile <<EOF
     mv $TARGET_FILE_PATH ${TARGET_FILE_PATH}.original
     upload $EXTRACTED_FILE $TARGET_FILE_PATH
     exit
EOF
fi

rm -rf $TEMP_DIR
}

# Check the first parameter and call the appropriate function
if [[ "$1" == "run" ]]; then
  run_plugin $2
elif [[ "$1" == "info" ]]; then
  get_plugin_info
else
  echo "Invalid parameter. Usage: ./run.sh [run|info]"
  exit 1
fi

