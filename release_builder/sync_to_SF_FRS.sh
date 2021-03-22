#!/bin/bash

# TODO: detect this some smarter way (or make it an arg?)
versionMajor=2020.3
patchLevel=7

version=$versionMajor.$patchLevel

echo "Moving RC for $version to SourceForge FRS"

server=jmturner@frs.sourceforge.net
destination=/home/frs/project/f/fl/flightgear
source=/var/www/downloads/builds/rc
localDest=/var/www/downloads/builds/$versionMajor

mkdir -p $localDest

scp $source/FlightGear-$version-rc.dmg $server:$destination/release-$versionMajor/FlightGear-$version.dmg
scp $source/FlightGear-$version-rc.exe $server:$destination/release-$versionMajor/FlightGear-$version.exe
scp $source/FlightGear-$version-x86_64-rc.AppImage $server:$destination/release-$versionMajor/FlightGear-$version-x86_64.AppImage


scp $source/flightgear-$version-rc.tar.bz2 $server:$destination/release-$versionMajor/flightgear-$version.tar.bz2
scp $source/simgear-$version-rc.tar.bz2 $server:$destination/release-$versionMajor/simgear-$version.tar.bz2
scp $source/FlightGear-$version-data-rc.txz $server:$destination/release-$versionMajor/FlightGear-$version-data.txz
scp $source/FlightGear-$version-update-data-rc.txz $server:$destination/release-$versionMajor/FlightGear-$version-update-data.txz

cp $source/FlightGear-$version-rc.dmg $localDest/FlightGear-$version.dmg
cp $source/FlightGear-$version-rc.exe $localDest/FlightGear-$version.exe
cp $source/FlightGear-$version-x86_64-rc.AppImage $localDest/FlightGear-$version-x86_64.AppImage

cp $source/flightgear-$version-rc.tar.bz2 $localDest/flightgear-$version.tar.bz2
cp $source/simgear-$version-rc.tar.bz2 $localDest/simgear-$version.tar.bz2
cp $source/FlightGear-$version-data-rc.txz $localDest/FlightGear-$version-data.txz
cp $source/FlightGear-$version-update-data-rc.txz $localDest/FlightGear-$version-update-data.txz

echo "All done"
