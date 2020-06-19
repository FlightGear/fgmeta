Introduction
============

This is the directory containing the script for updating aircraft, or other
craft, catalogs.  It will create the `catalog.xml` file used to add a hangar to
FlightGear, as well as the zip archives of each craft in the hangar and the
md5sums, thumbnails, and previews of these.  It consists of the script:

* update-catalog.py

And its Python modules:

* catalog.py
* catalogTags.py
* sgprogs.py


Usage
=====

The script can be run directly from this directory, or the script and its
modules can be copied together and run from any location.  The steps to use
these are:

* Have something like `export PYTHONPATH="/path/to/fgmeta/python3-flightgear"`
  in your shell setup or use a .pth file (see `python3-flightgear/README.md`
  for more details).
* Create an output directory where the catalog and zip files will be located.
* Copy the configuration files `catalog.config.xml`, `template.xml`, and
  `zip-excludes.lst` from one of the `*catalog*` example directories into the
  output directory.
* Modify these files as required.

Then run the script with:

`$ $FGMETA/catalog/update-catalog.py dir`

where `dir` is the output directory.  The script will create the following
files:

* `md5sum.xml`:  A file containing checksums of all craft zip archives in the
  base output directory.
* `ftp/catalog.xml`:  The XML catalog to upload to a server and advertise to
  FlightGear users.
* `ftp/*.zip`:  The zip archives of each craft in the hangar.
* `ftp/previews/*_Splashs/`:  A directory per craft containing the splash screen
  graphics.
* `ftp/thumbnails/`:  The collection of thumbnail graphics for the hangar.

The `ftp` directory is to be uploaded to a server which can be configured via
the `catalog.config.xml` file.


Examples
========

A number of example configuration files are located in this directory.  These
include:

* `fgaddon-catalog/`:  The configuration files used for the [official FGAddon
  hangar](http://wiki.flightgear.org/FGAddon).
* `stable-2018-catalog/':  The configuration files used for the 2018 long term
  stability release.
* `single-craft-catalog-test/`:  Configuration files used for testing the
  catalog and zip archive creation for a single craft.  These are for content
  developers to test their craft.
