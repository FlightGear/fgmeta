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
  echo "usage: author email"
  exit
fi

resetAuthor() {
    pushd $3 > /dev/null
  git config user.name "$1"
  git config user.email $2
  popd > /dev/null
}

resetAuthor "$1" $2 flightgear
resetAuthor "$1" $2 simgear
resetAuthor "$1" $2 fgdata
resetAuthor "$1" $2 getstart
resetAuthor "$1" $2 .

