#!/bin/bash

function getLatestCode() {
    git clone $1 $2 || (cd $2 ; git pull)
}

function createDir() {
    if [ ! -d $1 ]; then
        mkdir -p $1
    fi
}

function recreateDir() {
    if [ -d $1 ]; then
        rm -Rf $1
    fi
    mkdir -p $1
}

rootPath=$1
distPath=$2

sparrowDir="${rootPaht}/sparrow"
vaaliDir="${GOPATH}/src/github/varunamachi/vaali"
vaaliCmdDir="${vaaliDir}/cmd/vaali"
makeSelfDir="${rootPath}/makeself"
PATH="${GOPATH}/bin":${PATH}

#get spw server source code
# getLatestCode "https://github.com/varunamachi/spw"

#get vaali source code - if spw is retrieved the dep should get this
getLatestCode "https://github.com/varunamachi/vaali" ${vaaliDir} || exit -1

#get sparrow source code
getLatestCode "https://github.com/varunamachi/sparrow" ${sparrowDir} || exit -1

#get or update dep
go get -u github.com/golang/dep/cmd/dep || exit -1

#go to vaali dir and install dependencies
cd ${vaaliDir} || exit -2
dep ensure || exit -2

#build and install vaali executable
cd ${vaaliCmdDir} || exit -2
go install || exit -2

#build sparrow itself
cd ${sparrowDir} || exit -3

#install dependencies
npm install || exit -3

#build the web app
npm build || exit -3

#make the package...


