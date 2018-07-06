@ECHO OFF

set PATH=%CD%/../../Stage/bin;%CD%/../../vcpkg-git/installed/x64-windows/bin
set GDAL_DATA=%CD%/../../vcpkg-git/installed/x64-windows/share/gdal
set PRIORITIES_FILE=%CD%/../../Stage/share/TerraGear/default_priorities.txt
set USGS_MAP_FILE=%CD%/../../Stage/share/TerraGear/usgsmap.txt

echo === hgtchop =====================================================================
hgtchop 3 data/SRTM-3/N21W158.hgt work/SRTM-3
hgtchop 3 data/SRTM-3/N21W159.hgt work/SRTM-3

echo === terrafit ====================================================================
terrafit --minnodes 50 --maxnodes 20000 --maxerror 5 work/SRTM-3

echo === genapt850 ===================================================================
genapts850 --input=test.apt.dat --work=work --min-lon=-158.423 --max-lon=-157.544 --min-lat=21.064 --max-lat=21.8003 --log-level=info

echo === ogr-decode ==================================================================
ogr-decode --line-width 12 --continue-on-errors --all-threads --area-type Road        work/Road        data/osm_Road
ogr-decode --line-width 15 --continue-on-errors --all-threads --area-type Freeway     work/Freeway     data/osm_Freeway
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Railroad    work/Railroad    data/fg_Railroad
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Canal       work/Canal       data/osm_Canal
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Canal       work/Canal2      data/fg_Canal
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Stream      work/Stream      data/osm_Stream
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Stream      work/Stream2     data/fg_Stream
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Marsh       work/Marsh       data/fg_Marsh
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Lake        work/Lake        data/fg_Lake
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Sand        work/Sand        data/fg_Sand
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Lava        work/Lava        data/fg_Lava
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Dirt        work/Dirt        data/fg_Dirt
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type GolfCourse  work/GolfCourse  data/fg_GolfCourse
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type MixedCrop   work/MixedCrop   data/fg_MixedCrop
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Grassland   work/Grassland   data/fg_Grassland
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type MixedForest work/MixedForest data/fg_MixedForest
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Cemetery    work/Cemetery    data/fg_Cemetery
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Asphalt     work/Asphalt     data/fg_Asphalt
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Airport     work/Airport     data/fg_Airport
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Town        work/Town        data/fg_Town
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Industrial  work/Industrial  data/fg_Industrial
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Urban       work/Urban       data/fg_Urban
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Scrub       work/Scrub       data/fg_Scrub
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Scrub       work/Default     data/fg_Default
ogr-decode --line-width 10 --continue-on-errors --all-threads --area-type Ocean       work/Ocean       data/fg_Ocean

echo === tg-construct ================================================================
tg-construct --priorities=%PRIORITIES_FILE% --usgs-map=%USGS_MAP_FILE% --work-dir=work --output-dir=output/Terrain --ignore-landmass --min-lon=-158.423 --max-lon=-157.544 --min-lat=21.064 --max-lat=21.8003 Airport AirportArea AirportObj Asphalt Canal Canal2 Cemetery Dirt Freeway GolfCourse Grassland Industrial Lake Lava Marsh MixedCrop MixedForest Ocean Railroad Road Sand Scrub Stream Stream2 Town Urban Default SRTM-3
