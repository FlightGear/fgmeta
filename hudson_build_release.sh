#!/bin/sh

cd simgear
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist

make

if [ $? -ne '0' ]; then
    echo "make simgear failed"
    exit 1
fi

make install
make dist

echo "Starting on FlightGear"

cd ../flightgear
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist
make

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

make install
make dist
