#!/usr/bin/python

# gencoastline.py - create appropriate COASTLINE_LIST STG files for ws30 from openstreetmap
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
    print("Simple generation of COASTLINE_LIST files")
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

def feature_file(lat, lon):
    index = calc_tile.calc_tile_index((lon,lat))
    return str(index) + "_Coastline.txt"

def add_to_stg(lat, lon):
    index = calc_tile.calc_tile_index((lon, lat))
    stg = os.path.join(scenery_prefix, calc_tile.directory_name((lon, lat)), str(index) + ".stg")
    #print("Writing " + stg)
    with open(stg, 'a') as f:
        f.write("COASTLINE_LIST " + feature_file(lat, lon) + "\n")

def write_feature(lon, lat, coast):
    index = calc_tile.calc_tile_index((lon,lat))
    dirname = os.path.join(scenery_prefix, calc_tile.directory_name((lon, lat)))
    os.makedirs(dirname, exist_ok=True)
    txt = os.path.join(scenery_prefix, calc_tile.directory_name((lon, lat)), feature_file(lat, lon))
    #print("Writing " + txt)
    with open(txt, 'a') as f:
        for pt in coast :
            f.write(" "  + str(pt.lon) + " " + str(pt.lat))
        f.write("\n")

    stg = os.path.join(scenery_prefix, calc_tile.directory_name((lon, lat)), str(index) + ".stg")
    if not os.path.isfile(stg) :
        # No STG - generate
        add_to_stg(lat, lon)
    else :
        road_exists = 0
        with open(stg, 'r') as f:
            for line in f:
                if line.startswith("COASTLINE_LIST " + feature_file(lat, lon)) :
                    road_exists = 1
        if road_exists == 0 :
            add_to_stg(lat, lon)


def parse_way(way) :
    global road_count, river_count, lat1, lon1, lat2, lon2
    pts = []    
    width = 6.0
    road = 0    
    river = 0

    # It's a road or river.  Add it to appropriate tile entries.
    tileids = set()

    for pt in way.nodes:
        lon = float(pt.lon)
        lat = float(pt.lat)
        idx = calc_tile.calc_tile_index([lon, lat])
        if ((float(lon1) <= lon <= float(lon2)) and (float(lat1) <= lat <= float(lat2)) and (idx not in tileids)) :
            # Write the feature to a bucket provided it's within the lat/lon bounds and if we've not already written it there
            write_feature(lon, lat, way.nodes)
            tileids.add(idx)

def writeOSM(result):
        for child in result.ways:
            parse_way(child)

# Get River data

osm_bbox = ",".join([lat1, lon1, lat2, lon2])
api = overpy.Overpass(url="https://lz4.overpass-api.de/api/interpreter")

coast_query = "way[\"natural\"=\"coastline\"](" + osm_bbox + ");(._;>;);out;"
result = api.query(coast_query)
writeOSM(result)


