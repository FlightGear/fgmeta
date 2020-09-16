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

echo "Assembling base package"
cd $WORKSPACE

tar cjf output/FlightGear-$VERSION-data.tar.bz2 fgdata/
