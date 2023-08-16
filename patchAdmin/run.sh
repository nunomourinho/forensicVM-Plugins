#!/bin/bash -

PLUGIN_NAME="Bypass windows password - Patch NtlmShared.dll"
PLUGIN_DESCRIPTION="Patches the NtlmShared.dll to modify its behavior"
OS_NAME="windows"
OS_VERSION=("8" "8.1" "10" "11")
AUTHOR="Nuno Mourinho"
VERSION="1.0"
LICENSE="GPL"

TEMP_DIR="/tmp/ntlm_patch"
TARGET_FILE_PATH="/Windows/System32/NtlmShared.dll"
EXTRACTED_FILE="$TEMP_DIR/NtlmShared.dll"
SIGNATURE_FILE="pepass.sig"

function get_plugin_info() {
    echo "{\"plugin_name\":\"$PLUGIN_NAME\",\"plugin_description\":\"$PLUGIN_DESCRIPTION\",\"os_name\":\"$OS_NAME\",\"os_version\":\"${OS_VERSION[*]}\",\"author\":\"$AUTHOR\",\"version\":\"$VERSION\",\"license\":\"$LICENSE\"}"
}

function patch_binary() {
    local INPUT_BINARY="$1"
    local OUTPUT_BINARY="$2"
    local TEMP_HEX_FILE="${INPUT_BINARY}_temp.hex"

    # Convert binary to hex dump
    xxd -p -c 256 "$INPUT_BINARY" > "$TEMP_HEX_FILE"

    # Flag to check if any patching was done
    local PATCHED=0

    # Read the .sig file and process replacements
    while IFS=, read -r search_pattern replace_pattern; do
        # Remove any spaces and convert search pattern to uppercase
        search_pattern=$(echo "$search_pattern" | tr -d ' ' | tr 'A-F' 'a-f')
        replace_pattern=$(echo "$replace_pattern" | tr -d ' '| tr 'A-F' 'a-f')

        # Use awk for case-insensitive replacement
        if grep -qi "$search_pattern" "$TEMP_HEX_FILE"; then
            sed -i "s/$search_pattern/$replace_pattern/g" "$TEMP_HEX_FILE"
            echo "Pattern $search_pattern found and patched."
            PATCHED=1
        fi
    done < /forensicVM/plugins/patchAdmin/pepass.sig

    # Convert hex dump back to binary
    xxd -r -p "$TEMP_HEX_FILE" > "$OUTPUT_BINARY"

    # Optional: Clean up the temporary hex file
    #rm "$TEMP_HEX_FILE"

    if [ "$PATCHED" -eq "1" ]; then
        echo "Patching complete. The patched file is $OUTPUT_BINARY."
    else
        echo "No patches applied. Check your patterns or the input file."
    fi
}



function backup_dll() {
    local backup_file="$1.original"
    local i=1

    while guestfish --ro -i "$guestfile" ls "$backup_file" &>/dev/null; do
        backup_file="$1.original.$i"
        ((i++))
    done

    guestfish --rw -i "$guestfile" <<EOF
        cp $1 $backup_file
        exit
EOF

    echo "Backup created as: $backup_file"
}

function run_plugin() {
    set -e

    /forensicVM/bin/remove-hibernation.sh "$1"
    guestfile="$1"

    mkdir -p $TEMP_DIR

    # Check if backup exists and create one if not
    backup_dll "$TARGET_FILE_PATH"

    guestfish --rw -i "$guestfile" <<EOF
       download $TARGET_FILE_PATH $EXTRACTED_FILE
       exit
EOF

    patch_binary "$EXTRACTED_FILE" "$EXTRACTED_FILE"

    guestfish --rw -i "$guestfile" <<EOF
         upload $EXTRACTED_FILE $TARGET_FILE_PATH
         exit
EOF

    rm -rf $TEMP_DIR
}

if [[ "$1" == "run" ]]; then
    run_plugin "$2"
elif [[ "$1" == "info" ]]; then
    get_plugin_info
else
    echo "Invalid parameter. Usage: $0 [run|info]"
    exit 1
fi

