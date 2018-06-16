#!/bin/bash

serverExe="${1}"
deploymentDir=${2}
port=${3}
logFilePrefix="${deploymentDir}/logs/${serverExe}"
datePrefix=$(date +"%Y.%m.%d_%H.%M.%S")

cat  << EOF


echo "Checking log dir"
if [ ! -d "${deploymentDir}/logs" ]; then
    mkdir "${deploymentDir}/logs"
fi

if [ -f "${logFilePrefix}.log" ] ; then
    mv "${logFilePrefix}.log" "${logFilePrefix}_${datePrefix}.log"
fi
touch "${logFilePrefix}.log"

nohup "./${serverExe}" serve --port ${port} > "${logFilePrefix}.log" 2>&1 &
sleep 5s

#Check if server has started
netstat -ntpl | grep "[0-9]*:${1:-8000}"

if lsof -i:8000
then
    echo "${serverExe} started, processID: " 
    ps cax | grep "${serverExe}" | grep -o '^[ ]*[0-9]*'
else
    echo "Failed to start ${serverExe}"
fi

EOF
