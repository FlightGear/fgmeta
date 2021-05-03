#!/usr/bin/python

# genroads.py - create appropriate ROAD_LIST STG files for ws30 from openstreetmap
# Copyright (C) 2021  Stuart Buchanan
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


# You will need Python Overpass API - "pip install overpy"

import xml.etree.ElementTree as etree
import os
import shutil
import re
import sys
import collections
from math import floor

import calc_tile
import overpy

nodes = {}
road_count = 0
river_count = 0

if (len(sys.argv) != 6):
    print("Simple generation of ROAD_LIST files")
    print("")
    print("Usage: " + sys.argv[0] + " <scenery_dir> <lon1> <lat1> <lon2> <lat2>")
    print("  <scenery_dir>  \tScenery directory to write to")
    print("  <lon1> <lat1>  \tBottom left lon/lat of bounding box")
    print("  <lon2> <lat2>  \tTop right lon/lat of bounding box")
    exit(1)

scenery_prefix = sys.argv[1]
lon1 = sys.argv[2]
lat1 = sys.argv[3]
lon2 = sys.argv[4]
lat2 = sys.argv[5]

os.makedirs(scenery_prefix, exist_ok=True)

def feature_file(lat, lon, type):
    index = calc_tile.calc_tile_index((lon,lat))
    return str(index) + "_" + type + ".txt"

def add_to_stg(lat, lon, type):
    index = calc_tile.calc_tile_index((lon, lat))
    stg = os.path.join(scenery_prefix, calc_tile.directory_name((lon, lat)), str(index) + ".stg")
    #print("Writing " + stg)
    with open(stg, 'a') as f:
        f.write("LINE_FEATURE_LIST " + feature_file(lat, lon, type) + " " + type + "\n")

def write_feature(lon, lat, road, type, width):
    index = calc_tile.calc_tile_index((lon,lat))
    dirname = os.path.join(scenery_prefix, calc_tile.directory_name((lon, lat)))
    os.makedirs(dirname, exist_ok=True)
    txt = os.path.join(scenery_prefix, calc_tile.directory_name((lon, lat)), feature_file(lat, lon, type))
    #print("Writing " + txt)
    with open(txt, 'a') as f:
        f.write(str(width) + " 0 1 1 1 1") # Width plus currently unused generic attributes.
        for pt in road :
            f.write(" "  + str(pt.lon) + " " + str(pt.lat))
        f.write("\n")

    stg = os.path.join(scenery_prefix, calc_tile.directory_name((lon, lat)), str(index) + ".stg")
    if not os.path.isfile(stg) :
        # No STG - generate
        add_to_stg(lat, lon, type)
    else :
        road_exists = 0
        with open(stg, 'r') as f:
            for line in f:
                if line.startswith("LINE_FEATURE_LIST " + feature_file(lat, lon, type)) :
                    road_exists = 1
        if road_exists == 0 :
            add_to_stg(lat, lon, type)


def parse_way(way) :
    global road_count, river_count, lat1, lon1, lat2, lon2
    pts = []    
    width = 6.0
    road = 0    
    river = 0

    highway = way.tags.get("highway")
    waterway = way.tags.get("waterway")
    feature_type = "None"

    if (highway=="motorway_junction") or (highway=="motorway") or (highway=="motorway_link"):
        width = 15.0
        feature_type = "Road"
        road_count = road_count + 1

    if (highway=="secondary") or (highway=="primary")  or (highway=="trunk") or (highway=="trunk_link") or (highway=="primary_link") or (highway=="secondary_link") :
        width = 12.0
        feature_type = "Road"
        road_count = road_count + 1

    if (highway=="unclassified") or (highway=="tertiary") or (highway=="tertiary_link") or (highway=="service") or (highway=="residential"):
        width = 6.0
        feature_type = "Road"
        road_count = road_count + 1
    if (waterway=="river") or (waterway=="canal") :
        width = 10.0
        feature_type = "Watercourse"
        river_count = river_count + 1

    # Use the width if defined and parseable
    if (way.tags.get("width") != None) :
        width_str = way.tags.get("width")
        try:
            if (' m' in width_str) :
                width = float(width_str[0:width_str.find(" m")])
            if (' ft' in width_str) :
                width = 0.3 * float(width_str[0:width_str.find(" ft")])
        except ValueError :
            print("Unable to parse width " + width_str)

    if (feature_type != "None") :       
        # It's a road or river.  Add it to appropriate tile entries.
        tileids = set()

        for pt in way.nodes:
            lon = float(pt.lon)
            lat = float(pt.lat)
            idx = calc_tile.calc_tile_index([lon, lat])
            if ((float(lon1) <= lon <= float(lon2)) and (float(lat1) <= lat <= float(lat2)) and (idx not in tileids)) :
                # Write the feature to a bucket provided it's within the lat/lon bounds and if we've not already written it there
                write_feature(lon, lat, way.nodes, feature_type, width)
                tileids.add(idx)

def writeOSM(result):
        for child in result.ways:
            parse_way(child)

# Get River data

osm_bbox = ",".join([lat1, lon1, lat2, lon2])
api = overpy.Overpass(url="https://lz4.overpass-api.de/api/interpreter")

river_query = "(way[\"waterway\"=\"river\"](" + osm_bbox + "); way[\"waterway\"=\"canal\"](" + osm_bbox + "););(._;>;);out;"
result = api.query(river_query)
writeOSM(result)

road_query = "("
#road_types = ["unclassified", "tertiary", "service", "secondary", "primary", "motorway_junction", "motorway"]
#road_types = ["tertiary", "secondary", "primary", "motorway_junction", "motorway"]
road_types = ["motorway", "trunk", "primary", "secondary", "tertiary", "unclassified", "residential", "motorway_link", "trunk_link", "primary_link", "secondary_link", "tertiary_link"]
for r in road_types :
    road_query = road_query + "way[\"highway\"=\"" + r + "\"](" + osm_bbox + ");"

road_query = road_query + ");(._;>;);out;"
result = api.query(road_query)
writeOSM(result)

print("Wrote total of " + str(road_count) + " roads")
print("Wrote total of " + str(river_count) + " rivers")


#
#
#
#
#time ./genroads.py /tmp/OSMTEST/Terrain/ -3.5 55.0 -2.5 56.0
#2005  time ./genroads.py /tmp/OSMTEST/Terrain/ -12 59.0 -10 61.0
# 2006  time ./genroads.py /tmp/OSMTEST/Terrain/ -10 59.0 -8 61.0
# 2007  time ./genroads.py /tmp/OSMTEST/Terrain/ -8 59.0 -4 61.0
# 2008  time ./genroads.py /tmp/OSMTEST/Terrain/ -4 59.0 0 61.0
# 2009  time ./genroads.py /tmp/OSMTEST/Terrain/ 0 59.0 4 61.0
# 2010  time ./genroads.py /tmp/OSMTEST/Terrain/ -12 57.0 -10 59.0
# 2011  time ./genroads.py /tmp/OSMTEST/Terrain/ -10 57.0 -6 59.0
# 2012  time ./genroads.py /tmp/OSMTEST/Terrain/ -6 57.0 -2 59.0
# 2013  time ./genroads.py /tmp/OSMTEST/Terrain/ -2 57.0 4 59.0
