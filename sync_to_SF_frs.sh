#!/bin/sh

versionMajor=2018.3
patchLevel=6

version=$versionMajor.$patchLevel

echo "Moving RC for $version to SourceForge FRS"

server=jmturner@frs.sourceforge.net
destination=/home/frs/project/f/fl/flightgear
source=/var/www/html/builds/rc
localDest=/var/www/html/builds/$versionMajor

scp $source/FlightGear-$version-rc.dmg $server:$destination/release-$versionMajor/FlightGear-$version.dmg
scp $source/FlightGear-$version-rc.exe $server:$destination/release-$versionMajor/FlightGear-$version.exe

scp $source/flightgear-$version-rc.tar.bz2 $server:$destination/release-$versionMajor/flightgear-$version.tar.bz2
scp $source/simgear-$version-rc.tar.bz2 $server:$destination/release-$versionMajor/simgear-$version.tar.bz2
scp $source/FlightGear-$version-data-rc.tar.bz2 $server:$destination/release-$versionMajor/FlightGear-$version-data.tar.bz2

cp $source/FlightGear-$version-rc.dmg $localDest/FlightGear-$version.dmg
cp $source/FlightGear-$version-rc.exe $localDest/FlightGear-$version.exe

cp $source/flightgear-$version-rc.tar.bz2 $localDest/flightgear-$version.tar.bz2
cp $source/simgear-$version-rc.tar.bz2 $localDest/simgear-$version.tar.bz2
cp $source/FlightGear-$version-data-rc.tar.bz2 $localDest/FlightGear-$version-data.tar.bz2

echo "All done"
