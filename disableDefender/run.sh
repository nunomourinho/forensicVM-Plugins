#!/bin/bash -

PLUGIN_NAME="Permanently disable windows defender and firewall"
PLUGIN_DESCRIPTION="Disables windows defender and firewall"
OS_NAME="windows"
OS_VERSION=("7" "8" "8.1" "10" "11")
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

    # Paths to files in the current directory
    nsudo_exe_path="./NSudo.exe"
    run_bat_path="./disable-defender.bat"

    /forensicVM/bin/remove-hibernation.sh $1

   rand_name=`cat /dev/urandom | tr -cd 'a-f0-9' | head -c 7;`
   cp /forensicVM/plugins/disableDefender/disable-defender.bat /tmp/disable-defender$rand_name.bat
   cp $nsudo_exe_path /tmp/NSudo.exe
   virt-customize -a $1 -firstboot /tmp/disable-defender$rand_name.bat --upload /tmp/NSudo.exe:/Windows/System32/NSudo.exe
   rm /tmp/disable-defender$rand_name.bat /tmp/NSudo.exe
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

