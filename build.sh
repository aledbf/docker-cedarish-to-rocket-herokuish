#!/usr/bin/env bash

set -eo pipefail

[[ $DEBUG ]] && set -x

# destroy a running container
function removeContainer {
  docker rm -f $1 >/dev/null 2>&1 || true
}

# just for a pretty output
function echo_section {
  echo ""
  echo "--------------------------------------"
  echo $1
  echo "--------------------------------------"
}

# remove container, build a new version, extract a file and destroy the created container
# args: name, buildDirectory, fileToExtract, outputPAth
function buildAndCopy {
  removeContainer $1
  docker build -t $1 $2
  docker cp `docker create --name $1 $1 /bin/bash`:$3 $4
  removeContainer $1
}

# remove container, copy rkt and appc, build a container and run the rocket image
# args: name, directory
function buildAndRun {
  removeContainer $1
  copyRocketTools $2
  docker build -t $1 $2
  docker run --privileged --name $1 -p 5000:5000 $1
}

# copy rkt and actool to the specified directory
function copyRocketTools {
  cp tools/rkt $1
  cp tools/actool $1
  cp tools/stage1.aci $1
}

# remove any container related to this script
function onExit {
  docker stop -t 1 rocket-registry >/dev/null 2>&1 || true
  removeContainer rocket-registry
  removeContainer run-demo
  exit 0
}
trap onExit INT TERM EXIT

CURRENT_DIR=`pwd`
GITHUB_REPO=$1
SLUGRUNNER=$2

APPC_VERSION=0.6.0
RKT_VERSION=0.7.0

echo_section "installing rocket and appc tools..."
mkdir -p tools
cd tools
if [ ! -f ./actool ]; then
  curl -sSL https://github.com/appc/spec/releases/download/v$APPC_VERSION/appc-v$APPC_VERSION.tar.gz | tar -xvz --strip-components=1
fi

if [ ! -f ./rkt ]; then
  curl -sSL https://github.com/coreos/rkt/releases/download/v$RKT_VERSION/rkt-v$RKT_VERSION.tar.gz | tar -xvz --strip-components=1
fi

cd ..

echo_section "starting building process..."

echo_section "converting docker slugrunner image to rocket using docker2aci..."
REGISTRY="$CURRENT_DIR/registry/aledbf"
CEDAR_ACI="heroku-cedar-14-linux-amd64.aci"
if [ ! -f $REGISTRY/$CEDAR_ACI ]; then
  go get github.com/appc/docker2aci
  docker2aci docker://$SLUGRUNNER
  # the patch is required because the manifest is incomplete
  ./actool patch-manifest --manifest=heroku-cedar.manifest heroku-cedar-14.aci $CEDAR_ACI
  mv $CEDAR_ACI $REGISTRY/$CEDAR_ACI
  # if the idea is to be able to create reproducible builds we need the sha of the cedar aci
  #gzip -dc $REGISTRY/$CEDAR_ACI > temp.tar
  #sha512sum temp.tar
  #rm temp.tar
fi

DOCKER_BUILD="build-app-with-docker"
copyRocketTools $DOCKER_BUILD
cat $DOCKER_BUILD/Dockerfile.template | sed -e "s@#APP#@$GITHUB_REPO@" | sed -e "s@#SLUGRUNNER#@$SLUGRUNNER@" > $DOCKER_BUILD/Dockerfile
buildAndCopy herokuish-builder $DOCKER_BUILD /tmp/rocket-herokuish-app.aci $REGISTRY

# this section could be used to run the example locally
#echo_section "running rocket registry..."
#BOOT2DOCKER_IP=$(boot2docker ip 2>/dev/null)
#removeContainer rocket-registry
#docker run --name rocket-registry -p 80:80 -v $CURRENT_DIR/registry/aledbf:/usr/share/nginx/html:ro -d nginx

echo_section "running rocket demo"
buildAndRun run-demo run
