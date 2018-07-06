## Test Scenery Project
An example to demostrate the usage of the TerraGear Scenery tools.  By studying this example, you should gain a better understanding of the tool workflow.
Copyright (C) 2018  Scott Giese (xDraconian) scttgs0@gmail.com

### Purpose:
Most users could benefit from the availability of a reference example to gain a working understanding of scenery generation.  I am hopeful you gain value from this example and i would like to see this lead toward encouraging more Windows users to get involved in contributing to scenery development.

### Supported Platform:
Windows 10

### Prerequisites:
	SimGear
    TerraGear

### Installation Instructions:

None

### Usage:
Below is an explaination of the files provided:

| File | Description |
|-----:|------------|
|**generate.cmd** | A command script containing calls to the various TerraGear tools to produce scenery for Oahu |
|**test.apt.dat** | Contains all airport data for those located on Oahu |
|**/data** | Folder containing files you provide to the TerraGear tools |
|**/data/SRTM-3** | Terrain data for Oahu |
|**/data/fg_* ** | Shapefiles.  These define the type of terrain (grass, lake, forest, etc.) - Items typically defined by a polygon area |
|**/data/osm_* ** | OpenStreetMap files.  These represent roadways, rivers, etc. - Items typically defined by "lines" |
| **/work** | Files produced by the TerraGear tools |
| **/output** | Final resulting files.  These are the scenery files that will be loaded into FlightGear |

Run the command script interactively.  No log is produced.

	generate.cmd

Runs the command script and routes STDOUT and STDERR to a log file. You will miss the prompts, so it is important that you monitor the log while it is running.

	generate.cmd > generate.log 2>&1

Options for monitoring the log file while the script is running:
Start the script and then
- Load the log file into Notepad++ (https://notepad-plus-plus.org/).
 - Turn on feature "Monitor" via Notepad++
- **[Preferred]** Load the log file into WinTail (http://www.baremetalsoft.com/wintail/)

### Testing the Scenery:

Configure fgfs or the Flightgear Launcher to look in **/CustomSeneryProjects/Test/output** for additional scenery files.
Choose as a starting location from any of the airports present on Oahu (e.g. PHNL or PHNG.)

Note: You will find that all the buildings, radio towers, smoke stacks, etc. are missing.  This is expected since your *output* folder doesn't contain any of these items.

### Known Issues:

There is a bug in the toolchain that prevents the airport BTG files from being copied to the */output* folder. You will need to copy these files manually until the issue is resolved. Copy the files you find in the */work/AirportObj* folder to your */output* folder.