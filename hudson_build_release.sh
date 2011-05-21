#!/bin/sh

cd simgear
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

cd ../flightgear
./autogen.sh
./configure --prefix=$WORKSPACE/dist --with-osg=$WORKSPACE/dist
make

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

make install
make dist
