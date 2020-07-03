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
  echo "usage: thismajor.thisminor nextmajor.nextminor path"
  exit
fi


IFS='.' read -r -a  VERSION_A <<< "$1"
shift
if [ ${#VERSION_A[@]} != 2 ]; then
  echo "Need version as 'number.number'"
  exit
fi
THIS_MAJOR_VERSION=${VERSION_A[0]}
THIS_MINOR_VERSION=${VERSION_A[1]}
RELEASE_BRANCH="release/${THIS_MAJOR_VERSION}.${THIS_MINOR_VERSION}"

IFS='.' read -r -a  VERSION_A <<< "$1"
shift
if [ ${#VERSION_A[@]} != 2 ]; then
  echo "Need version as 'number.number'"
  exit
fi
NEXT_MAJOR_VERSION=${VERSION_A[0]}
NEXT_MINOR_VERSION=${VERSION_A[1]}

setVersionTo() {
  local V="$1"
  echo "setting version to $V"
  echo "$V" > flightgear-version
  git add flightgear-version
  echo "new version: $V" | git commit --file=-
#  git tag "version/$V"
}

createBranch() {
  echo "Preparing release in `pwd`"

  git checkout next
  git pull --rebase

  setVersionTo "${THIS_MAJOR_VERSION}.${THIS_MINOR_VERSION}.1"

  echo "Creating branch $RELEASE_BRANCH for version $(cat version) in `pwd`"
  git branch "$RELEASE_BRANCH"

  setVersionTo "${NEXT_MAJOR_VERSION}.${NEXT_MINOR_VERSION}.0"
}

while [ $# -gt 0 ]; do
  echo "Processing $1"
  pushd $1 > /dev/null
  createBranch
  popd > /dev/null
  shift  
done
