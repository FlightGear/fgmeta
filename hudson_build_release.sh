#!/bin/sh

if [ "$WORKSPACE" == "" ]; then
    echo "ERROR: Missing WORKSPACE environment variable."
    exit 1
fi

VERSION=`cat flightgear/version`

#####################################################################################
# remove old and create fresh build directories
rm -rf sgBuild
rm -rf fgBuild
mkdir -p sgBuild
mkdir -p fgBuild
mkdir -p output
rm -rf output/*
rm -rf $WORKSPACE/dist/include/simgear $WORKSPACE/dist/libSim* $WORKSPACE/dist/libsg*.a

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

echo "Syncing base packages files from sphere.telascience.org"

# a: archive mode
# z: compress
# delete: 'delete extraneous files from dest dirs'; avoid bug 1344
# filter: use the rules in our rules file
rsync -az --delete \
 --filter 'merge base-package.rules' \
 -e ssh jturner@sphere.telascience.org:/home/jturner/fgdata .

tar cjf output/FlightGear-$VERSION-data.tar.bz2 fgdata/

