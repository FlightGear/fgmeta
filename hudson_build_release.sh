#!/bin/sh

cd simgear
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist

# first make source package (clean directory), finally compile
make package_source
make

if [ $? -ne '0' ]; then
    echo "make simgear failed"
    exit 1
fi

make install

echo "Starting on FlightGear"

cd ../flightgear
cmake -DCMAKE_INSTALL_PREFIX:PATH=$WORKSPACE/dist

# first source package (clean directory), finally compile
make package_source
make

if [ $? -ne '0' ]; then
    echo "make flightgear failed"
    exit 1
fi

make install

