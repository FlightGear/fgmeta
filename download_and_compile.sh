#!/bin/bash
#* Written by Francesco Angelo Brisa, started January 2008.
#
# Copyright (C) 2013 Francesco Angelo Brisa
# email: fbrisa@gmail.com   -   fbrisa@yahoo.it
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

script_blob_id='$Id$'
# Slightly tricky substitution to avoid our regexp being wildly replaced with
# the blob name (id) when the script is checked out:
#
# First extract the hexadecimal blob object name followed by a '$'
VERSION="$(echo "$script_blob_id" | sed 's@\$Id: *\([0-9a-f]\+\) *@\1@')"
# Then remove the trailing '$'
VERSION="${VERSION%\$}"

PROGNAME=$(basename "$0")
FGVERSION="release/$(git ls-remote --heads https://git.code.sf.net/p/flightgear/flightgear|grep '\/release\/'|cut -f4 -d'/'|sort -t . -k 1,1n -k2,2n -k3,3n|tail -1)"

#######################################################
# THANKS TO
#######################################################
# Special thanks to Alessandro Garosi for FGComGui and
# other patches
# Thanks to "Pat Callahan" for patches for fgrun compilation
# Thanks to "F-JJTH" for bug fixes and suggestions
# Thanks again to "F-JJTH" for OpenRTI and FGX
# Thanks to André, (taureau89_9) for debian stable packages fixes

#############################################################"
# Some helper functions for redundant tasks

# Return 0 if $1 is identical to one of $2, $3, etc., else return 1.
_elementIn(){
  local valueToCheck="$1"
  local e

  shift
  for e; do
    if [[ "$e" == "$valueToCheck" ]]; then
      return 0
    fi
  done

  return 1
}

function _log(){
  echo "$@" >> "$LOGFILE"
}

function _logSep(){
  _log "***********************************"
}

function _printLog(){
  # Possible special case for the terminal: echo "${PROGNAME}: $@"
  # That would be more precise but rather verbose, and not all output uses
  # _printLog() for now, so it would look too inconsistent.
  echo "$@" | tee -a "$LOGFILE"
}

# Echo the contents of stdin to the terminal and/or to $LOGFILE.
function _logOutput(){
  case "$1" in
    term)
      cat ;;
    file)
      cat >> "$LOGFILE" ;;
    ""|term+file)
      tee -a "$LOGFILE" ;;
    *)
      _printLog "Bug in ${PROGNAME}: unexpected value for the first parameter" \
                "of _logOutput(): '$1'"
      exit 1 ;;
  esac
}

function _aptUpdate(){
  echo "Asking password for 'apt-get update'..."
  sudo apt-get update
}

function _aptInstall(){
  echo "Asking password for 'apt-get install $*'..."
  sudo apt-get install "$@"
}

function _gitUpdate(){
  if [ "$DOWNLOAD" != "y" ]; then
    return
  fi
  branch=$1
  set +e
  git diff --exit-code 2>&1 > /dev/null
  if [ $? != 1 ]; then
    set -e
    git pull -r
    git checkout -f $branch
  else
    set -e
    git stash save -u -q
    git pull -r
    git checkout -f $branch
    git stash pop -q
  fi
}

function _gitProtoSpec(){
 local proto="$1"
 local username="$2"
 local component="$3"
 local complement

 case "$proto" in
   ssh)
     if [[ -z "$username" ]]; then
       if [[ -n "$component" ]]; then
         complement=" (used to retrieve component $component)"
       fi

       _printLog "Protocol ssh$complement requires a username,"
       _printLog "but none was specified! Aborting."
       exit 1
     fi
     echo "${proto}://${username}@"
     ;;
   https|git)
     echo "${proto}://"
     ;;
   *)
     _printLog "Unknown protocol in _gitProtoSpec(): '$proto'. Aborting."
     exit 1
     ;;
 esac
}

function _gitDownload(){
  local component="$1"
  local clone_arg

  if [ "$DOWNLOAD" != "y" ]; then
    return
  fi


  if [ -f "README" -o -f "README.txt" -o -f "README.rst" ]; then
    _printLog "$component: the repository already exists"
  else
    proto_spec=$(_gitProtoSpec "${REPO_PROTO[$component]}" \
                               "${REPO_USERNAME[$component]}" \
                               "$component")
    clone_arg="${proto_spec}${REPO_ADDRESS[$component]}"
    _printLog "Fetching $component with 'git clone $clone_arg'"
    git clone "$clone_arg" .
  fi
}

function _make(){
  if [ "$COMPILE" = "y" ]; then
    pkg=$1
    cd "$CBD"/build/$pkg
    _printLog "MAKE $pkg"
    make $JOPTION $OOPTION 2>&1 | _logOutput
    _printLog "INSTALL $pkg"
    make install 2>&1 | _logOutput
  fi
}

# Add an available, non-virtual package matching one of the given regexps.
#
# Each positional parameter is interpreted as a POSIX extended regular
# expression. These parameters are examined from left to right, and the first
# available matching package is added to the global PKG variable. If no match
# is found, the script aborts.
function _mandatory_pkg_alternative(){
  local pkg

  if [[ $# -lt 1 ]]; then
    _printLog \
      "Empty package alternative: this is a bug in the script, aborting."
    exit 1
  fi

  _printLog "Considering a package alternative: $*"
  pkg=$(_find_package_alternative "$@")

  if [[ -n "$pkg" ]]; then
    _printLog "Package alternative matched for $pkg"
    PKG="$PKG $pkg"
  else
    _printLog "No match found for the package alternative, aborting."
    exit 1
  fi

  return 0
}

# If available, add a non-virtual package matching one of the given regexps.
#
# Returning 0 or 1 on success to indicate whether a match was found could be
# done, but would need to be specifically handled at the calling site,
# since the script is run under 'set -e' regime.
function _optional_pkg_alternative(){
  local pkg

  if [[ $# -lt 1 ]]; then
    _printLog "Empty optional package alternative: this is a bug in the" \
              "script, aborting."
    exit 1
  fi

  _printLog "Considering an optional package alternative: $*"
  pkg=$(_find_package_alternative "$@")

  if [[ -n "$pkg" ]]; then
    _printLog "Optional package alternative matched for $pkg"
    PKG="$PKG $pkg"
  else
    _printLog "No match found for the optional package alternative," \
              "continuing anyway."
    # "$*" so that we only add one element to the array in this line
    UNMATCHED_OPTIONAL_PKG_ALTERNATIVES+=("$*")
  fi

  return 0
}

# This function requires the 'dctrl-tools' package
function _find_package_alternative(){
  local pkg

  if [[ $# -lt 1 ]]; then
    return 0                    # Nothing could be found
  fi

  # This finds non-virtual packages only (on purpose)
  pkg="$(apt-cache dumpavail | \
         grep-dctrl -e -sPackage -FPackage \
           "^[[:space:]]*($1)[[:space:]]*\$" - | \
         sed -ne '1s/^Package:[[:space:]]*//gp')"

  if [[ -n "$pkg" ]]; then
    echo "$pkg"
    return 0
  else
    # Try with the next regexp
    shift
    _find_package_alternative "$@"
  fi
}

function _printVersion(){
  echo "$PROGNAME version $VERSION"
  echo
  echo "This script is part of the FlightGear project."
  echo
  echo "This program is free software: you can redistribute it and/or modify"
  echo "it under the terms of the GNU General Public License as published by"
  echo "the Free Software Foundation, either version 3 of the License, or"
  echo "(at your option) any later version."
  echo
  echo "This program is distributed in the hope that it will be useful,"
  echo "but WITHOUT ANY WARRANTY; without even the implied warranty of"
  echo "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
  echo "GNU General Public License for more details."
  echo
  echo "You should have received a copy of the GNU General Public License"
  echo "along with this program.  If not, see <http://www.gnu.org/licenses/>."
}

function _usage() {
  echo "$PROGNAME [OPTION...] [--] [COMPONENT...]"
  echo "Download and compile components belonging to the FlightGear ecosystem."
  echo
  echo "Without any COMPONENT listed, or if ALL is specified, recompile all"
  echo "components listed in the WHATTOBUILDALL variable. Each COMPONENT may"
  echo "be one of the following words:"
  echo
  echo "  ALL, CMAKE, OSG, PLIB, OPENRTI, SIMGEAR, FGFS, DATA, FGRUN, FGO, FGX,"
  echo "  OPENRADAR, ATCPIE, TERRAGEAR, TERRAGEARGUI"
  echo
  echo "Available options:"
  echo "  -h, --help    show this help message and exit"
  echo "      --version print version and license information, then exit"
  echo "  -e            compile FlightGear with --with-eventinput option (experimental)"
  echo "  -i            compile SimGear and FlightGear with -D ENABLE_RTI=ON option (experimental)"
  echo "  -b RELEASE_TYPE                                                                     default=RelWithDebInfo"
  echo "                set build type to RELEASE_TYPE (Release|RelWithDebInfo|Debug)"
  echo "  -a y|n        y=do an apt-get update, n=don't                                       default=y"
  echo "  -p y|n        y=download packages, n=don't                                          default=y"
  echo "  -c y|n        y=compile programs, n=don't                                           default=y"
  echo "  -d y|n        y=fetch programs from internet (cvs, svn, etc...), n=don't            default=y"
  echo "      --git-clone-default-proto=PROTO                                                 default=https"
  echo "                default protocol to use for 'git clone' (https, git or ssh)"
  echo "      --git-clone-site-params=SITE=PROTOCOL[:USERNAME]"
  echo "                use PROTOCOL as USERNAME when cloning a Git repository located"
  echo "                at SITE (sample sites: 'sourceforge', 'github'; valid"
  echo "                protocols: 'ssh', 'https', 'git'; USERNAME is required when"
  echo "                using 'ssh'). You may pass this option several times with"
  echo "                different sites."
  echo "  -j X          pass -jX to the Make program"
  echo "  -O X          pass -OX to the Make program"
  echo "  -r y|n        y=reconfigure programs before compiling them, n=don't reconfigure     default=y"
  echo "  -s            compile only the last known stable versions"
}

#######################################################
# set script to stop if an error occours
set -e

CBD="$PWD"
LOGFILE="$CBD/compilation_log.txt"

# Available values for WHATTOBUILD and WHATTOBUILDALL:
declare -a WHATTOBUILD_AVAIL=(
  'CMAKE' 'PLIB' 'OPENRTI' 'OSG' 'SIMGEAR' 'FGFS' 'DATA' 'FGRUN' 'FGO' 'FGX'
  'OPENRADAR' 'ATCPIE' 'TERRAGEAR' 'TERRAGEARGUI'
)
WHATTOBUILDALL=(SIMGEAR FGFS DATA)

STABLE=
APT_GET_UPDATE="y"
DOWNLOAD_PACKAGES="y"
COMPILE="y"
RECONFIGURE="y"
DOWNLOAD="y"

# How to download Git repositories:
#
# - 'https' used to be fine, but is currently unreliable at SourceForge (esp.
#   for FGData, see
#   <https://forum.flightgear.org/viewtopic.php?f=20&t=33620&start=90&sid=afb8b688a02c01ea4ea9306c35487bd0>);
# - 'git' is insecure (no way to guarantee you are downloading what you expect
#   to be downloading);
# - 'ssh' is secure, but requires an account at SourceForge (may be created at
#   no cost, though).
#
# These are the default values but may be overridden via command-line options.
REPO_DEFAULT_PROTO='https'
REPO_DEFAULT_USERNAME=''

JOPTION=""
OOPTION=""
BUILD_TYPE="RelWithDebInfo"
SG_CMAKEARGS=""
FG_CMAKEARGS=""

declare -a UNMATCHED_OPTIONAL_PKG_ALTERNATIVES

# Will hold the per-repository download settings.
declare -A REPO_PROTO
declare -A REPO_USERNAME

# Allows one to set a default (username, protocol) combination for each hosting
# site (SouceForge, GitHub, GitLab, etc.) when cloning a new repository.
declare -A PROTO_AT_SITE
declare -A USERNAME_AT_SITE

# Most specific settings: per-repository (actually, one current assumes that
# there is at most one repository per component such as SIMGEAR, FGFS, DATA,
# etc.)
declare -A REPO_ADDRESS
declare -A REPO_SITE

REPO_ADDRESS[CMAKE]="cmake.org/cmake.git"
REPO_SITE[CMAKE]="cmake.org"
REPO_ADDRESS[PLIB]="git.code.sf.net/p/libplib/code"
REPO_SITE[PLIB]="SourceForge"
REPO_ADDRESS[OPENRTI]="git.code.sf.net/p/openrti/OpenRTI"
REPO_SITE[OPENRTI]="SourceForge"
REPO_ADDRESS[OSG]="github.com/openscenegraph/osg.git"
REPO_SITE[OSG]="GitHub"
REPO_ADDRESS[SIMGEAR]="git.code.sf.net/p/flightgear/simgear"
REPO_SITE[SIMGEAR]="SourceForge"
REPO_ADDRESS[DATA]="git.code.sf.net/p/flightgear/fgdata"
REPO_SITE[DATA]="SourceForge"
REPO_ADDRESS[FGFS]="git.code.sf.net/p/flightgear/flightgear"
REPO_SITE[FGFS]="SourceForge"
REPO_ADDRESS[FGRUN]="git.code.sf.net/p/flightgear/fgrun"
REPO_SITE[FGRUN]="SourceForge"
REPO_ADDRESS[FGX]="github.com/fgx/fgx.git"
REPO_SITE[FGX]="GitHub"
REPO_ADDRESS[ATCPIE]="git.code.sf.net/p/atc-pie/code"
REPO_SITE[ATCPIE]="SourceForge"
REPO_ADDRESS[TERRAGEAR]="git.code.sf.net/p/flightgear/terragear"
REPO_SITE[TERRAGEAR]="SourceForge"
REPO_ADDRESS[TERRAGEARGUI]="git.code.sf.net/p/flightgear/fgscenery/terrageargui"
REPO_SITE[TERRAGEARGUI]="SourceForge"

# getopt is from the util-linux package (in Debian). Contrary to bash's getopts
# built-in function, it allows one to define long options.
TEMP=$(getopt -o '+shc:p:a:d:r:j:O:ib:' \
  --longoptions git-clone-default-proto:,git-clone-site-params:,help,version \
  -n "$PROGNAME" -- "$@")

case $? in
    0) : ;;
    1) _usage >&2; exit 1 ;;
    *) exit 1 ;;
esac

# Don't remove the quotes around $TEMP!
eval set -- "$TEMP"

while true; do
  case "$1" in
    -s) STABLE="STABLE"; shift ;;
    -a) APT_GET_UPDATE="$2"; shift 2 ;;
    -c) COMPILE="$2"; shift 2 ;;
    -p) DOWNLOAD_PACKAGES="$2"; shift 2 ;;
    -d) DOWNLOAD="$2"; shift 2 ;;
    --git-clone-default-proto)
      proto="${2,,}"            # convert to lowercase

      if ! _elementIn "$proto" ssh https git; then
        echo "Invalid protocol passed to option" \
             "--git-clone-default-proto: '$2'." >&2
        echo "Allowed protocols are 'ssh', 'https' and 'git'." >&2
        exit 1
      fi

      REPO_DEFAULT_PROTO="$proto"
      unset -v proto
      shift 2
      ;;
    --git-clone-site-params)
      if [[ "$2" =~ ^([[:alnum:]]+)=([[:alpha:]]+)(:([[:alnum:]]+))?$ ]]; then
        site="${BASH_REMATCH[1],,}"         # convert the site to lowercase
        verbatim_proto="${BASH_REMATCH[2]}"
        proto="${verbatim_proto,,}"         # ditto for the protocol
        username="${BASH_REMATCH[4]}"       # but take the username verbatim

        if ! _elementIn "$proto" ssh https git; then
          echo "Invalid protocol passed to option --git-clone-site-params:" \
               "'$verbatim_proto'." >&2
          echo "Allowed protocols are 'ssh', 'https' and 'git'." >&2
          exit 1
        fi

        PROTO_AT_SITE[$site]="$proto"
        if [[ -n "$username" ]]; then
          USERNAME_AT_SITE[$site]="$username"
        fi

        if [[ "$proto" == "ssh" && -z "$username" ]]; then
          echo "Invalid value passed to option --git-clone-site-params: '$2'" >&2
          echo "The 'ssh' protocol requires a username (use" >&2
          echo "--git-clone-site-params SITE=ssh:USERNAME)." >&2
          exit 1
        fi

        unset -v site proto verbatim_proto username
      else
        echo "Invalid value passed to option --git-clone-site-params: '$2'." >&2
        echo "The correct syntax is" \
             "--git-clone-site-params SITE=PROTOCOL[:USERNAME]" >&2
        echo "(or --git-clone-site-params=SITE=PROTOCOL[:USERNAME])." >&2
        exit 1
      fi
      shift 2
      ;;
    -r) RECONFIGURE="$2"; shift 2 ;;
    -j) JOPTION=" -j$2"; shift 2 ;;
    -O) OOPTION=" -O$2"; shift 2 ;;
    -i) OPENRTI="OPENRTI"; shift ;;
    -b) BUILD_TYPE="$2"; shift 2 ;;
    -h|--help) _usage; exit 0 ;;
    --version) _printVersion; exit 0 ;;
    --) shift; break ;;
    *) echo "$PROGNAME: unexpected option '$1'; please report a bug." >&2
       exit 1 ;;
  esac
done

declare -a WHATTOBUILD=()

if [[ $# == 0 ]] || _elementIn ALL "$@"; then
  WHATTOBUILD=( "${WHATTOBUILDALL[@]}" )
else
  WHATTOBUILD=( "$@" )
fi

if [[ "$STABLE" != "STABLE" ]]; then
  FGVERSION="next"
fi

if [ "$OPENRTI" = "OPENRTI" ]; then
  SG_CMAKEARGS="$SG_CMAKEARGS -DENABLE_RTI=ON;"
  FG_CMAKEARGS="$FG_CMAKEARGS -DENABLE_RTI=ON;"
  WHATTOBUILD+=( "OPENRTI" )
fi

# Set the default download settings for each repository
for component in "${WHATTOBUILD_AVAIL[@]}"; do
  REPO_PROTO[$component]="$REPO_DEFAULT_PROTO"
  REPO_USERNAME[$component]="$REPO_DEFAULT_USERNAME"

  site="${REPO_SITE[$component]}"
  site="${site,,}"              # convert to lowercase

  # Is there a specific protocol for this repo's hosting site?
  if [[ -n "$site" && -n "${PROTO_AT_SITE[$site]}" ]]; then
    REPO_PROTO[$component]="${PROTO_AT_SITE[$site]}"
  fi

  # Is there a specific username for this repo's hosting site?
  if [[ -n "$site" && -n "${USERNAME_AT_SITE[$site]}" ]]; then
    REPO_USERNAME[$component]="${USERNAME_AT_SITE[$site]}"
  fi
done
unset -v site

#######################################################
#######################################################
# Warning about compilation time and size
# Idea from Jester
echo "**************************************"
echo "*                                    *"
echo "* Warning, the compilation process   *"
echo "* is going to use 12 or more Gbytes  *"
echo "* of space and at least a couple of  *"
echo "* hours to download and build FG.    *"
echo "*                                    *"
echo "* Please, be patient ......          *"
echo "*                                    *"
echo "**************************************"

#######################################################
#######################################################

echo "$0 $*" > "$LOGFILE"
_log "VERSION=$VERSION"
_log "APT_GET_UPDATE=$APT_GET_UPDATE"
_log "DOWNLOAD_PACKAGES=$DOWNLOAD_PACKAGES"
_log "COMPILE=$COMPILE"
_log "RECONFIGURE=$RECONFIGURE"
_log "DOWNLOAD=$DOWNLOAD"
_log "JOPTION=$JOPTION"
_log "OOPTION=$OOPTION"
_log "BUILD_TYPE=$BUILD_TYPE"
_log "DIRECTORY=$CBD"
_logSep

#######################################################
#######################################################

if [[ "$DOWNLOAD_PACKAGES" = "y" ]] && [[ "$APT_GET_UPDATE" = "y" ]]; then
  _aptUpdate
fi

# Ensure 'dctrl-tools' is installed
if [[ "$(dpkg-query --showformat='${Status}\n' --show dctrl-tools \
                    2>/dev/null | awk '{print $3}')" != "installed" ]]; then
  if [[ "$DOWNLOAD_PACKAGES" = "y" ]]; then
    _aptInstall dctrl-tools
  else
    echo -n "The 'dctrl-tools' package is needed, but DOWNLOAD_PACKAGES is "
    echo -e "not set to 'y'.\nAborting."
    exit 1
  fi
fi

# Minimum
PKG="build-essential cmake git"
_mandatory_pkg_alternative libcurl4-openssl-dev libcurl4-gnutls-dev
# cmake
PKG="$PKG libarchive-dev libbz2-dev libexpat1-dev libjsoncpp-dev liblzma-dev libncurses5-dev procps zlib1g-dev"
# TG
PKG="$PKG libcgal-dev libgdal-dev libtiff5-dev"
# TGGUI/OpenRTI
PKG="$PKG libqt4-dev"
# SG/FG
PKG="$PKG zlib1g-dev freeglut3-dev libglew-dev libboost-dev"
_mandatory_pkg_alternative libopenscenegraph-3.4-dev libopenscenegraph-dev \
                           'libopenscenegraph-[0-9]+\.[0-9]+-dev'
# FG
PKG="$PKG libopenal-dev libudev-dev libdbus-1-dev libplib-dev"
_mandatory_pkg_alternative libpng-dev libpng12-dev libpng16-dev
# The following packages are needed for the built-in launcher
_optional_pkg_alternative qt5-default
_optional_pkg_alternative qtdeclarative5-dev
_optional_pkg_alternative qtbase5-dev-tools            # for rcc
_optional_pkg_alternative qttools5-dev-tools           # for lrelease
_optional_pkg_alternative qml-module-qtquick2
_optional_pkg_alternative qml-module-qtquick-window2
_optional_pkg_alternative qml-module-qtquick-dialogs
_optional_pkg_alternative libqt5opengl5-dev
_optional_pkg_alternative libqt5svg5-dev
_optional_pkg_alternative libqt5websockets5-dev
# The following packages are only needed for the Qt-based remote Canvas
# (comment written at the time of FG 2018.2).
_optional_pkg_alternative qtbase5-private-dev
_optional_pkg_alternative qtdeclarative5-private-dev
# FGPanel
PKG="$PKG fluid libbz2-dev libfltk1.3-dev libxi-dev libxmu-dev"
# FGAdmin
PKG="$PKG libxinerama-dev libjpeg-dev libxft-dev"
# ATC-Pie
PKG="$PKG python3-pyqt5 python3-pyqt5.qtmultimedia libqt5multimedia5-plugins"
# FGo
PKG="$PKG python-tk"
# FGx (FGx is not compatible with Qt5, however we have installed Qt5 by default)
#PKG="$PKG libqt5xmlpatterns5-dev libqt5webkit5-dev"

if [[ "$DOWNLOAD_PACKAGES" = "y" ]]; then
  _aptInstall $PKG
fi

#######################################################
#######################################################

SUB_INSTALL_DIR=install
INSTALL_DIR="$CBD/$SUB_INSTALL_DIR"
cd "$CBD"
mkdir -p build install

#######################################################
# BACKWARD COMPATIBILITY WITH 1.9.14a
#######################################################

if [ -d "$CBD"/fgfs/flightgear ]; then
  _logSep
  _printLog "Move to the new folder structure"
  rm -rf OpenSceneGraph
  rm -rf plib
  rm -rf build
  rm -rf install/fgo
  rm -rf install/fgx
  rm -rf install/osg
  rm -rf install/plib
  rm -rf install/simgear
  rm -f *.log*
  rm -f run_*.sh
  mv openrti/openrti tmp && rm -rf openrti && mv tmp openrti
  mv fgfs/flightgear tmp && rm -rf fgfs && mv tmp flightgear
  mv simgear/simgear tmp && rm -rf simgear && mv tmp simgear
  mkdir -p install/flightgear && mv install/fgfs/fgdata install/flightgear/fgdata
  echo "Done"
fi

_printLog

#######################################################
# cmake
#######################################################
CMAKE_INSTALL_DIR=cmake
INSTALL_DIR_CMAKE=$INSTALL_DIR/$CMAKE_INSTALL_DIR
cd "$CBD"
if _elementIn "CMAKE" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "*************** CMAKE ******************"
  _printLog "****************************************"

  mkdir -p "cmake"
  cd "$CBD"/cmake
  _gitDownload CMAKE
  _gitUpdate master

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/cmake
    _printLog "CONFIGURING CMake"
    cd "$CBD"/build/cmake
    ../../cmake/configure --prefix="$INSTALL_DIR_CMAKE" \
           2>&1 | _logOutput
  fi

  _make cmake
  CMAKE="$INSTALL_DIR_CMAKE/bin/cmake"
else
  if [ -x "$INSTALL_DIR_CMAKE/bin/cmake" ]; then
    CMAKE="$INSTALL_DIR_CMAKE/bin/cmake"
  else
    CMAKE=cmake
  fi
fi

#######################################################
# PLIB
#######################################################
PLIB_INSTALL_DIR=plib
INSTALL_DIR_PLIB=$INSTALL_DIR/$PLIB_INSTALL_DIR
cd "$CBD"
if _elementIn "PLIB" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "**************** PLIB ******************"
  _printLog "****************************************"

  mkdir -p "plib"
  cd "$CBD"/plib
  _gitDownload PLIB
  _gitUpdate master

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/plib
    _log "CONFIGURING plib"
    cd "$CBD"/build/plib
    "$CMAKE" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
          -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_PLIB" \
          ../../plib 2>&1 | _logOutput
  fi

  _make plib
fi

#######################################################
# OPENRTI
#######################################################
OPENRTI_INSTALL_DIR=openrti
INSTALL_DIR_OPENRTI=$INSTALL_DIR/$OPENRTI_INSTALL_DIR
cd "$CBD"
if _elementIn "OPENRTI" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "**************** OPENRTI ***************"
  _printLog "****************************************"

  mkdir -p "openrti"
  cd "$CBD"/openrti
  _gitDownload OPENRTI

  if [ "$STABLE" = "STABLE" ]; then
    _gitUpdate release-0.7
  else
    _gitUpdate master
  fi

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/openrti
    cd "$CBD"/build/openrti
    rm -f CMakeCache.txt
    "$CMAKE" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
          -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_OPENRTI" \
          ../../openrti 2>&1 | _logOutput
  fi

  _make openrti
fi

#######################################################
# OpenSceneGraph
#######################################################
OSG_INSTALL_DIR=openscenegraph
INSTALL_DIR_OSG=$INSTALL_DIR/$OSG_INSTALL_DIR
cd "$CBD"
mkdir -p "openscenegraph"
if _elementIn "OSG" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "**************** OSG *******************"
  _printLog "****************************************"

  cd "$CBD"/openscenegraph
  _gitDownload OSG
  _gitUpdate OpenSceneGraph-3.4

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/openscenegraph
    cd "$CBD"/build/openscenegraph
    rm -f CMakeCache.txt
    if [ "$BUILD_TYPE" = "Debug" ]; then
      OSG_BUILD_TYPE=Debug
    else
      OSG_BUILD_TYPE=Release
    fi
    "$CMAKE" -DCMAKE_BUILD_TYPE="$OSG_BUILD_TYPE" \
         -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_OSG" ../../openscenegraph \
         2>&1 | _logOutput
  fi

  _make openscenegraph
  #FIX FOR 64 BIT COMPILATION
  if [ -d "$INSTALL_DIR_OSG/lib64" ]; then
    if [ -L "$INSTALL_DIR_OSG/lib" ]; then
      echo "link already done"
    else
      ln -s "$INSTALL_DIR_OSG/lib64" "$INSTALL_DIR_OSG/lib"
    fi
  fi
fi

#######################################################
# SIMGEAR
#######################################################
SIMGEAR_INSTALL_DIR=simgear
INSTALL_DIR_SIMGEAR=$INSTALL_DIR/$SIMGEAR_INSTALL_DIR
cd "$CBD"
if _elementIn "SIMGEAR" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "**************** SIMGEAR ***************"
  _printLog "****************************************"

  mkdir -p "simgear"
  cd "$CBD"/simgear
  _gitDownload SIMGEAR
  _gitUpdate $FGVERSION

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/simgear
    cd "$CBD"/build/simgear
    rm -f CMakeCache.txt
    "$CMAKE" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
          -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_SIMGEAR" \
          -DCMAKE_PREFIX_PATH="$INSTALL_DIR_OSG;$INSTALL_DIR_OPENRTI" \
	  $SG_CMAKEARGS \
          ../../simgear 2>&1 | _logOutput
  fi

  _make simgear
fi

#######################################################
# FGFS
#######################################################
FGFS_INSTALL_DIR=flightgear
INSTALL_DIR_FGFS=$INSTALL_DIR/$FGFS_INSTALL_DIR
cd "$CBD"
if _elementIn "FGFS" "${WHATTOBUILD[@]}" || \
   _elementIn "DATA" "${WHATTOBUILD[@]}"; then
  mkdir -p "$INSTALL_DIR_FGFS"/fgdata
  cd "$INSTALL_DIR_FGFS"/fgdata

  if _elementIn "DATA" "${WHATTOBUILD[@]}"; then
    _printLog "****************************************"
    _printLog "**************** DATA ******************"
    _printLog "****************************************"

    _gitDownload DATA
    _gitUpdate $FGVERSION
  fi

  mkdir -p "$CBD"/flightgear
  cd "$CBD"/flightgear

  if _elementIn "FGFS" "${WHATTOBUILD[@]}"; then
    _printLog "****************************************"
    _printLog "************** FLIGHTGEAR **************"
    _printLog "****************************************"

    _gitDownload FGFS
    _gitUpdate $FGVERSION

    if [ "$RECONFIGURE" = "y" ]; then
      cd "$CBD"
      mkdir -p build/flightgear
      cd "$CBD"/build/flightgear
      rm -f CMakeCache.txt
      "$CMAKE" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
            -DENABLE_FLITE=ON \
            -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGFS" \
            -DCMAKE_PREFIX_PATH="$INSTALL_DIR_SIMGEAR;$INSTALL_DIR_OSG;$INSTALL_DIR_OPENRTI;$INSTALL_DIR_PLIB" \
            -DFG_DATA_DIR="$INSTALL_DIR_FGFS/fgdata" \
            $FG_CMAKEARGS \
            ../../flightgear 2>&1 | _logOutput
    fi

    _make flightgear
  fi
  cd "$CBD"

  SCRIPT=run_fgfs.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin" >> $SCRIPT
  echo "export LD_LIBRARY_PATH=../../$SIMGEAR_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$OPENRTI_INSTALL_DIR/lib:../../$PLIB_INSTALL_DIR/lib\${LD_LIBRARY_PATH:+:}\${LD_LIBRARY_PATH}" \
       >> $SCRIPT
  echo "./fgfs --fg-root=\$PWD/../fgdata/ \$@" >> $SCRIPT
  chmod 755 $SCRIPT

  SCRIPT=run_fgfs_debug.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin" >> $SCRIPT
  echo "export LD_LIBRARY_PATH=../../$SIMGEAR_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$OPENRTI_INSTALL_DIR/lib:../../$PLIB_INSTALL_DIR/lib\${LD_LIBRARY_PATH:+:}\${LD_LIBRARY_PATH}" \
       >> $SCRIPT
  echo "gdb  --directory=$CBD/flightgear/src --args fgfs --fg-root=\$PWD/../fgdata/ \$@" >> $SCRIPT
  chmod 755 $SCRIPT

  SCRIPT=run_fgcom.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin" >> $SCRIPT
  echo "./fgcom \$@" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# FGRUN
#######################################################
FGRUN_INSTALL_DIR=fgrun
INSTALL_DIR_FGRUN=$INSTALL_DIR/$FGRUN_INSTALL_DIR
cd "$CBD"
if _elementIn "FGRUN" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "**************** FGRUN *****************"
  _printLog "****************************************"

  mkdir -p "fgrun"
  cd "$CBD"/fgrun
  _gitDownload FGRUN
  _gitUpdate $FGVERSION

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/fgrun
    cd "$CBD"/build/fgrun
    rm -f CMakeCache.txt
    "$CMAKE" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
          -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGRUN" \
          -DCMAKE_PREFIX_PATH="$INSTALL_DIR_SIMGEAR" \
          ../../fgrun/ 2>&1 | _logOutput
  fi

  _make fgrun

  cd "$CBD"

  SCRIPT=run_fgrun.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$FGRUN_INSTALL_DIR/bin" >> $SCRIPT
  echo "export LD_LIBRARY_PATH=../../$SIMGEAR_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$OPENRTI_INSTALL_DIR/lib:../../$PLIB_INSTALL_DIR/lib\${LD_LIBRARY_PATH:+:}\${LD_LIBRARY_PATH}" \
       >> $SCRIPT
  echo "./fgrun --fg-exe=\$PWD/../../$FGFS_INSTALL_DIR/bin/fgfs --fg-root=\$PWD/../../$FGFS_INSTALL_DIR/fgdata   \$@" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# FGO!
#######################################################
FGO_INSTALL_DIR=fgo
INSTALL_DIR_FGO=$INSTALL_DIR/$FGO_INSTALL_DIR
cd "$CBD"
if _elementIn "FGO" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "***************** FGO ******************"
  _printLog "****************************************"

  if [ "$DOWNLOAD" = "y" ]; then
    rm -rf fgo*.tar.gz
    wget https://sites.google.com/site/erobosprojects/flightgear/add-ons/fgo/download/fgo-1.5.5.tar.gz -O fgo.tar.gz
    cd install
    tar -zxvf ../fgo.tar.gz
    cd ..
  fi

  cd "$CBD"

  SCRIPT=run_fgo.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR" >> $SCRIPT
  echo "p=\$(pwd)" >> $SCRIPT
  echo "cd $FGO_INSTALL_DIR" >> $SCRIPT
  echo "python fgo" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# FGx
#######################################################
FGX_INSTALL_DIR=fgx
INSTALL_DIR_FGX=$INSTALL_DIR/$FGX_INSTALL_DIR
cd "$CBD"
if _elementIn "FGX" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "***************** FGX ******************"
  _printLog "****************************************"

  mkdir -p "fgx"
  cd "$CBD"/fgx
  _gitDownload FGX
  _gitUpdate master

  cd "$CBD"/fgx/src/
  #Patch in order to pre-setting paths
  cd resources/default/
  cp x_default.ini x_default.ini.orig
  cat x_default.ini | sed s/\\/usr\\/bin\\/fgfs/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgfsMY_SLASH_HEREbinMY_SLASH_HEREfgfs/g > tmp1
  cat tmp1 | sed s/\\/usr\\/share\\/flightgear/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgfsMY_SLASH_HEREfgdata/g > tmp2
  cat tmp2 | sed s/\\/usr\\/bin\\/terrasync/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgfsMY_SLASH_HEREbinMY_SLASH_HEREterrasync/g > tmp3
  cat tmp3 | sed s/\\/usr\\/bin\\/fgcom/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgcomMY_SLASH_HEREbinMY_SLASH_HEREfgcom/g > tmp4
  cat tmp4 | sed s/\\/usr\\/bin\\/js_demo/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgfsMY_SLASH_HEREbinMY_SLASH_HEREjs_demo/g > tmp5
  INSTALL_DIR_FGX_NO_SLASHS=$(echo "$INSTALL_DIR_FGX" | sed -e 's/\//MY_SLASH_HERE/g')
  cat tmp5 | sed s/INSTALL_DIR_FGX/"$INSTALL_DIR_FGX_NO_SLASHS"/g > tmp
  cat tmp | sed s/MY_SLASH_HERE/\\//g > x_default.ini
  rm tmp*

  cd ..
  if [ "$RECONFIGURE" = "y" ]; then
    mkdir -p $INSTALL_DIR_FGX
    cd $INSTALL_DIR_FGX
    qmake ../../fgx/src
  fi

  if [ "$COMPILE" = "y" ]; then
    cd $INSTALL_DIR_FGX
    _printLog "MAKE AND INSTALL FGX"
    _printLog "make $JOPTION $OOPTION"
    make $JOPTION $OOPTION 2>&1 | _logOutput
    cd ..
  fi

  cd "$CBD"

  SCRIPT=run_fgx.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $ " >> $SCRIPT
  echo "p=\$(pwd)" >> $SCRIPT
  echo "cd $FGX_INSTALL_DIR" >> $SCRIPT
  echo "./fgx" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# ATC-PIE
#######################################################
ATCPIE_INSTALL_DIR=atc-pie
INSTALL_DIR_ATCPIE=$INSTALL_DIR/$ATCPIE_INSTALL_DIR
cd "$CBD"
if _elementIn "ATCPIE" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "**************** ATCPIE ***************"
  _printLog "****************************************"

  mkdir -p "$INSTALL_DIR_ATCPIE"
  cd $INSTALL_DIR_ATCPIE
  _gitDownload ATCPIE
  _gitUpdate master

  cd "$CBD"

  SCRIPT=run_atcpie.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$ATCPIE_INSTALL_DIR" >> $SCRIPT
  echo "./ATC-pie.py \$@" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# OPENRADAR
#######################################################
OR_INSTALL_DIR=openradar
INSTALL_DIR_OR=$INSTALL_DIR/$OR_INSTALL_DIR
cd "$CBD"
if _elementIn "OPENRADAR" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "************** OPENRADAR ***************"
  _printLog "****************************************"

  if [ "$DOWNLOAD" = "y" ]; then
    wget http://wagnerw.de/OpenRadar.zip -O OpenRadar.zip
    cd install
    unzip -o ../OpenRadar.zip
    cd ..
  fi

  SCRIPT=run_openradar.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd install/OpenRadar" >> $SCRIPT
  echo "java -jar OpenRadar.jar" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# TERRAGEAR
#######################################################

TG_INSTALL_DIR=terragear
INSTALL_DIR_TG=$INSTALL_DIR/$TG_INSTALL_DIR
cd "$CBD"
if _elementIn "TERRAGEAR" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "*************** TERRAGEAR **************"
  _printLog "****************************************"

  mkdir -p "terragear"
  cd "$CBD"/terragear
  _gitDownload TERRAGEAR
  _gitUpdate scenery/ws2.0

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/terragear
    cd "$CBD"/build/terragear
    rm -f CMakeCache.txt
    "$CMAKE" -DCMAKE_BUILD_TYPE="Debug" \
          -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_TG" \
          -DCMAKE_PREFIX_PATH="$INSTALL_DIR_SIMGEAR;$INSTALL_DIR_CGAL" \
          ../../terragear/ 2>&1 | _logOutput
  fi

  _make terragear

  cd "$CBD"
  echo "#!/bin/sh" > run_tg-construct.sh
  echo "cd $(dirname $0)" >> run_tg-construct.sh
  echo "cd install/terragear/bin" >> run_tg-construct.sh
  echo "export LD_LIBRARY_PATH=$INSTALL_DIR_SIMGEAR/lib\${LD_LIBRARY_PATH:+:}\${LD_LIBRARY_PATH}" \
       >> run_tg-construct.sh
  echo "./tg-construct \$@" >> run_tg-construct.sh

  echo "#!/bin/sh" > run_ogr-decode.sh
  echo "cd $(dirname $0)" >> run_ogr-decode.sh
  echo "cd install/terragear/bin" >> run_ogr-decode.sh
  echo "export LD_LIBRARY_PATH=$INSTALL_DIR_SIMGEAR/lib\${LD_LIBRARY_PATH:+:}\${LD_LIBRARY_PATH}" \
       >> run_ogr-decode.sh
  echo "./ogr-decode \$@" >> run_ogr-decode.sh

  echo "#!/bin/sh" > run_genapts850.sh
  echo "cd $(dirname $0)" >> run_genapts850.sh
  echo "cd install/terragear/bin" >> run_genapts850.sh
  echo "export LD_LIBRARY_PATH=$INSTALL_DIR_SIMGEAR/lib\${LD_LIBRARY_PATH:+:}\${LD_LIBRARY_PATH}" \
       >> run_genapts850.sh
  echo "./genapts850 \$@" >> run_genapts850.sh
fi
_logSep

#######################################################
# TERRAGEAR GUI
#######################################################

TGGUI_INSTALL_DIR=terrageargui
INSTALL_DIR_TGGUI=$INSTALL_DIR/$TGGUI_INSTALL_DIR
cd "$CBD"
if _elementIn "TERRAGEARGUI" "${WHATTOBUILD[@]}"; then
  _printLog "****************************************"
  _printLog "************* TERRAGEAR GUI ************"
  _printLog "****************************************"

  mkdir -p "terrageargui"
  cd "$CBD"/terrageargui
  _gitDownload TERRAGEARGUI
  _gitUpdate master


  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/terrageargui
    cd "$CBD"/build/terrageargui
    rm -f ../../terrageargui/CMakeCache.txt
    "$CMAKE" -DCMAKE_BUILD_TYPE="Release" \
          -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR_TGGUI" \
          ../../terrageargui 2>&1 | _logOutput
  fi

  _make terrageargui

  cd "$CBD"
  # Fill TerraGear Root field
  if [ ! -f ~/.config/TerraGear/TerraGearGUI.conf ]; then
    _log "Fill TerraGear Root field"
    echo "[paths]" > TerraGearGUI.conf
    echo "terragear=$INSTALL_DIR_TG/bin" >> TerraGearGUI.conf
    mkdir -p ~/.config/TerraGear
    mv TerraGearGUI.conf ~/.config/TerraGear
  fi

  _log "Create run_terrageargui.sh"
  echo "#!/bin/sh" > run_terrageargui.sh
  echo "cd \$(dirname \$0)" >> run_terrageargui.sh
  echo "cd install/terrageargui/bin" >> run_terrageargui.sh
  echo "export LD_LIBRARY_PATH=$INSTALL_DIR_SIMGEAR/lib\${LD_LIBRARY_PATH:+:}\${LD_LIBRARY_PATH}" \
       >> run_terrageargui.sh
  echo "./TerraGUI \$@" >> run_terrageargui.sh
fi

# Print optional package alternatives that didn't match (this helps with
# troubleshooting)
if [[ ${#UNMATCHED_OPTIONAL_PKG_ALTERNATIVES[@]} -gt 0 ]]; then
  _printLog
  _printLog "The following optional package alternative(s) didn't match:"
  _printLog

  for alt in "${UNMATCHED_OPTIONAL_PKG_ALTERNATIVES[@]}"; do
    _printLog "  $alt"
  done

  _printLog
  _printLog "This could explain missing optional features in FlightGear" \
            "or other software"
  _printLog "installed by $PROGNAME."
else
  _printLog "All optional package alternatives have found a matching package."
fi

_printLog
_printLog "$PROGNAME has finished to work."
