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

PATH=$PATH:$QTPATH
echo "Build path is: $PATH"

###############################################################################
echo "Starting on SimGear"
pushd sgBuild
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist -DCMAKE_BUILD_TYPE=RelWithDebInfo ../simgear

# compile
make

if [ $? -ne '0' ]; then
    echo "make simgear failed"
    exit 1
fi

make install


popd

################################################################################
echo "Starting on FlightGear"
pushd fgBuild

if [ $FG_IS_RELEASE == '1' ]; then
  FGBUILDTYPE=Release
else
  FGBUILDTYPE=Nightly
fi

cmake -DFG_BUILD_TYPE=$FGBUILDTYPE -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist -DCMAKE_BUILD_TYPE=RelWithDebInfo ../flightgear

make

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

make install

popd

chmod +x $WORKSPACE/dist/bin/osgversion


################################################################################

# run the unlock script now - we need to do this right before code-signing,
# or the keychain may automatically re-lock after some period of time
unlock-keychain.sh

echo "Running package script"
./hudson_mac_package_release.rb
