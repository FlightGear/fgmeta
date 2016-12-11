This is the scripts I (James) use to maintain my builds on each platform.

They're much less clever than 'download and compile' but they do enough for me
and probably most other people, if you tweak the paths accordingly. The Mac
and Linux ones require Ruby (which is usually pre-installed). There are no
instructions - if you can't figure out what these do from reading the scripts,
you almost certainly should not be using them!

They all assume a top-level folder  which contains
checkouts of simgear, flightgear, fgdata, OpenSceneGraph (into a dir named
  'osg') and the windows-3rd-party dir in the case of Windows. It's assumed
  you copy the script to that same dir, edit paths and run from there.

The Mac and Linux scripts will do the checkout for you - the Windows is not
so smart because Window batch scripts are not my friend.

On Mac you will need to grab the 3rdparty-dependency-build from Jenkins, or
build PLIB manually yourself, either should be straightforward. For all other
dependencies on Mac / Linux use your package manager / Homebrew.

Files will be installed into a subdir called 'dist'
