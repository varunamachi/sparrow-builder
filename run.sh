#!/bin/bash

serverExe="vaali"
scriptName=$(readlink -f "$0")
deploymentDir=$(dirname "$scriptName")

echo "Checking log dir"
if [ ! -d "${deploymentDir}/logs" ]; then
    mkdir "${deploymentDir}/logs"
fi

logFilePrefix="${deploymentDir}/logs/${serverExe}"
if [ ! -f "${logFilePrefix}.log" ] ; then
    datePrefix=$(date +"%d/%m/%Y %H:%M:%S")
    mv "${logFilePrefix}.log" "${logFilePrefix}_${datePrefix}.log"
fi
touch "${logFilePrefix}.log"

nohup "./${serverExe}" serve > "${logFilePrefix}.log" 2>&1 &
sleep 5s

#Check if server has started
netstat -ntpl | grep "[0-9]:${1:-8000} -q ;"
if [ $? -eq 1 ] ; then 
    echo "${serverExe} started, processID: " 
    ps cax | grep "${serverExe}" | grep -o '^[ ]*[0-9]'
else
    echo "Failed to start ${serverExe}"
fi