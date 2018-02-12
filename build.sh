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

#Path where code and required tools will be checked out
rootPath="$1"
echo "Build root: ${rootPath}"

#Path where generated installer will be copied
distPath="$2"
echo "Dist path: ${distPath}"

#Name of the installer that is going to be generated
# distName="$3"

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
vaaliDir="${GOPATH}/src/github.com/varunamachi/vaali"
vaaliCmdDir="${vaaliDir}/cmd/vaali"
sparrowDir="${rootPath}/sparrow"
scriptName=$(readlink -f "$0")
scriptDir=$(dirname "$scriptName")

#get spw server source code
# getLatestCode "https://github.com/varunamachi/spw"

#get vaali source code - if spw is retrieved the dep should get this
echo "Cloning Vaali to ${vaaliDir}..."
getLatestCode "https://github.com/varunamachi/vaali" "${vaaliDir}" || exit -1
echo "Done!"

#go to vaali dir and install dependencies
cd "${vaaliDir}" || exit -2
echo "Entered ${vaaliDir}, Depping..."
dep ensure || exit -2

#build and install vaali executable
cd "${vaaliCmdDir}" || exit -2
echo "Entered ${vaaliCmdDir}, Installing..."
go install || exit -2

#get sparrow source code
echo "Clone Sparrow to ${sparrowDir}..."
getLatestCode "https://github.com/varunamachi/sparrow" "${sparrowDir}" \
    || exit -1
echo "Done!, Entering ${sparrowDir}, Installing dependencies..."
cd "${sparrowDir}" || exit -3
npm install || exit -3
echo "Performing build..."
npm run build || exit -3
echo "Done!"


#create a temporary directory for building the installer
tempDir=$(mktemp -d -t "sparrow_xxxxxxxx") || exit -4
mkdir "${tempDir}/static"
echo "Created temp dir: ${tempDir}"

buildDate=$(date +"%d/%m/%Y %H:%M:%S")
goVersion=$(go version)
nodeVersion=$(node --version)
npmVersion=$(npm --version)
cd "$sparrowDir"
hashSparrow=$(git log --format=%H -n 1)
cd "$vaaliDir"
hashVaali=$(git log --format=%M -n 1)
cd "${rootPath}"

version_info="${tempDir}/version.json"
touch "${version_info}"
{
    echo "{"                                 
    echo "    nodeVersion: ${nodeVersion},"  
    echo "    npmVersion: ${npmVersion},"    
    echo "    goVersion: ${goVersion},"      
    echo "    sparrowCommit: ${hashSparrow},"
    echo "    vaaliCommit: ${hashVaali},"    
    echo "    builtAt: ${buildDate}"         
    echo "}"                                 
} >> "${version_info}"
echo "Version file: "
cat "${version_info}"
#Copy stuff to dist directory
echo "Copying static files ${sparrowDir}/dist/*"
cp -R "${sparrowDir}/dist/*"    "${tempDir}/static" || exit -5
echo "Copying ${scriptDir}/install.sh"
cp "${scriptDir}/install.sh"    "${tempDir}"	    || exit -5
echo "Copying ${GOPATH}/bin/vaali"
cp "${GOPATH}/bin/vaali"        "${tempDir}"        || exit -5
echo "Copying ${scriptDir}/run.sh"
cp "${scriptDir}/run.sh"        "${tempDir}"        || exit -5

#Create VERSION file and copy it to temp dir
echo "Makeself: ${tempDir} --> ${distPath}"
"${makeSelfExe}" --gzip --keep-umask \
    "${tempDir}"  \
    "${distPath}" \
    "Sparrow!"    \
    "./install.sh"              || exit -5

function cleanup() {
    echo "Cleaning up temp dir"
    rm -R "${tempDir}"
}

trap cleanup EXIT



