#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Must supply FlightGear version as an argument, eg 3.5.2"
    exit
fi

FG_VERSION = $1
SF_FRS_PATH = "jmturner@frs.sourceforge.net:/home/frs/project/f/fl/flightgear/unstable/"

echo "Running Mac upload post-processing steps"

cd /var/www/html/builds/nightly

# first, remove any existing DMG binaries
rm FlightGear-*.dmg

# move newly upload files
mv $HOME/nightly-incoming/FlightGear-$FG_VERSION-nightly.dmg .
mv $HOME/nightly-incoming/FlightGear-$FG_VERSION-nightly-full.dmg .

# rsync to SourceForge
rsync -avP -e ssh FlightGear-$FG_VERSION-nightly.dmg $SF_FRS_PATH
rsync -avP -e ssh FlightGear-$FG_VERSION-nightly-full.dmg $SF_FRS_PATH

