#!/bin/bash

function getLatestCode() {
    git clone "$1" "$2" || (cd "$2" ; git pull)
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

#Path where generated installer will be copied
distPath="$2"

#Name of the installer that is going to be generated
# distName="$3"

createDir "${rootPath}"
recreateDir "${distPath}"

cd "${rootPath}"

#get or update dep
go get -u github.com/golang/dep/cmd/dep || exit -1

#get make self
if [ ! -d makeself ]; then
    clone https://github.com/megastep/makeself.git
fi

makeSelfDir="${rootPath}/makeself"
makeSelfExe="${makeSelfDir}/makeself.sh"
PATH="${GOPATH}/bin":${PATH}
vaaliDir="${GOPATH}/src/github/varunamachi/vaali"
vaaliCmdDir="${vaaliDir}/cmd/vaali"
sparrowDir="${rootPath}/sparrow"
scriptName=$(readlink -f "$0")
scriptDir=$(dirname "$scriptName")

#get spw server source code
# getLatestCode "https://github.com/varunamachi/spw"

#get vaali source code - if spw is retrieved the dep should get this
getLatestCode "https://github.com/varunamachi/vaali" "${vaaliDir}" || exit -1
#go to vaali dir and install dependencies
cd "${vaaliDir}" || exit -2
#install dependencies
dep ensure || exit -2
#build and install vaali executable
cd "${vaaliCmdDir}" || exit -2
go install || exit -2

#get sparrow source code
getLatestCode "https://github.com/varunamachi/sparrow" "${sparrowDir}" \
    || exit -1
#build sparrow itself
cd "${sparrowDir}" || exit -3
#install dependencies
npm install || exit -3
#build the web app
npm build || exit -3

#create a temporary directory for building the installer
tempDir=$(mktemp -d -t "sparrow_") || exit -4
mkdir "${tempDir}/static"

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

#Copy stuff to dist directory
cp -R "${sparrowDir}/dist/*"    "${tempDir}/static"
cp "${scriptDir}/install.sh"    "${tempDir}"
cp "${GOPATH}/bin/sparrow"      "${tempDir}"
cp "${scriptDir}/run.sh"        "${tempDir}"

#Create VERSION file and copy it to temp dir
"${makeSelfExe}" --gzip --keep-umask \
    "${tempDir}"  \
    "${distPath}" \
    "Sparrow!"    \
    "./install.sh"              || exit -5

function cleanup() {
    rm -R "${tempDir}"
}

trap cleanup EXIT



