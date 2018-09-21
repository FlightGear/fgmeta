#!/bin/bash
cat << EOF
Changelog for FlightGear from $1 to $2
==========================
EOF
for submodule in simgear flightgear fgdata; do
cat << EOF

$submodule
--------------------------
EOF
  pushd  $submodule > /dev/null 2>&1
    git log --pretty=format:%s version/${1}..version/${2} |while read f; do 
      echo "* $f"; 
    done 
  popd 
done
