#!/usr/bin/env python3
#
# Script to summarize changes to fgaddon Aircraft based on svn activity.
#
# Primarily intended to provide a list of aircraft that have been significantly
# updated since the last release for the change log.

import os, sys
import os.path
import re
from collections import defaultdict
import subprocess
import math
import shlex

extensions = ["*", "xml", "nas", "ac", "png", "jpg"]
new_aircraft_list = []
updated_aircraft_list = []

if (len(sys.argv) != 4):
    print("Summarize fgaddon/Aircraft changes in a given branch between two dates.")
    print("")
    print("Usage: " + sys.argv[0] + " <branch> <from> <to>")
    print("  <branch>\tSVN branch to check (e.g trunk, branches/release-2020.3")
    print("  <from>  \tStart date (e.g. 2020-04-27)")
    print("  <to>    \tEnd date (e.g. 2020-10-11")
    exit(1)


branch = sys.argv[1]
from_date = sys.argv[2]
to_date = sys.argv[3]

# Create a format string listing changes to all the file types above
tableformat = "{:<25}{:>4}"
for ext in extensions:
    tableformat = tableformat + "{:>5}"

# Check an individual aircraft for changes since date and output them
def check_aircraft(aircraft):
    # This command lists all the changed files since date for a given aircraft
    svn_log = "svn log https://svn.code.sf.net/p/flightgear/fgaddon/" + branch + "/Aircraft/" + aircraft + " -r {" + from_date + "}:{" + to_date + "} -v -q"
    process = subprocess.Popen(shlex.split(svn_log), stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    stdout, stderr = process.communicate()

    # Now collect some data
    count = []
    for ext in extensions:
        regexp = "  [AM] .*\." + ext + "$"
        count.append(len(re.findall(regexp, stdout, flags=re.MULTILINE)))

    # Find completely new aircraft.
    regexp = "  A /.*/Aircraft/" + aircraft + "$"
    new_aircraft = ""
    if (re.findall(regexp, stdout, flags=re.MULTILINE)):
        new_aircraft = "NEW"
        new_aircraft_list.append(aircraft)
    elif (count[0] > 100) :
        updated_aircraft_list.append(aircraft)

    # Only output if we have more than 100 changes or it's a new aircraft
    if ((count[0] > 100) or (new_aircraft == "NEW")):
        print(tableformat.format(aircraft, new_aircraft, count[0], count[1], count[2], count[3], count[4], count[5]))



svn_list = "svn list https://svn.code.sf.net/p/flightgear/fgaddon/" + branch + "/Aircraft/"
process = subprocess.Popen(shlex.split(svn_list), stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
stdout, stderr = process.communicate()

print(tableformat.format("Aircraft", "New?", extensions[0], extensions[1], extensions[2], extensions[3], extensions[4], extensions[5]))

aircraft_list = re.split("/\n", stdout)
for ac in aircraft_list:
    check_aircraft(ac)

separator = ", "
print("\nNew Aircraft " + separator.join(new_aircraft_list))
print("Update Aircraft " + separator.join(updated_aircraft_list))

print("Total: New aircraft: " + str(len(new_aircraft_list)) + " Updated Aircraft: " + str(len(updated_aircraft_list)));