#!/bin/bash

#Deploys sparrow on a machine that is different from the machine on which this
#script is invoked. This script uses SSH and SCP. It needs SSH keys for the
#remote machine to be copied to the key store of the user invoking this script
remoteHost=${REMOTE_HOST:="localhost"}
remoteUser=${REMOTE_USER:=$(whoami)}
scp "${DIST_PATH}/${DIST_NAME}" "${remoteUser}@${remoteHost}:/tmp"
ssh "${remoteUser}@${remoteHost}" "/tmp/${DIST_NAME}"
