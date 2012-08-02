#!/bin/sh

if [ "$WORKSPACE" == "" ]; then
    echo "ERROR: Missing WORKSPACE environment variable."
    exit 1
fi

###############################################################################
# remove old and create fresh build directories
rm -rf sgBuild
rm -rf fgBuild
mkdir -p sgBuild
mkdir -p fgBuild
mkdir -p output
rm -rf output/*
rm -rf $WORKSPACE/dist/include/simgear $WORKSPACE/dist/libSim* $WORKSPACE/dist/libsg*.a

###############################################################################
echo "Starting on SimGear"
pushd sgBuild
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist -G Xcode ../simgear

# compile
xcodebuild -configuration Release -target install  build

if [ $? -ne '0' ]; then
    echo "make simgear failed"
    exit 1
fi

popd

################################################################################
echo "Starting on FlightGear"
pushd fgBuild
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist -G Xcode ../flightgear

xcodebuild -configuration Release -target install  build

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

popd

chmod +x $WORKSPACE/dist/bin/osgversion

################################################################################
echo "Building Macflightgear launcher"

SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk"
OSX_TARGET="10.7"

pushd maclauncher/FlightGearOSX

# compile the stub executable
gcc -o FlightGear -mmacosx-version-min=$OSX_TARGET -isysroot $SDK_PATH -arch i386 main.m \
    -framework Cocoa -framework RubyCocoa -framework Foundation -framework AppKit

popd

################################################################################
echo "Syncing base packages files from sphere.telascience.org"
rsync -avz --filter 'merge base-package.rules' \
 -e ssh jturner@sphere.telascience.org:/home/jturner/fgdata .

echo "Running package script"
./hudson_mac_package_release.rb
