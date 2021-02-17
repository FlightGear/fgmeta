#!/bin/bash

#####################################################################################


if [ "$WORKSPACE" == "" ]; then
    echo "ERROR: Missing WORKSPACE environment variable."
    exit 1
fi

if [ ! -d "$WORKSPACE/fgdata" ]; then
    echo "No fgdata subdir in WORKSPACE: can't continue"
    exit 1
fi


VERSION=`cat fgdata/version`
BASE_VERSION_TAG="version/2020.3.1"
SCENERY_PACK_AIRPORT=BIKF
SCENERY_PACK_URI="https://sourceforge.net/projects/flightgear/files/scenery/SceneryPack.${SCENERY_PACK_AIRPORT}.tgz/download"

echo "Assembling base package for $VERSION"
cd $WORKSPACE


# wipe directories and re-create
rm -rf output
rm -rf staging
mkdir -p output
mkdir -p staging

rsync -az --exclude=".git" fgdata staging/

# add all the scenery pack files into it

SCENERY_PACK_NAME=SceneryPack_${SCENERY_PACK_AIRPORT}.tgz

# Should we re-download the SceneryPack periodically? Or just rely on doing a workspace wipe?
if [ ! -f $SCENERY_PACK_NAME ]; then
    echo "Downlaod scenery pack from ${SCENERY_PACK_URI}"
    # -L to follow the SF redirect
    curl -L $SCENERY_PACK_URI --output $SCENERY_PACK_NAME
fi

tar -xf $SCENERY_PACK_NAME --directory staging/fgdata
pushd staging/fgdata
mv SceneryPack.${SCENERY_PACK_AIRPORT} Scenery
popd

# Creating full base package TXZ 

OUTPUT_NAME=FlightGear-$VERSION-data
tar -cJf output/$OUTPUT_NAME.txz --directory staging fgdata

echo "Creating updates package"

pushd fgdata
git diff --name-only --line-prefix="fgdata/" $BASE_VERSION_TAG..HEAD > ../fgdata_changes
popd

tar -cJf output/FlightGear-$VERSION-update-data.txz -T fgdata_changes

echo "Done, data TXZs are in output/"
