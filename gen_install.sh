#!/bin/bash

#!/bin/bash
#This script will invoke the sparrow server

serverExe="${1}"
deploymentDir="${2}"
# deploymentDir="/usr/share/nginx/grinningyeti.com/"

#for templating...
cat  << EOF

if [ ! -d "${deploymentDir}" ] ; then
    mkdir -p "${deploymentDir}"
fi

#kill the previous instance
echo "Killing previous instance of server"
killall "${serverExe}"
echo "Delete previous installation"
rm -f "${deploymentDir}/${serverExe}" || exit 1
rm -f "${deploymentDir}/version.json"  || exit 1
rm -f "${deploymentDir}/run.sh"        || exit 1
rm -Rf "${deploymentDir}/static"       || exit 1    

echo "Copying files..."
cp "${serverExe}" "${deploymentDir}"  || exit 2
cp version.json "${deploymentDir}"  || exit 2
cp run.sh "${deploymentDir}"        || exit 2
cp -R static "${deploymentDir}"     || exit 2
chmod 755 "${deploymentDir}/${serverExe}"
chmod 755 "${deploymentDir}/run.sh"
"${deploymentDir}/run.sh"

EOF
