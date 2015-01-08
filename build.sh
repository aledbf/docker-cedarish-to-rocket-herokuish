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

BUILDER="compat-builder"

DOCKER_BUILD="build-app-with-docker"

ROCKET_BUILD="build-rocket-image"
ROOTFS=$ROCKET_BUILD/demo/rootfs

ROCKET_PARENT=rocket-slugrunner
ROCKET_PARENT_BUILD="build-parent-image"
ROCKET_PARENT_ROOTFS=$ROCKET_PARENT_BUILD/slugrunner/rootfs

echo_section "cleaning..."
rm -rf $ROOTFS $ROCKET_PARENT_ROOTFS
mkdir -p $ROOTFS/app $ROCKET_PARENT_ROOTFS

echo_section "starting building process..."
cat $DOCKER_BUILD/Dockerfile.template | sed -e "s@#APP#@$GITHUB_REPO@" | sed -e "s@#SLUGRUNNER#@$SLUGRUNNER@" > $DOCKER_BUILD/Dockerfile
docker build -t $BUILDER $DOCKER_BUILD

echo_section "extracting generated slug.tgz..."
removeContainer $BUILDER
docker create $BUILDER
docker cp `docker create --name $BUILDER $BUILDER`:/tmp/slug.tgz $CURRENT_DIR
removeContainer $BUILDER

echo_section "converting docker slugrunner image to rocket rootfs..."
docker create --name docker-slugrunner dev-registry.soficom.cl:5000/soficom/slugrunner:v0.5
docker export docker-slugrunner | tar -x -C $ROCKET_PARENT_ROOTFS -f -
removeContainer docker-slugrunner

echo_section "building rocket parent image..."
docker build -t $ROCKET_PARENT $ROCKET_PARENT_BUILD
docker cp `docker create --name $ROCKET_PARENT_BUILD $ROCKET_PARENT /bin/bash`:/tmp/slugrunner.aci $CURRENT_DIR
removeContainer $ROCKET_PARENT_BUILD

# osx alternative to sha512sum
echo_section "generating sha512 from generated image"
SHA512=`openssl dgst -sha512 slugrunner.aci | cut -d' ' -f 2 | cut -c1-33`
cat $ROCKET_BUILD/manifest.template | sed -e "s@#SHA512#@$SHA512@" > $ROCKET_BUILD/demo/manifest

echo_section "decompressing generated application tgz..."
tar -xzf slug.tgz -C $ROOTFS/app

echo_section "generating manifest..."

echo_section "extracting rocket image from docker..."
docker build -t $ROCKET_BUILD $ROCKET_BUILD
removeContainer $ROCKET_BUILD
docker cp `docker create $ROCKET_BUILD`:/tmp/rocket-herokuish-nodejs.aci $CURRENT_DIR
removeContainer $ROCKET_BUILD

echo_section "running rocket registry..."
mkdir -p registry/aledbf
mv *.aci registry/aledbf

echo_section "running rocket demo"
cat run/Dockerfile.template | sed -e "s/#IP#/$1/" > run/Dockerfile
docker build -t run-demo run

removeContainer rocket-registry
removeContainer demo
docker run --name rocket-registry -p 8080:80 -v $CURRENT_DIR/registry:/usr/share/nginx/html:ro -d nginx
docker run --name demo --privileged -it run-demo

