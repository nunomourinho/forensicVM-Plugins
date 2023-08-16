#!/bin/bash -

PLUGIN_NAME="BOOTFIX: Disable Driver Signature Enforcement"
PLUGIN_DESCRIPTION="Disables the signed driver enforcement on a Windows system"
OS_NAME="windows"
OS_VERSION=("xp" "7" "8" "8.1" "10" "11")
AUTHOR="Nuno Mourinho"
VERSION="1.0"
LICENSE="GPL"

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

function run_plugin() {
    guestfile="$1"
    
    # Prepare .reg file
    echo '[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows NT\Driver Signing]' > /tmp/linux.reg
    echo '"BehaviorOnFailedVerify"=dword:00000000' >> /tmp/linux.reg
    unix2dos /tmp/linux.reg | iconv -f utf-8 -t utf-16le > /tmp/win.reg

    # Apply registry modification
    if ! virt-win-reg --merge $guestfile /tmp/win.reg; then
        echo "Error: Failed to modify the registry."
        exit 1
    fi
    
    # Upload PowerShell script and create scheduled task
    echo 'bcdedit /set nointegritychecks on
schtasks /delete /tn "ModifyBCD" /f' > modify-bcd.ps1
    virt-customize -a $guestfile --upload modify-bcd.ps1:/Windows/Temp/modify-bcd.ps1 \
        --run-command 'schtasks /create /tn "ModifyBCD" /tr "powershell -executionpolicy bypass -file C:\Windows\Temp\modify-bcd.ps1" /sc onstart /ru System'

    # Clean up temporary files
    rm /tmp/linux.reg /tmp/win.reg modify-bcd.ps1

    echo "Registry modification and scheduled task creation were successful."
}

# Check the first parameter and call the appropriate function
if [[ "$1" == "run" ]]; then
  run_plugin $2
elif [[ "$1" == "info" ]]; then
  get_plugin_info
else
  echo "Invalid parameter. Usage: ./myscript.sh [run|info]"
  exit 1
fi

