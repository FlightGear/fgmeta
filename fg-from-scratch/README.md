## fg-from-scratch
Windows utility to download, compile, and stage TerraGear and its dependencies
Copyright (C) 2018-2019  Scott Giese (xDraconian) scttgs0@gmail.com

### Purpose:
Simplify the process of producing a working version of the OSG, SimGear, FlightGear, and TerraGear for Windows users.
If you find this script useful, or not useful, please share your experience with me via a brief email.

### Approach:
Rather than leveraging the popular Win.3rdParty download, this script compiles all dependencies
on your hardware.  This eliminates many of the problems associated with mixed compilation in which
your compiled binary comes into conflict with 3rd-party binaries.

vcpkg is leveraged to download and compile all the dependencies required.

### Supported Platform:
Windows 10

### Prerequisites:
	Visual Studio Community 2017 +
		https://www.visualstudio.com/downloads/
		Include the C++ package which includes the MSVC 19.14 compiler

	CMake 3.11.3 +
		https://cmake.org/download/
		The script assumes the installation folder is c:\Program Files\.

	Qt 5.10.1 +
		https://www.qt.io/download/
		The script assumes the installation folder is C:\Qt\.

	Git 2.17.1 +
		https://git-scm.com/download/win/
		The script assumes the installation folder is reflected on your PATH.

Author's configuration: Visual Studio Community 2019, CMake 3.15.3, Qt 5.13.1, Git  2.18.0

### Recommended:

Before running the script for the first time, set this environment variable:

	setx /m VCPKG_DEFAULT_TRIPLET x64-windows

You can execute the above command via a Command Terminal or via Powershell Admin

### Usage:
The script is intended to be run multiple times. During the first execution, all the packages are downloaded and compiled. Any time the script is executed afterward, the packages will update themselves.

<i>Note: Because failures can occur, the script will continue to download packages even after the first execution.</i>

Run the command script interactively.  No log is produced.

	fg-from-scratch.cmd

Run the command script and routes STDOUT and STDERR to a log file.

	fg-from-scratch.cmd > scratch.log 2>&1

**Fix for the "White Text" issue** - pass either -wt or - -whitetext as an argument:

	fg-from-scratch.cmd -wt > scratch.log 2>&1

The above command will force the usage of James' customized OSG source repo to leverage his workaround.

Options for monitoring the log file while the script is running:
Start the script and then
- Load the log file into Notepad++ (https://notepad-plus-plus.org/).
 - Turn on feature "Monitor" via Notepad++
- **[Preferred]** Load the log file into WinTail (http://www.baremetalsoft.com/wintail/)

### TerraGear Example Project
Refer to CustomSceneryProjects/Test folder for an example of scenery generation.

	generate.cmd > generate.log 2>&1
