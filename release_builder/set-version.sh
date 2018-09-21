#!/bin/bash
#This file is part of FlightGear
#
#FlightGear is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 2 of the License, or
#(at your option) any later version.
#
#FlightGear is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with FlightGear  If not, see <http://www.gnu.org/licenses/>.

if [ -z "$1" -o -z "$2" ]; then
  echo "usage: major.minor.micro path"
  exit
fi


IFS='.' read -r -a  VERSION_A <<< "$1"
shift
if [ ${#VERSION_A[@]} != 3 ]; then
  echo "Need version as 'number.number.number'"
  exit
fi
MAJOR_VERSION=${VERSION_A[0]}
MINOR_VERSION=${VERSION_A[1]}
MICRO_VERSION=${VERSION_A[2]}


setVersionTo() {
  local V="$1"
  echo "setting version to $V"
  echo "$V" > version
  git add version
  echo "new version: $V" | git commit --file=-
  git tag "version/$V"
}

while [ $# -gt 0 ]; do
  echo "Processing $1"
  pushd $1 > /dev/null
  git config user.name "Automatic Release Builder"
  git config user.email "build@flightgear.org"
  setVersionTo "${MAJOR_VERSION}.${MINOR_VERSION}.${MICRO_VERSION}"
  popd > /dev/null
  shift  
done
