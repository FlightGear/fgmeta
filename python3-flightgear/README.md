Python code for FlightGear “meta” work
======================================

The `flightgear` directory contains FlightGear-specific Python 3 modules.
These modules are mostly of interest to FlightGear developers.


Telling your Python interpreter how to access the modules
---------------------------------------------------------

In order to run most of the Python scripts in FGMeta, your Python 3
installation must have the `/path/to/fgmeta/python3-flightgear` directory in
its `sys.path`. One way to do this is to use something like the following in
your shell setup:

    export PYTHONPATH="/path/to/fgmeta/python3-flightgear"

This example uses Bourne-style syntax; adjust for your particular shell.
Several directories may be added this way using a colon separator on Unix, and
presumably a semicolon on Windows.

An alternative to setting `PYTHONPATH` is to add .pth files in special
directories of your Python installation(s). For instance, you can create a
file, say, `FlightGear-FGMeta.pth`, containing a single line (with no space at
the beginning):

    /path/to/fgmeta/python3-flightgear

If you want the modules present in `/path/to/fgmeta/python3-flightgear` to be
accessible to a particular Python interpreter (say, a Python 3.8), simply put
the `.pth` file in `/path/to/python-install-dir/lib/python3.8/site-packages/`.
This can even be a virtual environment if you want. For the system Python
interpreters on Debian, you can put the `.pth` file in, e.g,
`/usr/local/lib/python3.8/dist-packages/`. Note that you may add more lines to
a `.pth` file in case you want to add other paths to the Python interpreter's
`sys.path`.


The scripts
-----------

Once you've done the above setup, the Python 3 scripts in FGMeta should run
fine. This concerns in particular scripts located in the following top-level
directories of FGMeta:

    catalog   Generation of aircraft catalogs
    i18n      Management of translations in FlightGear (i18n stands for
              “internationalization”)
