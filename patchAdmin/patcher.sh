#!/bin/bash

TARGET_FILE="$1"
SIGNATURE_FILE="$2"

# Function to patch a specific location in the file
patch_file() {
    OFFSET=$1
    DATA=$2
    
    echo "Patching offset $OFFSET with $DATA"
    
    # Convert ASCIIHEX to binary
    if [[ "$DATA" =~ ^[0-9A-Fa-f]+$ ]]; then
        DATA=$(echo $DATA | xxd -r -p)
    fi
    
    # Use dd to patch the file at specific offset
    echo -n "$DATA" | dd of="$TARGET_FILE" bs=1 seek=$((16#$OFFSET)) count=${#DATA} conv=notrunc &>/dev/null
}

# Read the signature file line by line
while IFS= read -r line; do
    # Ignore lines starting with '#'
    if [[ "$line" =~ ^#.* ]]; then
        continue
    fi
    
    # Extract chunks from the line
    IFS=',' read -ra CHUNKS <<< "$line"
    
    # Apply patches based on the instruction guide
    for CHUNK in "${CHUNKS[@]}"; do
        IFS=' ' read OFFSET DATA <<< "$CHUNK"
        
        # Check if the data section contains filename to load binary data from
        if [[ -f "$DATA" ]]; then
            DATA=$(cat "$DATA")
        fi
        
        patch_file "$OFFSET" "$DATA"
    done
done < "$SIGNATURE_FILE"

echo "Patching complete."

