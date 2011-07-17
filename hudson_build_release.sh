#!/bin/sh


pushd simgear

SG_VERSION=$(cat version)

./autogen.sh
./configure --prefix=$WORKSPACE/dist --with-osg=$WORKSPACE/dist

make

if [ $? -ne '0' ]; then
    echo "make simgear failed"
    exit 1
fi

make install
make dist

echo "Starting on FlightGear"

popd
pushd flightgear

FG_VERSION=$(cat version)

./autogen.sh
./configure --prefix=$WORKSPACE/dist --with-osg=$WORKSPACE/dist
make

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

make install
make dist

popd

# create output directory, suitable for archiving / uploading
rm -rf output
mkdir -p output/${FG_VERSION}
mv simgear/simgear-${SG_VERSION}.tar.bz2 output/${FG_VERSION}/
mv flightgear/flightgear-${FG_VERSION}.tar.bz2 output/${FG_VERSION}/

