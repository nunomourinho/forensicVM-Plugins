PLUGIN_NAME="Reset Windows XP or Windows 2003 Activation"
PLUGIN_DESCRIPTION="Patch Windows XP or 2003 Activation. Not possible to activate by microsoft"
OS_NAME="windows"
OS_VERSION=("xp" "2003")
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
/forensicVM/bin/remove-hibernation.sh $1
rand_name=`cat /dev/urandom | tr -cd 'a-f0-9' | head -c 7;`
cp /forensicVM/plugins/resetXPActivation/resetXP.bat /tmp/resetXPActivation$rand_name.bat
virt-customize -a $1 -firstboot /tmp/resetXPActivation$rand_name.bat
rm /tmp/resetXPActivation$rand_name.bat
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
