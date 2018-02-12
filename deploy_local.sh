#!/bin/bash
#Deploys sparrow on the machine on which this script is invoked on

appName="sparrow"
distName=${appName}_$(date +"%Y%m%d_%H%M%S").run
workspacePath="/var/workspaces"
distPath="${workspacePath}/dist/${distName}"

scriptName=$(readlink -f "$0")
scriptDir=$(dirname "$scriptName")

#build - set dist path
"${scriptDir}/build.sh" "${workspacePath}/build" "${distPath}"  || exit 5

#install from dist path
"${distPath}" || exit 5

#remove dist??
