#!/bin/bash

#Deploys sparrow on a machine that is different from the machine on which this
#script is invoked. This script uses SSH and SCP. It needs SSH keys for the
#remote machine to be copied to the key store of the user invoking this script

remoteHost=${REMOTE_HOST:="localhost"}
remoteUser=${REMOTE_USER:=$(whoami)}

appName="sparrow"
distName=${appName}_$(date +"%Y%m%d_%H%M%S").run
workspacePath="/var/workspaces/sparrow/dist"
distPath="${workspacePath}/${distName}"
remoteDir

scriptName=$(readlink -f "$0")
scriptDir=$(dirname "$scriptName")

#build - set dist path
"${scriptDir}/build.sh" "${workspacePath}/build" "${distPath}" || exit 5

#ssh -tt
# ssh "${remoteUser}@${remoteHost}" mkdir -p "/temp"
scp "${distPath}" "${remoteUser}@${remoteHost}:/temp"
ssh "${remoteUser}@${remoteHost}" "/temp/${distName}"
