#!/usr/bin/python

import argparse
import os
import sgprops

def check_meta_data(aircraft_dir, set_file, includes):
    base_file = os.path.basename(set_file)
    base_id = base_file[:-8]
    set_path = os.path.join(aircraft_dir, set_file)

    includes.append(aircraft_dir)
    root_node = sgprops.readProps(set_path, includePaths = includes)

    if not root_node.hasChild("sim"):
        print "-set.xml has no <sim> node:", set_path
        return

    sim_node = root_node.getChild("sim")
    if not sim_node.hasChild('description'):
        print "-set.xml missing <description>:", set_path

    if not sim_node.hasChild('long-description'):
        print "-set.xml missing <long-description>:", set_path

    if not sim_node.hasChild('authors'):
        print "-set.xml is missing structured <authors> data:", set_path

    if not sim_node.hasChild('tags'):
        print "-set.xml does not define any tags", set_path

    # check for non-standard tags

    if not sim_node.hasChild('thumbnail'):
        print "-set.xml does not define a thumbnail", set_path

    # check thumbnail size and format

    if not sim_node.hasChild('rating'):
        print "-set.xml does not define any ratings", set_path

    if not sim_node.hasChild('minimum-fg-version'):
        print "-set.xml does not define a minimum FG version", set_path

# check all the -set.xml files in an aircraft directory.  
def check_aircraft_dir(d, includes):
    if not os.path.isdir(d):
        return

    files = os.listdir(d)
    for file in sorted(files, key=lambda s: s.lower()):
        if file.endswith('-set.xml'):
            check_meta_data(d, file, includes)

parser = argparse.ArgumentParser()
parser.add_argument("--include", help="Include directory to validate -set.xml parsing",
                    action="append", dest='include', default=[])
parser.add_argument("dir", nargs='+', help="Aircraft directory")
args = parser.parse_args()

for d in args.dir:
    if not os.path.isdir(d):
        print "Skipping missing directory:", d

    names = os.listdir(d)
    for name in sorted(names, key=lambda s: s.lower()):
        # if name in skip_list:
        #     print "skipping:", name
        #     continue

        acftDir = os.path.join(d, name)
        check_aircraft_dir(acftDir, args.include)
    