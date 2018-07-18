## fg-from-scratch
Windows utility to download, compile, and stage TerraGear and its dependencies
Copyright (C) 2018  Scott Giese (xDraconian) scttgs0@gmail.com

### Purpose:
Simplify the process of producing a working version of the TerraGear tools for Windows users.
If you find this script useful, or not useful, please share your experience with me via a brief email.

### Approach:
Rather than leveraging the popular Win.3rdParty download, this script compiles all dependencies
on your hardware.  This eliminates many of the problems associated with mixed compilation in which
your compiled binary become in conflict with 3rd-party binaries.

vcpkg is leveraged to download and compile all the dependencies required by TerraGear.

This script could be expanded to include compiling FlightGear and/or any of the other FlightGear
submodules (FGCom, Atlas, OpenRadar, etc.)

### Supported Platform:
Windows 10

### Prerequisites:
	Visual Studio Community 2017
		https://www.visualstudio.com/downloads/
		Include the C++ package which includes the MSVC 19.14 compiler

	CMake 3.11.3
		https://cmake.org/download/
		The script assumes the installation folder is c:\Program Files\.

	Qt 5.10.1
		https://www.qt.io/download/
		The script assumes the installation folder is C:\Qt\Qt5\.

	Git 2.17.1
		https://git-scm.com/download/win/
		The script assumes the installation folder is reflected on your PATH.

### Recommended:

Before running the script for the first time, set this environment variable:

	setx /m VCPKG_DEFAULT_TRIPLET x64-windows

You can execute the above command via a Command Terminal or via Powershell Admin

### Usage:
The script is intended to be run multiple times. During the first execution, all the packages are downloaded and compiled. Any time the script is executed afterward, the packages will update themselves.

<i>Note: Because failures can sometimes occur, the script will download packages after the first execution.  Once you confirm that all packages have successfully been downloaded, you can optimize the script by adding <b>REM</b> at the beginning of the line. Refer to the comments within the script.</i>

Run the command script interactively.  No log is produced.

	fg-from-scratch.cmd

Runs the command script and routes STDOUT and STDERR to a log file. **The prompts have been removed, so it is no longer necessary to monitor the log while it is running.**

	fg-from-scratch.cmd > scratch.log 2>&1

Options for monitoring the log file while the script is running:
Start the script and then
- Load the log file into Notepad++ (https://notepad-plus-plus.org/).
 - Turn on feature "Monitor" via Notepad++
- **[Preferred]** Load the log file into WinTail (http://www.baremetalsoft.com/wintail/)

### Example Project
Refer to CustomSceneryProjects/Test folder for an example of scenery generation.

	generate.cmd > generate.log 2>&1
