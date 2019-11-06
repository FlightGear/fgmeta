#!/bin/bash
#
# Create the scenery pack for a release distribution
# Make sure to 
# * set SCENERY and point it to your local (full) mirror of terrasync scenery
# * name the SCENERY_PACK correctly
# * carefully select the tiles to copy, usually 2x2, 2x3 or 3x2 keeps the pack small enough
#
SCENERY=/path/to/your/scenery
SCENERY_PACK=SceneryPack.PHNL
TILES="w160n[12]0/w???n??"

if [ ! -d "$SCENERY" ]; then
  echo "Scenery directory not found or not readable"
  exit 1
fi

if [ ! -d "$SCENERY"/Objects -o ! -d  "$SCENERY"/Terrain -o ! -d  "$SCENERY"/Airports -o ! -d  "$SCENERY"/Models ]; then
  echo "Scenery directory does not look like a scenery directory"
  exit 1
fi

rm -f SceneryPack.*.tgz
ln -s "$SCENERY" ${SCENERY_PACK}
tar --format=gnu --create --owner=root --group=root --gzip --exclude="**/.dirindex" --file=${SCENERY_PACK}.tgz ${SCENERY_PACK}/Objects/${TILES} ${SCENERY_PACK}/Terrain/${TILES} ${SCENERY_PACK}/Airports ${SCENERY_PACK}/Models
rm ${SCENERY_PACK}
