#!/usr/bin/env bash

set -eo pipefail

[[ $DEBUG ]] && set -x

function removeContainer {
  docker rm -f $1 >/dev/null 2>&1 || true
}

function echo_section {
  echo ""
  echo "--------------------------------------"
  echo $1
  echo "--------------------------------------"
}

# name directory file path
function buildAndCopy {
  removeContainer $1
  docker build -t $1 $2
  docker cp `docker create --name $1 $1 /bin/bash`:$3 $4
  removeContainer $1
}

function buildAndRun {
  removeContainer $1
  docker build -t $1 $2
  docker run --name $1 --privileged -it $1
}

function onExit {
  docker stop -t 1 rocket-registry >/dev/null 2>&1 || true
  removeContainer rocket-registry
  removeContainer run-demo
  exit 0
}
trap onExit INT TERM EXIT

CURRENT_DIR=`pwd`
DOCKER_IP=$1
GITHUB_REPO=$2
SLUGRUNNER=$3

REGISTRY="registry/aledbf"

ROCKET_BUILD="build-app-rocket-image"
ROOTFS=$ROCKET_BUILD/demo/rootfs

ROCKET_PARENT_ROOTFS=build-parent-image/slugrunner/rootfs

echo_section "cleaning..."
rm -rf $ROOTFS $ROCKET_PARENT_ROOTFS *.tgz
mkdir -p $ROOTFS/app $ROCKET_PARENT_ROOTFS

echo_section "building rocket and actool..."
buildAndCopy tools build-rocket-image /tools.tgz `pwd`

echo_section "copying tools..."
cp tools.tgz build-app-rocket-image
cp tools.tgz run

# echo_section "starting building process..."
DOCKER_BUILD="build-app-with-docker"
cat $DOCKER_BUILD/Dockerfile.template | sed -e "s@#APP#@$GITHUB_REPO@" | sed -e "s@#SLUGRUNNER#@$SLUGRUNNER@" > $DOCKER_BUILD/Dockerfile
buildAndCopy herokuish-builder $DOCKER_BUILD /tmp/slug.tgz $CURRENT_DIR

echo_section "converting docker slugrunner image to rocket rootfs..."
docker create --name docker-slugrunner dev-registry.soficom.cl:5000/soficom/slugrunner:v0.5
docker export docker-slugrunner | tar -x -C $ROCKET_PARENT_ROOTFS -f -
removeContainer docker-slugrunner

echo_section "building rocket parent image..."
buildAndCopy parent-image build-parent-image /tmp/slugrunner.aci $REGISTRY

# osx alternative to sha512sum
echo_section "generating sha512 from generated image"
SHA512=`openssl dgst -sha512 $REGISTRY/slugrunner.aci | cut -d' ' -f 2 | cut -c1-33`
cat $ROCKET_BUILD/manifest.template | sed -e "s@#SHA512#@$SHA512@" > $ROCKET_BUILD/demo/manifest

echo_section "decompressing generated application tgz..."
tar -xzf slug.tgz -C $ROOTFS/app

echo_section "generating manifest..."

echo_section "extracting rocket image from docker..."
buildAndCopy $ROCKET_BUILD $ROCKET_BUILD /tmp/rocket-herokuish-nodejs.aci $REGISTRY

echo_section "running rocket registry..."
removeContainer rocket-registry
docker run --name rocket-registry -p 8080:80 -v $CURRENT_DIR/registry:/usr/share/nginx/html:ro -d nginx

echo_section "running rocket demo"
cat run/Dockerfile.template | sed -e "s/#IP#/$1/" > run/Dockerfile
buildAndRun run-demo run

