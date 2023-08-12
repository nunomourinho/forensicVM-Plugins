#!/bin/bash -

PLUGIN_NAME="Add linux forensicAdmin"
PLUGIN_DESCRIPTION="Adds a forensicAdmin user with the password forensicAdmin to the Linux system and gives it administrative permissions"
OS_NAME="linux"
OS_VERSION=("debian-based" "redhat-based")
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
set -e
guestfile="$1"

guestfish --rw -i $guestfile <<'EOF'
   add-user forensicAdmin
   password forensicAdmin forensicAdmin
   usermod -aG sudo forensicAdmin
   exit
EOF
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

