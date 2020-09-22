#!/bin/sh

if [ "$WORKSPACE" == "" ]; then
    echo "ERROR: Missing WORKSPACE environment variable."
    exit 1
fi

cmakeGenerator=Ninja
cmakeCommonArgs="-DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist -DCMAKE_BUILD_TYPE=RelWithDebInfo"
VERSION=`cat flightgear/flightgear-version`

#####################################################################################
# ensure fgrcc can run when linked against libSimGearCore, for example
export LD_LIBRARY_PATH=$WORKSPACE/dist/lib64:$WORKSPACE/dist/lib:$LD_LIBRARY_PATH

#####################################################################################
# remove old and create fresh build directories
cd $WORKSPACE
mkdir -p sgBuild
mkdir -p fgBuild
mkdir -p output
rm -rf output/*

#####################################################################################
echo "Starting on SimGear"
cd sgBuild
cmake -G $cmakeGenerator $cmakeCommonArgs ../simgear

# compile
ninja

if [ $? -ne '0' ]; then
    echo "make simgear failed"
    exit 1
fi

ninja install

# build source package and copy to output
ninja package_source
cp simgear-*.tar.bz2 ../output/.

#####################################################################################
echo "Starting on FlightGear"
cd ../fgBuild
cmake -G $cmakeGenerator $cmakeCommonArgs -DENABLE_SWIFT:BOOL=ON -DFG_BUILD_TYPE=Release ../flightgear

# compile
ninja

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

ninja install

# build source package and copy to output
ninja package_source
cp flightgear-*.tar.bz2 ../output/.

#####################################################################################

if which sentry-cli >/dev/null; then
    echo "Uploading symbols"

    export SENTRY_ORG=flightgear
    export SENTRY_PROJECT=flightgear
    
    # set in the Jenkins environment for the builder
  #  export SENTRY_AUTH_TOKEN=YOUR_AUTH_TOKEN

    ERROR=$(sentry-cli upload-dif --include-sources "$WORKSPACE/dist/bin/fgfs" 2>&1 >/dev/null)
    if [ ! $? -eq 0 ]; then
        echo "warning: sentry-cli - $ERROR"
    fi
else
    echo "warning: sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases"
fi

# now we uploaded symnbols, strip the binary
strip $WORKSPACE/dist/bin/fgfs

#####################################################################################

echo "Assembling base package"
cd $WORKSPACE

tar cjf output/FlightGear-$VERSION-data.tar.bz2 fgdata/
