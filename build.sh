#!/usr/bin/env bash

set -eo pipefail

#set -x

BUILDER="compat-builder"
APP_SLUG="/tmp/slug.tgz"
DOCKER_BUILD="build-app-with-docker"
ROCKET_PARENT_BUILD="build-parent-image"
ROCKET_PARENT=rocket-slugrunner
ROCKET_BUILD="build-rocket-image"
ROOTFS=$ROCKET_BUILD/demo/rootfs
ROCKET_PARENT_ROOTFS=$ROCKET_PARENT_BUILD/slugrunner/rootfs
ACI_NAME=herokuish-docker-express.aci

echo "starting building process..."
rm -rf $ROOTFS $ROCKET_PARENT_ROOTFS
mkdir -p $ROOTFS/app $ROCKET_PARENT_ROOTFS

docker build -t $BUILDER $DOCKER_BUILD

echo "extracting generated slug..."
docker create $BUILDER
docker cp `docker create --name $BUILDER $BUILDER`:$APP_SLUG `pwd`
docker rm $BUILDER

echo "converting docker slugrunner image to rocket rootfs..."
docker create --name rocket-slugrunner dev-registry.soficom.cl:5000/soficom/slugrunner:v0.5
docker export rocket-slugrunner | tar -x -C $ROCKET_PARENT_ROOTFS -f -
docker rm rocket-slugrunner

echo "building rocket parent image..."
docker build -t $ROCKET_PARENT $ROCKET_PARENT_BUILD
docker cp `docker create --name $ROCKET_PARENT $ROCKET_PARENT`:/tmp/slugrunner.aci `pwd`/$ROOTFS
docker rm $ROCKET_PARENT
# osx alternative to sha512sum
echo "generating sha512 from generated image"
SHA512=`openssl dgst -sha512 $ROCKET_BUILD/slugrunner.aci | cut -d' ' -f 2 | cut -c1-41`
cat $ROCKET_BUILD/manifest.template | sed -e "s/#SH512#/$SHA512/" > $ROCKET_BUILD/demo/manifest

echo "decompressing generated application tgz..."
tar -xzf slug.tgz -C $ROOTFS/app

echo "generating manifest..."

echo "building rocket image..."
docker build -t $BUILDER $ROCKET_BUILD

echo "extracting rocket image from docker..."
docker cp `docker create $ROCKET_BUILD`:/tmp/$ACI_NAME $ACI_NAME

echo "done"