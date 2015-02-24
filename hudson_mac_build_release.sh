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
xcodebuild -configuration RelWithDebInfo -target install  build

if [ $? -ne '0' ]; then
    echo "make simgear failed"
    exit 1
fi

popd

################################################################################
echo "Starting on FlightGear"
pushd fgBuild
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist -G Xcode ../flightgear

xcodebuild -configuration RelWithDebInfo -target install  build

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

popd

chmod +x $WORKSPACE/dist/bin/osgversion


################################################################################
echo "Syncing base packages files from sphere.telascience.org"
rsync -avz --filter 'merge base-package.rules' \
 -e ssh jturner@sphere.telascience.org:/home/jturner/fgdata .

# run the unlock script now - we need to do this right before code-signing,
# or the keychain may automatically re-lock after some period of time
unlock-keychain.sh

echo "Running package script"
./hudson_mac_package_release.rb
