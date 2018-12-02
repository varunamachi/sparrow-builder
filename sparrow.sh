#!/bin/bash

if [ $# -lt 3 ] ; then 
    echo "Insufficient arguments... Requires: "
    echo "  1. Remote Host - remote host where app has to be deployed"
    echo "  2. Remote User Name - user account name at remote host"
    echo "  3. NGINX site name - site name for NGINX for deployment"
    exit 1
fi

REMOTE_HOST="$1"
REMOTE_USER="$2"
NGINX_SITE_NAME="$3"


WORKSPACE_PATH="/var/workspaces"
ROOT_PATH="${WORKSPACE_PATH}/build"
DIST_PATH="${WORKSPACE_PATH}/dist"
DIST_NAME=${WEB_CLIENT_NAME}_$(date +"%Y%m%d_%H%M%S").run
SRV_CMD_NAME="sprw"
SERVER_REPO="https://github.com/varunamachi/sprw"
SRV_SRC_GO_PATH="github.com/varunamachi/sprw"
WEB_CLIENT_NAME="sparrow"
WEB_CLIENT_REPO="github.com/varunamachi/sparrow"
WEB_CLIENT_PROJECT_DIR="${WORKSPACE_PATH}/webclient"
DEPLOYMENT_DIR="/usr/share/nginx/${NGINX_SITE_NAME}"
SERVER_PORT="8000"



export WORKSPACE_PATH
export ROOT_PATH
export DIST_PATH
export DIST_NAME
export SRV_CMD_NAME
export SERVER_REPO
export SRV_SRC_GO_PATH
export WEB_CLIENT_NAME
export WEB_CLIENT_REPO
export WEB_CLIENT_PROJECT_DIR
export DEPLOYMENT_DIR
export REMOTE_USER
export REMOTE_HOST
export SERVER_PORT

scriptName=$(readlink -f "$0")
scriptDir=$(dirname "$scriptName")

"${scriptDir}/build.sh" || exit -1
"${scriptDir}/deploy.sh" || exit -1

