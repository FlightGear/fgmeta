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

# this shoudl not be needed, since this is inside CMAKE_INSTALL_PREFIX, but seemed
# to be necessary all the same
#export PKG_CONFIG_PATH=$WORKSPACE/dist/lib/pkgconfig

cmakeCommonArgs="-DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist -DCMAKE_BUILD_TYPE=RelWithDebInfo"

###############################################################################
echo "Starting on SimGear"
pushd sgBuild
cmake ${cmakeCommonArgs} ../simgear

# compile
cmake --build . --target debug_symbols
cmake --build . --target install

if [ $? -ne '0' ]; then
    echo "make simgear failed"
    exit 1
fi

popd

################################################################################
echo "Starting on FlightGear"
pushd fgBuild

if [ $FG_IS_RELEASE == '1' ]; then
  FGBUILDTYPE=Release
else
  FGBUILDTYPE=Nightly
fi

cmake -DFG_BUILD_TYPE=$FGBUILDTYPE -DENABLE_SWIFT:BOOL=ON ${cmakeCommonArgs} ../flightgear

cmake --build . --target debug_symbols
cmake --build . --target install

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

popd

chmod +x $WORKSPACE/dist/bin/osgversion

echo "Running symbol upload script"
./sentry-dSYM-upload-mac.sh

################################################################################

# run the unlock script now - we need to do this right before code-signing,
# or the keychain may automatically re-lock after some period of time
unlock-keychain.sh

echo "Running package script"
./hudson_mac_package_release.rb
