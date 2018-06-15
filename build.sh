#!/bin/bash

function getLatestCode() {
    if [ ! -d "${2}/.git" ] ; then
	git clone "${1}" "${2}"
    else 
	cd "${2}"
	git pull
    fi
}

function createDir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

function recreateDir() {
    if [ -d "$1" ]; then
        rm -Rf "$1"
    fi
    mkdir -p "$1"
}

#Path where code and required tools will be checked out. ex: /var/workspaces
rootPath="${ROOT_PATH}"

#Path where generated installer will be copied. ex: /mnt/builds/sprw/nightlies
distPath="${DIST_PATH}"

#Name of the installer that is going to be generated. 
#ex: sprw_yyyymmdd_hhmmss.run
distName="${DIST_NAME}"

#Server command dir path relative to GOPATH ex: cmd/vaali
srvCmdName="${SRV_CMD_NAME}"

#Source directory of server peoject ex: github.com/varunamachi/vaali
srvSrcGoPath="${SRV_SRC_GO_PATH}"

wcName="${WEB_CLIENT_NAME}"

wcRepo="${WEB_CLIENT_REPO}"

wcProjectDir="${WEB_CLIENT_PROJECT_DIR}"

deploymentDir=${DEPLOYMENT_DIR}

#git repo of server project
gitRepo="https://${srvSrcGoPath}"
srvProjectDir="${GOPATH}/src/${srvSrcGoPath}"
srvCmdDir="${srvProjectDir}/cmd/${srvCmdName}"


echo "Build root: ${rootPath}"
echo "Dist path: ${distPath}"
echo "Server Command Name: ${srvCmdName}"
echo "Git Repo:  ${gitRepo}"
echo "Server Command Abs Path: ${srvCmdDir}"
echo "Web Client Name: ${wcName}"
echo "Web Client Repo: ${wcRepo}"
echo "Web Client Project Dir: ${wcProjectDir}"
echo "Deployment Directory: ${DEPLOYMENT_DIR}"


tempDir=$(mktemp -d -t "${wcName}_XXXXXXXX") || exit -4
echo "Temp Dir: ${tempDir}"
cleanup() {
    echo "Cleaning up temp dir"
    rm -R "${tempDir}"
}
trap cleanup EXIT



createDir "${rootPath}"
recreateDir "${distPath}"
echo "Recreated dist at: ${distPath}"

cd "${rootPath}"
echo "Moved to ${rootPath}"

#get or update dep
echo "Updating DEP"
go get -u github.com/golang/dep/cmd/dep || exit -1

#get make self
if [ ! -d makeself ]; then
    git clone https://github.com/megastep/makeself.git
    echo "Cloned makeself at $(pwd)"
fi

makeSelfDir="${rootPath}/makeself"
makeSelfExe="${makeSelfDir}/makeself.sh"
PATH="${GOPATH}/bin":${PATH}
scriptName=$(readlink -f "$0")
scriptDir=$(dirname "$scriptName")

#get server source code - if spw is retrieved the dep should get this
echo "Cloning ${srvCmdName} to ${srvProjectDir}..."
getLatestCode "${gitRepo}" "${srvProjectDir}" || exit -1
echo "Done!"

#go to project dir and install dependencies
cd "${srvProjectDir}" || exit -2
echo "Entered ${srvProjectDir}, Depping..."
dep ensure || exit -2

#build and install server executable
cd "${srvCmdDir}" || exit -2
echo "Entered ${srvCmdDir}, Installing..."
go install || exit -2

#get web client source code
echo "Clone ${wcName} to ${wcProjectDir}..."
getLatestCode "https://${wcRepo}" "${wcProjectDir}" || exit -1
echo "Done!, Entering ${wcName}, Installing dependencies..."
cd "${wcProjectDir}" || exit -3
npm install || exit -3
echo "Performing build..."
npm run build || exit -3
echo "Done!"


#create a temporary directory for building the installer
mkdir "${tempDir}/static"
echo "Created temp dir: ${tempDir}"

buildDate=$(date +"%d/%m/%Y %H:%M:%S")
goVersion=$(go version)
nodeVersion=$(node --version)
npmVersion=$(npm --version)
cd "${wcProjectDir}"
hashWC=$(git log --format=%H -n 1)
cd "${srvProjectDir}"
hashSrv=$(git log --format=%M -n 1)
cd "${rootPath}"

version_info="${tempDir}/version.json"
touch "${version_info}"
{
    echo "{"                                 
    echo "    nodeVersion: \"${nodeVersion}\","  
    echo "    npmVersion: \"${npmVersion}\","    
    echo "    goVersion: \"${goVersion}\","      
    echo "    ${wcName}Commit: \"${hashWC}\","
    echo "    ${srvCmdName}Commit: \"${hashSrv}\","    
    echo "    builtAt: \"${buildDate}\""         
    echo "}"                                 
} >> "${version_info}"
echo "Version file: "
cat "${version_info}"

#Copy stuff to dist directory
echo "Copying static files ${wcProjectDir}/dist/*"
cp -r "${wcProjectDir}/dist/"*   "${tempDir}/static/" || exit -5
echo "Copying ${GOPATH}/bin/${srvCmdName}"
cp "${GOPATH}/bin/${srvCmdName}" "${tempDir}"        || exit -5

# echo "Copying ${scriptDir}/install.sh"
# cp "${scriptDir}/install.sh"    "${tempDir}"	    || exit -5
# echo "Copying ${scriptDir}/run.sh"
# cp "${scriptDir}/run.sh"        "${tempDir}"         || exit -5
echo "Generating ${tempDir}/install.sh"
"${scriptDir}/gen_install.sh" "${srvCmdName}" "${deploymentDir}" \
    | tee "${tempDir}/install.sh"   || exit -5
chmod +x "${tempDir}/install.sh"

echo "Generating ${tempDir}/run.sh"
"${scriptDir}/gen_run.sh" "${srvCmdName}" "${deploymentDir}" \
    | tee "${tempDir}/run.sh"   || exit -5
chmod +x "${tempDir}/run.sh"

#Create VERSION file and copy it to temp dir
echo "Makeself: ${tempDir} --> ${distPath}"
"${makeSelfExe}" --gzip --keep-umask \
    "${tempDir}"  \
    "${distPath}/${distName}" \
    "${wcName}!"    \
    "./install.sh"              || exit -5



