#!/bin/sh

if [ "$WORKSPACE" == "" ]; then
    echo "ERROR: Missing WORKSPACE environment variable."
    exit 1
fi

VERSION=`cat flightgear/version`

#####################################################################################
# remove old and create fresh build directories
cd $WORKSPACE
mkdir -p sgBuild
mkdir -p fgBuild
mkdir -p output
rm -rf output/*
rm -rf dist/*

#####################################################################################
echo "Starting on SimGear"
cd sgBuild
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist -DSIMGEAR_SHARED:BOOL="ON" ../simgear

# compile
make

if [ $? -ne '0' ]; then
    echo "make simgear failed"
    exit 1
fi

make install

# build source package and copy to output
make package_source
cp simgear-*.tar.bz2 ../output/.

#####################################################################################
echo "Starting on FlightGear"
cd ../fgBuild
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist -DSIMGEAR_SHARED:BOOL="ON" ../flightgear

# compile
make

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

make install

# build source package and copy to output
make package_source
cp flightgear-*.tar.bz2 ../output/.

#####################################################################################

echo "Assembling base package"
cd $WORKSPACE

rm -rf base_package

# a: archive mode
# z: compress
# delete: 'delete extraneous files from dest dirs'; avoid bug 1344
# filter: use the rules in our rules file

echo "Copying FGData files"
rsync -a --delete \
 --filter 'merge base-package.rules' \
  fgdata base_package

echo "Syncing aircraft data"
rsync -a --delete --filter 'merge aircraft.rules' /home/jenkins/fgaddon-3.6.0/ extended-data

echo "Copying aircraft data"
rsync -a extended-data/ base_package/fgdata

echo "Creating tar archive"
pushd base_package
tar cjf output/FlightGear-$VERSION-data.tar.bz2 fgdata/
popd
