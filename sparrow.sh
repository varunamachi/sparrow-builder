#!/bin/bash

REMOTE_USER="$1"
REMOTE_HOST="$2"
NGINX_SITE_NAME="$3"

WORKSPACE_PATH="/var/workspaces"
ROOT_PATH="${WORKSPACE_PATH}/build"
DIST_PATH="${WORKSPACE_PATH}/dist"
DIST_NAME=${WEB_CLIENT_NAME}_$(date +"%Y%m%d_%H%M%S").run
SRV_CMD_NAME="sprw"
SRV_SRC_GO_PATH="github.com/varunamachi/sprw"
WEB_CLIENT_NAME="sparrow"
WEB_CLIENT_REPO="github.com/varunamachi/sparrow"
WEB_CLIENT_PROJECT_DIR="${WORKSPACE_PATH}"
DEPLOYMENT_DIR="/usr/share/nginx/${NGINX_SITE_NAME}/"



export WORKSPACE_PATH
export ROOT_PATH
export DIST_PATH
export DIST_NAME
export SRV_CMD_NAME
export SRV_SRC_GO_PATH
export WEB_CLIENT_NAME
export WEB_CLIENT_REPO
export WEB_CLIENT_PROJECT_DIR
export DEPLOYMENT_DIR
export REMOTE_USER
export REMOTE_HOST

scriptName=$(readlink -f "$0")
scriptDir=$(dirname "$scriptName")

"${scriptDir}/build.sh" || exit -1
"${scriptDir}/deploy.sh" || exit -1

