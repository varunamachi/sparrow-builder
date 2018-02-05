#!/bin/bash

function getLatestCode(url, repoName) {
    git clone $url || (cd $repoName ; git pull)
}

rootPath = $1
distPath = $2
sparrowDir = "${rootPaht}/sparrow"
vaaliDir = "${GOPATH}/src/github/varunamachi/vaali"
vaaliCmdDir = "${vaaliDir}/cmd/vaali"
PATH="${GOPATH}/bin":${PATH}

#get spw server source code
# getLatestCode "https://github.com/varunamachi/spw"

#get vaali source code - if spw is retrieved the dep should get this
getLatestCode "https://github.com/varunamachi/vaali" || exit -1

#get sparrow source code
getLatestCode "https://github.com/varunamachi/sparrow" || exit -1

#get or update dep
go get -u github.com/golang/dep/cmd/dep || exit -1

#go to vaali dir and install dependencies
cd ${vaaliDir} || exit -2
dep ensure || exit -2

#build and install vaali executable
cd ${vaaliCmdDir} || exit -2
go install || exit -2

cd ${sparrowDir} || exit -3
npm install || exit -2


