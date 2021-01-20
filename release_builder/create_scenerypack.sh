#!/bin/bash

# the name to create
SCENERY_PACK=SceneryPack.BIKF

# the tiles to select
TILES="w030n60/w???n??";

# tiles for PHNL for C172 tutorials
TUTORIAL_TILES="w160n[12]0/w???n??";

rm -f SceneryPack.*.tgz

# note the path to the TerraSync root here
ln -s /var/www/uk-mirror/fgscenery ${SCENERY_PACK}

tar --format=gnu --create --owner=root --group=root --gzip --file=${SCENERY_PACK}.tgz \
    ${SCENERY_PACK}/Objects/${TILES} \
    ${SCENERY_PACK}/Terrain/${TILES} \
    ${SCENERY_PACK}/Objects/${TUTORIAL_TILES} \
    ${SCENERY_PACK}/Terrain/${TUTORIAL_TILES} \
    ${SCENERY_PACK}/Airports/B/I/K \
    ${SCENERY_PACK}/Airports/P/H \
    ${SCENERY_PACK}/Airports_archive.tgz \
    ${SCENERY_PACK}/Models

rm ${SCENERY_PACK}

# upload to frs.sourceforge.net /home/frs/project/fl/flightgear/scenery/ 

