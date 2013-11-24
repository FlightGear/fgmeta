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

VERSION="1.9-12" 

#COMPILE GIT FGFS

#######################################################
# THANKS TO
#######################################################
# Special thanks to Alessandro Garosi for FGComGui and 
# other patches
# Thanks to "Pat Callahan" for patches for fgrun compilation
# Thanks to "F-JJTH" for bug fixes and suggestions
# Thanks again to "F-JJTH" for OpenRTI and FGX 
# Thanks to André, ( taureau89_9 ) for debian stable packages fixes

# ---------------------------------------------------------
# Script Section: Script and Option Initialization
# ---------------------------------------------------------
function write_log(){
	if [[ "$1" = "separator" ]]
	then 
		echo ""               | tee -a download_and_compile_summary.log
		echo "-----------------------------------------------------------------------------------" \
				      | tee -a download_and_compile_summary.log
		echo ""               | tee -a download_and_compile_summary.log
	else
		echo "$(date) $1"| tee -a download_and_compile_summary.log
	fi
}
function write_log_and_exec(){
	write_log "$1 $2"
	$1
}
function SET_WINDOW_TITLE(){
	echo -ne "\033]0;Build Flightgear:  -  ${CBD} - $1\007"
}
function check_build(){
#
# which directories have flightgear installations
#


cd $1
pwd=$(pwd)
for fgfs_install_dir in $(find $1 -type d -regex '.*install/fgfs')
do
	write_log; write_log; 
	
        cd $pwd

	cd "${fgfs_install_dir}/.."
	install_dir=$(pwd)
	exe_fgfs=""
	exe_fgrun=""
	exe_fgcom=""
	exe_fgcomgui=""
	install_dir_fgfs=""
	install_dir_fgrun=""
	install_dir_fgcom=""
	install_dir_fgcomgui=""
	no_exe_fgfs=""
	no_exe_fgrun=""
	no_exe_fgcom=""
	no_exe_fgcomgui=""
	no_install_dir_fgfs=""
	no_install_dir_fgrun=""
	no_install_dir_fgcom=""
	no_install_dir_fgcomgui=""

	if [[ -e ${install_dir}/fgfs/bin/fgfs ]] 
	then
		exe_fgfs="fgfs"
	else
		no_exe_fgfs="fgfs"
	fi

	if [[ -e "${install_dir}/fgrun/bin/fgrun" ]] 
	then
		exe_fgrun="fgrun"
	else
		no_exe_fgrun="fgrun"
	fi

	if [[ -e "${install_dir}/fgcom/bin/fgcom" ]] 
	then
		exe_fgcom="fgcom"
	else
		no_exe_fgcom="fgcom"
	fi

	if [[ -e "${install_dir}/fgcomgui/bin/fgcomgui" ]] 
	then
		exe_fgcomgui="fgcomgui"
	else
		no_exe_fgcomgui="fgcomgui"
	fi

	if [[ -e ${install_dir}/fgfs ]] 
	then
		install_dir_fgfs="fgfs"
	else
		no_install_dir_fgfs="fgfs"
	fi

	if [[ -e "${install_dir}/fgrun" ]] 
	then
		install_dir_fgrun="fgrun"
	else
		no_install_dir_fgrun="fgrun"
	fi

	if [[ -e "${install_dir}/fgcom" ]] 
	then
		install_dir_fgcom="fgcom"
	else
		no_install_dir_fgcom="fgcom"
	fi

	if [[ -e "${install_dir}/fgcomgui" ]] 
	then
		install_dir_fgcomgui="fgcomgui"
	else
		no_install_dir_fgcomgui="fgcomgui"
	fi

	
	found_exe="$exe_fgfs $exe_fgrun $exe_fgcom $exe_fgcomgui"
	no_exe="$no_exe_fgfs $no_exe_fgrun $no_exe_fgcom $no_exe_fgcomgui"
	found_install_dir="$install_dir_fgfs $install_dir_fgrun $install_dir_fgcom $install_dir_fgcomgui"
	no_install_dir="$no_install_dir_fgfs $no_install_dir_fgrun $no_install_dir_fgcom $no_install_dir_fgcomgui"
	found_exe=${found_exe=## }
	found_install_dir=${found_install_dir=##}
	no_exe=${no_exe##}
	no_install_dir=${no_install_dir##}

        cd $pwd

	write_log separator
	write_log "Install dir: ${install_dir}"
	write_log separator

	write_log "Found fgdata:          $(cat $install_dir/fgfs/fgdata/version)"
	write_log "Found Executables:     $found_exe"
	write_log "Found Install Dir:     $found_install_dir"
	write_log "Found No Executables:  $no_exe"
	write_log "Found No Install Dir:  $no_install_dir"
	write_log ""
	write_log separator
	write_log separator
	write_log ""
done
}
rebuild_command="$0 $*"
echo $0 $* >>download_and_compile.log
echo "		started building in $(pwd)" >>download_and_compile.log
echo "		        at $(date)" >>download_and_compile.log

LOGFILE=compilation_log.txt
LOGSEP="***********************************"

WHATTOBUILD=
WHATTOBUILDALL=( PLIB OSG OPENRTI SIMGEAR FGFS DATA FGRUN FGCOM )
UPDATE=
STABLE=
STOP_AFTER_ONE_MODULE=false 

APT_GET_UPDATE="y"
DOWNLOAD_PACKAGES="y"

COMPILE="y"
RECONFIGURE="y"
DOWNLOAD="y"

JOPTION=""
OOPTION=""
DEBUG=""
WITH_EVENT_INPUT=""
WITH_OPENRTI=""
FGSG_BRANCH="next"
FGSG_REVISION="HEAD"
OSG_VERSION="3.0.1"
# ---------------------------------------------------------
# Script Section: Option Interpretation
# ---------------------------------------------------------
SET_WINDOW_TITLE "Script and Option Initialization"

while getopts "zsuhgeixvwc:p:a:d:r:j:O:B:R:G:" OPTION
do
	echo $OPTION
     case $OPTION in
         s)
	     STABLE="STABLE"
             FGSG_BRANCH="2.10.0"
	     FGSG_REVISION="HEAD"
             ;;
         B)
             FGSG_BRANCH=$OPTARG
             ;;
         R)
             FGSG_REVISION=$OPTARG
             ;;
         G)
	     OSG_VERSION=${OPTARG^^} #3.0.1, 3.0.1d 3.1.9 3.1.9d, next nextd, etc
	     OSG_DEBUG_OR_RELEASE='Release'
	     if [[ ${OSG_VERSION%d} != ${OSG_VERSION} ]]
	     then
		    OSG_DEBUG_OR_RELEASE='Debug'
		    OSG_VERSION= ${OSG_VERSION%d}
	     fi
	     ;;         
	 u)
             UPDATE="UPDATE"
             ;;
         h)
             HELP="HELP"
             ;;
         a)
             APT_GET_UPDATE=$OPTARG
             ;;
         c)
             COMPILE=$OPTARG
             ;;
         p)
             DOWNLOAD_PACKAGES=$OPTARG
             ;;
         d)
             DOWNLOAD=$OPTARG
             ;;
         r)
             RECONFIGURE=$OPTARG
             ;;
         j)
             JOPTION=" -j"$OPTARG" "
             ;;
	 O)
	    OOPTION=" -O"$OPTARG" "
	    ;;
         g)
             DEBUG="CXXFLAGS=-g"
             ;;
         e)
             WITH_EVENT_INPUT="--with-eventinput"
             ;;
         i)
             WITH_OPENRTI="-D ENABLE_RTI=ON"
             ;;
         x)
             set -x
             ;;
         v)
             set -v
             ;;
         w)
	     VERBOSE_MAKEFILE="-D CMAKE_VERBOSE_MAKEFILE=ON"
	     ;;
         z)
	     STOP_AFTER_ONE_MODULE=true
	     ;;
         ?)
             echo "error"
             HELP="HELP"
             #exit
             ;;
     esac
done


# ---------------------------------------------------------
# Script Section: Build Argument Interpretation
# ---------------------------------------------------------
SET_WINDOW_TITLE "Option Interpretation"


shift $(($OPTIND - 1))
#printf "Remaining arguments are: %s\n" "$*"
#printf "Num: %d\n" "$#"

if [ ! "$#" = "0" ]
then
	for arg in $*
	do
		#echo  "$arg"
		if [ "${arg^^}" == "UPDATE" ]
		then
			UPDATE="UPDATE"
		else
			WHATTOBUILD=( "${WHATTOBUILD[@]}" "${arg^^}" )
		fi
	done
else
	WHATTOBUILD=( "${WHATTOBUILDALL[@]}" )
fi

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="ALL"' ]]
then
	WHATTOBUILD=( "${WHATTOBUILDALL[@]}" )
fi

printf "%s\n" "${WHATTOBUILD[@]}"

# ---------------------------------------------------------
# Script Section: Set Source Archive Version Variables
# ---------------------------------------------------------

# Last stable revision: currently FlightGear 2.10.0 with 3.0.1
PLIB_STABLE_REVISION="2172"
OSG_SVN="http://svn.openscenegraph.org/osg/OpenSceneGraph/tags/OpenSceneGraph-${OSG_VERSION}/"

declare -A OPENRTI_MAP
declare -A FGSG_MAP
declare -A FGDATA_MAP
FGSG_MAP=( [next]="next HEAD"  \
		[master]="master HEAD "  \
		[2.12.1]="release/2.12.1 HEAD"  \
		[2.12.0]="release/2.12.0 HEAD"  \
		[2.10.0]="release/2.10.0 HEAD "  \
		[2.8.0]="release/2.8.0 version/2.8.0-final" )
FGDATA_MAP=([next]="next HEAD 2.99.9"  \
		[master]="master HEAD 2.12.1"  \
		[master]="master HEAD 2.12.0"  \
		[2.12.0]="release/2.12.0 HEAD 2.12.0"  \
		[2.10.0]="release/2.10.0 HEAD 2.10.0"  \
		[2.8.0]="release/2.8.0 HEAD 2.8.0" )

OPENRTI_MAP=( [next]="master HEAD" \
		[master]="master HEAD"	\
		[2.12.1]="master HEAD"  \
		[2.12.0]="master HEAD"  \
		[2.10.0]="master HEAD"  \
		[2.8.0]="release-0.3 OpenRTI-0.3.0" )

FG_SG_VERSION=${FGSG_BRANCH##*/}

MAP_ITEM=( ${FGSG_MAP[${FG_SG_VERSION}]} )
FGSG_BRANCH=${MAP_ITEM[0]}
FGSG_REVISION=${MAP_ITEM[1]}

MAP_ITEM=( ${FGDATA_MAP[${FG_SG_VERSION}]} )
FGDATA_BRANCH=${MAP_ITEM[1]}
FGDATA_REVISION=${MAP_ITEM[2]}
FGDATA_VERSION=${MAP_ITEM[3]}

MAP_ITEM=( ${OPENRTI_MAP[${FG_SG_VERSION}]} )
OPENRTI_BRANCH=${MAP_ITEM[0]}
OPENRTI_REVISION=${MAP_ITEM[1]}


# FGCOM
FGCOM_BRANCH="master"
FGCOMGUI_STABLE_REVISION="46"

#OpenRadar
OR_STABLE_RELEASE="http://wagnerw.de/OpenRadar.zip"

fgdata_git="git://gitorious.org/fg/fgdata.git"
echo $(pwd)

# ---------------------------------------------------------
# Script Section: Display Script Help
# ---------------------------------------------------------

if [ "$HELP" = "HELP" ]
then
	echo "$0 Version $VERSION"
	echo "Usage:"
	echo "./$0 [-u] [-h] [-s] [-e] [-i] [-g] [-a y|n] [-c y|n] [-p y|n] [-d y|n] [-r y|n] [ALL|PLIB|OSG|OPENRTI|SIMGEAR|FGFS|FGO|FGX|FGRUN|FGCOM|FGCOMGUI|ATLAS] [UPDATE]"
	echo "* without options it recompiles: PLIB,OSG,OPENRTI,SIMGEAR,FGFS,FGRUN"
	echo "* Using ALL compiles everything"
	echo "* Adding UPDATE it does not rebuild all (faster but to use only after one successfull first compile)"
	echo "Switches:"
	echo "* -u  such as using UPDATE"
	echo "* -h  show this help"
	echo "* -e  compile FlightGear with --with-eventinput option (experimental)"
	echo "* -i  compile SimGear and FlightGear with -D ENABLE_RTI=ON option (experimental)"
	echo "* -g  compile with debug info for gcc"
	echo "* -a y|n  y=do an apt-get update n=skip apt-get update                      	default=y"
	echo "* -p y|n  y=download packages n=skip download packages                      	default=y"
	echo "* -c y|n  y=compile programs  n=do not compile programs                     	default=y"
	echo "* -d y|n  y=fetch programs from internet (cvs, svn, etc...)  n=do not fetch 	default=y"
	echo "* -j X    Add -jX to the make compilation		                             	default=None"
	echo "* -O X    Add -OX to the make compilation	           				default=None"
	echo "* -r y|n  y=reconfigure programs before compiling them  n=do not reconfigure	default=y"
	echo "* -s compile only last stable known versions					default=y"
	echo "* -w cmake verbose option"
	echo "* -x set -x bash option"
	echo "* -v set -v bash option"
	echo "* -B branch"
	echo "* -R revision"
	echo "* -G osg version"
	
	exit
fi

# --------------------------------------------
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


# ---------------------------------------------------------
# Script Section: Debian Backports
# ---------------------------------------------------------


# Debian 4.0rX (Etch) backports.org
# From D-HUND

ISSUE=$(cat /etc/issue)

# Uncomment following line to confirm backports.org is in sources.list:
#ISSUE=""

if [ "$ISSUE" = "Debian GNU/Linux 4.0 \n \l" ]; then
	clear
	echo "*****************************************************"
	echo "*    Note to users of Debian Etch (Stable 4.0rX)    *"
	echo "*****************************************************"
	echo
	echo "Since autumn 2008 it is not possible anymore to easily install fgfs"
	echo "cvs by using standard repositry. Therefore it is necessary to have"
	echo "backports.org in the apt sources.list to run this script."
	echo
	echo "If you're using synaptic you may follow these steps:"
	echo "  - Open synaptics menu 'Settings' --> 'Repositories'"
	echo "  - Click 'Add' and do"
	echo "      select 'Binaries (deb)'"
	echo "      enter Address:      'www.backports.org/backports.org/'"
	echo "      enter Distribution: 'etch-backports'"
	echo "      enter Section(s):   'main contrib non-free'"
	echo "  - Close Repositries window using 'OK'"
	echo "  - Click 'Reload' to update database."
	echo
	echo "If you have backports.org in your apt-repositries and want to get"
	echo "rid of this message have a look at the script."
	echo -n "[c] to continue or just [ENTER] to exit script: "
	if [ "$(read GOON)" != "c" ]; then
		echo "Script aborted!"
		exit 0
	fi
fi

# ---------------------------------------------------------
# Script Section: Display Options Chosen
# ---------------------------------------------------------

 
echo $0 $* > $LOGFILE

echo "APT_GET_UPDATE=$APT_GET_UPDATE" |tee -a $LOGFILE
echo "DOWNLOAD_PACKAGES=$DOWNLOAD_PACKAGES" |tee -a $LOGFILE
echo "COMPILE=$COMPILE" |tee -a $LOGFILE
echo "RECONFIGURE=$RECONFIGURE" |tee -a $LOGFILE
echo "DOWNLOAD=$DOWNLOAD" |tee -a $LOGFILE
echo "JOPTION=$JOPTION" |tee -a $LOGFILE
echo "OOPTION=$OOPTION" |tee -a $LOGFILE
echo "DEBUG=$DEBUG" |tee -a $LOGFILE
echo "FGSG_VERSION=$FGSG_VERSION" |tee -a LOGFILE
echo "FGSG_REVISION=$FGSG_REVISION" |tee -a LOGFILE
echo "FGDATA_BRANCH=$FGDATA_BRANCH" |tee -a LOGFILE
echo "FGDATA_REVISION=$FGDATA_REVISION" |tee -a LOGFILE
echo "FGDATA_VERSION=$FGDATA_VERSION" |tee -a LOGFILE

echo "$LOGSEP" |tee -a $LOGFILE

# ---------------------------------------------------------
# Script Section: Determine Linux Distribution
# ---------------------------------------------------------

if [ -e /etc/lsb-release ]
then
	. /etc/lsb-release
fi

# default is hardy
DISTRO_PACKAGES="libopenal-dev libalut-dev libalut0 cvs subversion cmake make build-essential automake zlib1g-dev zlib1g libwxgtk2.8-0 libwxgtk2.8-dev fluid gawk gettext libxi-dev libxi6 libxmu-dev libxmu6 libboost-dev libasound2-dev libasound2 libpng12-dev libpng12-0 libjasper1 libjasper-dev libopenexr-dev libboost-serialization-dev git-core libhal-dev libqt4-dev scons python-tk python-imaging-tk libsvn-dev libglew1.5-dev  libxft2 libxft-dev libxinerama1 libxinerama-dev"

UBUNTU_PACKAGES="freeglut3-dev libjpeg62-dev libjpeg62 libapr1-dev libfltk1.3-dev libfltk1.3"

DEBIAN_PACKAGES_STABLE="freeglut3-dev libjpeg8-dev libjpeg8 libfltk1.1-dev libfltk1.1"
DEBIAN_PACKAGES_TESTING="freeglut3-dev libjpeg8-dev libjpeg8 libfltk1.3-dev libfltk1.3"
DEBIAN_PACKAGES_UNSTABLE="freeglut3-dev libjpeg8-dev libjpeg8 libfltk1.3-dev libfltk1.3"

if [ "$DISTRIB_ID" = "Ubuntu" -o "$DISTRIB_ID" = "LinuxMint" ]
then	
	echo "$DISTRIB_ID $DISTRIB_RELEASE" >> $LOGFILE
	DISTRO_PACKAGES="$DISTRO_PACKAGES $UBUNTU_PACKAGES"
else
	echo "DEBIAN I SUPPOUSE" >> $LOGFILE

	DEBIAN_PACKAGES=$DEBIAN_PACKAGES_STABLE
	if [ ! "$(apt-cache search libfltk1.3)" = "" ]
	then
	  #TESTING MAYBE
	  DEBIAN_PACKAGES=$DEBIAN_PACKAGES_TESTING
	fi

	DISTRO_PACKAGES="$DISTRO_PACKAGES $DEBIAN_PACKAGES"
fi
echo "$LOGSEP" >> $LOGFILE

# ---------------------------------------------------------
# Script Section: Install Prerequisite Development Packages
# ---------------------------------------------------------
SET_WINDOW_TITLE "Install Prerequisite Development Packages"


if [ "$DOWNLOAD_PACKAGES" = "y" ]
then
	echo -n "PACKAGE INSTALLATION ... " >> $LOGFILE

	LIBOPENALPACKAGE=$(apt-cache search libopenal | grep "libopenal. " | sed s/\ .*//)
	DISTRO_PACKAGES=$DISTRO_PACKAGES" "$LIBOPENALPACKAGE

	# checking linux distro and version to differ needed packages
	if [ "$DISTRIB_ID" = "Ubuntu" ]
	then
		
		if [ "$APT_GET_UPDATE" = "y" ]
		then
			echo "Asking your password to perform an apt-get update"
			sudo apt-get update
		fi
		

		echo "Asking your password to perform an apt-get install ... "
		sudo apt-get install $DISTRO_PACKAGES 
	else
		# WE ARE USING DEBIAN
		
		if [ "$APT_GET_UPDATE" = "y" ]
		then
			echo "Asking root password to perform an apt-get update"
			su -c "apt-get update"
		fi
		echo "Asking root password to perform an apt-get install ... "
		su -c "apt-get install $DISTRO_PACKAGES"
	fi

	echo " OK" >> $LOGFILE
fi


# -------------------------------------------------------------
# Script Section: Create Required Build and install Directories
# -------------------------------------------------------------
SET_WINDOW_TITLE "Create Required Build and install Directories"

COMPILE_BASE_DIR=.

#cd into compile base directory
cd "$COMPILE_BASE_DIR"

#get absolute path
CBD=$(pwd)

LOGFILE=$CBD/$LOGFILE

echo "DIRECTORY= $CBD" >> $LOGFILE
echo "$LOGSEP" >> $LOGFILE

mkdir -p install

SUB_INSTALL_DIR=install
INSTALL_DIR=$CBD/$SUB_INSTALL_DIR


cd "$CBD"
mkdir -p build

# ---------------------------------------------------------
# Script Section: set script to stop if an error occours
# ---------------------------------------------------------

set -e

# ---------------------------------------------------------
# Script Section: Build Components
# ---------------------------------------------------------

#######################################################
# PLIB
#######################################################
PLIB_INSTALL_DIR=plib
INSTALL_DIR_PLIB=$INSTALL_DIR/$PLIB_INSTALL_DIR

cd "$CBD"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="PLIB"' ]]
then
	if [ ! "$UPDATE" = "UPDATE" ]
	then
		echo "****************************************" | tee -a $LOGFILE
		echo "**************** PLIB ******************" | tee -a $LOGFILE
		echo "****************************************" | tee -a $LOGFILE
		SET_WINDOW_TITLE "Building PLIB"

		echo "COMPILING PLIB" >> $LOGFILE
		echo "INSTALL_DIR_PLIB=$INSTALL_DIR_PLIB" >> $LOGFILE


		PLIB_STABLE_REVISION_=""
		if [ "$STABLE" = "STABLE" ]
		#if [ "STABLE" = "STABLE" ]
		then
			PLIB_STABLE_REVISION_=" -r $PLIB_STABLE_REVISION"
		fi

		if [ "$DOWNLOAD" = "y" ]
		then
			if [ -d "plib/.svn" ]
			then
				echo -n "updating plib svn" >>$LOGFILE
				cd plib
				svn update $PLIB_STABLE_REVISION_
				cd -
            		else
				echo -n "DOWNLOADING FROM http://svn.code.sf.net/p/plib/code/trunk/ ..." >> $LOGFILE
				svn $PLIB_STABLE_REVISION_ co http://svn.code.sf.net/p/plib/code/trunk/ plib  
				echo " OK" >> $LOGFILE
            		fi
		fi 
		cd plib

		if [ "$RECONFIGURE" = "y" ]
		then

			cd "$CBD"
			mkdir -p build/plib


			cd plib

			echo "AUTOGEN plib" >> $LOGFILE
			./autogen.sh 2>&1 | tee  -a $LOGFILE
			echo "CONFIGURING plib" >> $LOGFILE
			cd "$CBD"/build/plib
			../../plib/configure  --disable-pw --disable-sl --disable-psl --disable-ssg --disable-ssgaux  --prefix="$INSTALL_DIR_PLIB" --exec-prefix="$INSTALL_DIR_PLIB" 2>&1 | tee -a $LOGFILE
		else
			echo "NO RECONFIGURE FOR plib" >> $LOGFILE
		fi

		
		if [ "$COMPILE" = "y" ]
		then
			
			echo "MAKE plib" >> $LOGFILE
			echo "make $JOPTION $OOPTION" >> $LOGFILE
			
			cd "$CBD"/build/plib
			make $JOPTION $OOPTION 2>&1 | tee -a $LOGFILE
	
			if [ ! -d $INSTALL_DIR_PLIB ]
			then
				mkdir -p "$INSTALL_DIR_PLIB"
			fi
	
			
			echo "INSTALL plib" >> $LOGFILE
			echo "make install" >> $LOGFILE
			make install 2>&1 | tee -a $LOGFILE
		fi

		cd "$CBD"
	fi
	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# OpenSceneGraph
#######################################################
SET_WINDOW_TITLE "Building OpenSceneGraph"
OSG_INSTALL_DIR=OpenSceneGraph
INSTALL_DIR_OSG=$INSTALL_DIR/$OSG_INSTALL_DIR
cd "$CBD"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="OSG"' ]]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "**************** OSG *******************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE

	if [ "$DOWNLOAD" = "y" ]
	then
		echo -n "SVN FROM $OSG_SVN ... " >> $LOGFILE
		svn co "$OSG_SVN" OpenSceneGraph
		echo " OK" >> $LOGFILE
	fi
	cd OpenSceneGraph

	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then
			cd "$CBD"
			mkdir -p build/osg
			cd "$CBD"/build/osg		
			echo -n "RECONFIGURE OSG ... " >> $LOGFILE
			rm -f CMakeCache.txt ../../OpenSceneGraph/CMakeCache.txt
			cmake ../../OpenSceneGraph/
			echo " OK" >> $LOGFILE



			cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_OSG" ../../OpenSceneGraph/ 2>&1 | tee -a $LOGFILE
			
			echo "RECONFIGURE OSG DONE." >> $LOGFILE
			
		fi
	fi

	if [ "$COMPILE" = "y" ]
	then
		echo "COMPILING OSG" >> $LOGFILE
		cd "$CBD"/build/osg
		make $JOPTION $OOPTION 2>&1 | tee -a $LOGFILE
	
		if [ ! -d $INSTALL_DIR_OSG ]
		then
			mkdir -p "$INSTALL_DIR_OSG"
		fi
	
		echo "INSTALLING OSG" >> $LOGFILE
		make install 2>&1 | tee -a $LOGFILE
	fi
	
	#FIX FOR 64 BIT COMPILATION
	if [ -d "$INSTALL_DIR_OSG/lib64" ]
	then
		if [ -L "$INSTALL_DIR_OSG/lib" ]
		then
			echo "link already done"
		else
			ln -s "$INSTALL_DIR_OSG/lib64" "$INSTALL_DIR_OSG/lib"
		fi
	fi

	cd -
	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# OPENRTI
#######################################################
SET_WINDOW_TITLE "Building OPENRTI"
OPENRTI_INSTALL_DIR=openrti
INSTALL_DIR_OPENRTI=$INSTALL_DIR/$OPENRTI_INSTALL_DIR
cd "$CBD"

if [ ! -d "openrti" ]
then
	mkdir "openrti"
fi

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="OPENRTI"' ]]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "**************** OPENRTI ***************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE


	if [ "$DOWNLOAD" = "y" ]
	then
		cd openrti

		echo -n "git FROM git://gitorious.org/openrti/openrti.git ... " >> $LOGFILE

		if [ -d "openrti" ]
		then
			echo "openrti exists already."
		else
			git clone git://gitorious.org/openrti/openrti.git
		fi

		cd openrti

		git fetch origin
		if [ "$STABLE" = "STABLE" ]
		then
			# switch to stable branch
			# create local stable branch, ignore errors if it exists
			git branch -f $OPENRTI_BRANCH origin/$OPENRTI_BRANCH 2> /dev/null || true
			# switch to stable branch. No error is reported if we're already on the branch.
			git checkout -f $OPENRTI_BRANCH
			# get indicated stable version
			git reset --hard $OPENRTI_REVISION
		else
			# switch to unstable branch
			# create local unstable branch, ignore errors if it exists
			git branch -f $OPENRTI_BRANCH origin/$OPENRTI_BRANCH 2> /dev/null || true
			# switch to unstable branch. No error is reported if we're already on the branch.
			git checkout -f $OPENRTI_BRANCH
			# pull latest version from the unstable branch
			git pull
		fi

		cd ..	

		echo " OK" >> $LOGFILE
		cd ..
	
	fi
	
	cd "openrti/openrti"
	
	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then

			cd "$CBD"
			mkdir -p build/openrti
			cd "$CBD"/build/openrti
			echo -n "RECONFIGURE OPENRTI ... " >> $LOGFILE
			rm -f ../../openrti/openrti/CMakeCache.txt
			cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_OPENRTI" ../../openrti/openrti/ 2>&1 | tee -a $LOGFILE
			echo " OK" >> $LOGFILE



		fi
	fi
	
	if [ "$COMPILE" = "y" ]
	then


		cd "$CBD"/build/openrti
		echo "MAKE OPENRTI" >> $LOGFILE
		echo "make $JOPTION $OOPTION " >> $LOGFILE
		make $JOPTION $OOPTION 2>&1 | tee -a $LOGFILE

		echo "INSTALL OPENRTI" >> $LOGFILE
		make install 2>&1 | tee -a $LOGFILE
	fi
	cd -
	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# SIMGEAR
#######################################################
SET_WINDOW_TITLE "Building Simgear"
SIMGEAR_INSTALL_DIR=simgear
INSTALL_DIR_SIMGEAR=$INSTALL_DIR/$SIMGEAR_INSTALL_DIR
cd "$CBD"

if [ ! -d "simgear" ]
then
	mkdir "simgear"
fi

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="SIMGEAR"' ]]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "**************** SIMGEAR ***************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE


	if [ "$DOWNLOAD" = "y" ]
	then
		cd simgear
		#echo -n "CVS FROM cvs.simgear.org:/var/cvs/SimGear-0.3 ... " >> $LOGFILE
		#cvs -z5 -d :pserver:cvsguest:guest@cvs.simgear.org:/var/cvs/SimGear-0.3 login
		#cvs -z5 -d :pserver:cvsguest@cvs.simgear.org:/var/cvs/SimGear-0.3 co source


		echo -n "git FROM git://gitorious.org/fg/simgear.git ... " >> $LOGFILE

		if [ -d "simgear" ]
		then
			echo "simgear exists already."
		else
			git clone git://gitorious.org/fg/simgear.git
		fi

		cd simgear

		git fetch origin
		if [ "$STABLE" = "STABLE" ]
		then
			# switch to stable branch
			# create local stable branch, ignore errors if it exists
			git branch -f $FGSG_BRANCH origin/$FGSG_BRANCH 2> /dev/null || true
			# switch to stable branch. No error is reported if we're already on the branch.
			git checkout -f $FGSG_BRANCH
			# get indicated stable version
			git reset --hard $SIMGEAR_STABLE_REVISION
		else
			# switch to unstable branch
			# create local unstable branch, ignore errors if it exists
			git branch -f $FGSG_BRANCH origin/$FGSG_BRANCH 2> /dev/null || true
			# switch to unstable branch. No error is reported if we're already on the branch.
			git checkout -f $FGSG_BRANCH
			# pull latest version from the unstable branch
			git pull
		fi

		cd ..	

		echo " OK" >> $LOGFILE
		cd ..
	
	fi
	

	cd "simgear/simgear"
	
	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then

			cd "$CBD"
			mkdir -p build/simgear
			cd "$CBD"/build/simgear
			echo -n "RECONFIGURE SIMGEAR ... " >> $LOGFILE
			rm -f ../../simgear/simgear/CMakeCache.txt
			rm -f CMakeCache.txt
			cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" $WITH_OPENRTI -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_SIMGEAR" -D "CMAKE_PREFIX_PATH=$INSTALL_DIR_OSG;$INSTALL_DIR_OPENRTI" ../../simgear/simgear/ 2>&1 | tee -a $LOGFILE
			echo " OK" >> $LOGFILE



		fi
	fi
	
	if [ "$COMPILE" = "y" ]
	then


		cd "$CBD"/build/simgear
		echo "MAKE SIMGEAR" >> $LOGFILE
		echo "make $JOPTION $OOPTION " >> $LOGFILE
		make $JOPTION $OOPTION 2>&1 | tee -a $LOGFILE

		echo "INSTALL SIMGEAR" >> $LOGFILE
		make install 2>&1 | tee -a $LOGFILE
	fi
	cd -
	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# FGFS
#######################################################
SET_WINDOW_TITLE "Building Flightgear"
FGFS_INSTALL_DIR=fgfs
INSTALL_DIR_FGFS=$INSTALL_DIR/$FGFS_INSTALL_DIR
cd "$CBD"

if [ ! -d "fgfs" ]
then
	mkdir "fgfs"
fi

#if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "FGFS" -o "$WHATTOBUILD" = "DATA" -o "$WHATTOBUILD" = "ALL" ]
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGFS"' || "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="DATA"' ]]
then

	echo "****************************************" | tee -a $LOGFILE
	echo "**************** FGFS ******************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE

	cd fgfs

	if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGFS"' ]]
	then
		if [ "$DOWNLOAD" = "y" ]
		then
			#echo -n "CVS FROM cvs.flightgear.org:/var/cvs/FlightGear-0.9 ... " >> $LOGFILE
			#cvs -z5 -d :pserver:cvsguest:guest@cvs.flightgear.org:/var/cvs/FlightGear-0.9 login
			#cvs -z5 -d :pserver:cvsguest@cvs.flightgear.org:/var/cvs/FlightGear-0.9 co source

			echo -n "GIT FROM git://gitorious.org/fg/flightgear.git ... " >> $LOGFILE
			

			if [ -d "flightgear" ]
			then
				echo "flightgear exists already."
			else
				git clone git://gitorious.org/fg/flightgear.git
			fi

			cd flightgear
		# fix for CMakeLists.txt broken by fltk issues on Ubuntu 13.10

			git fetch origin
			if [ "$STABLE" = "STABLE" ]
			then
				# switch to stable branch
				# create local stable branch, ignore errors if it exists
				git branch -f $FGSG_BRANCH origin/$FGSG_BRANCH 2> /dev/null || true
				# switch to stable branch. No error is reported if we're already on the branch.
				git checkout -f $FGSG_BRANCH
				# get indicated stable version
				git reset --hard $FGFS_STABLE_REVISION
			else
				# switch to unstable branch
				# create local unstable branch, ignore errors if it exists
				git branch -f $FGSG_BRANCH origin/$FGSG_BRANCH 2> /dev/null || true
				# switch to unstable branch. No error is reported if we're already on the branch.
				git checkout -f $FGSG_BRANCH
				# pull latest version from the unstable branch
				git pull
			fi

			cd ..	

			echo " OK" >> $LOGFILE

		fi
		
		cd flightgear
		if [[ $(grep -L 'list(APPEND FLTK_LIBRARIES ${CMAKE_DL_LIBS})' CMakeLists.txt) != "" ]]
		then
		patch  CMakeLists.txt <<\EOF
--- fgfs/flightgear/CMakeLists.txt_old	2013-08-04 08:59:00.614104454 -0400
+++ fgfs/flightgear/CMakeLists.txt_new	2013-08-04 09:03:32.430104979 -0400
@@ -203,6 +203,10 @@
             list(APPEND FLTK_LIBRARIES ${X11_Xft_LIB})
         endif()
 
+	if ( CMAKE_DL_LIBS )
+	     list(APPEND FLTK_LIBRARIES ${CMAKE_DL_LIBS}) 
+    	endif()
+
         message(STATUS "Using FLTK_LIBRARIES for fgadmin: ${FLTK_LIBRARIES}")
     endif ( FLTK_FOUND )
 endif(ENABLE_FGADMIN)
EOF
fi
		if [ ! "$UPDATE" = "UPDATE" ]
		then
			if [ "$RECONFIGURE" = "y" ]
			then
				#echo "AUTOGEN FGFS" >> $LOGFILE
				#./autogen.sh 2>&1 | tee -a $LOGFILE
				#echo "CONFIGURE FGFS" >> $LOGFILE
			   	#echo ./configure "$DEBUG" $WITH_EVENT_INPUT --prefix=$INSTALL_DIR_FGFS --exec-prefix=$INSTALL_DIR_FGFS --with-osg="$INSTALL_DIR_OSG" --with-simgear="$INSTALL_DIR_SIMGEAR" --with-plib="$INSTALL_DIR_PLIB" 
				#./configure "$DEBUG" $WITH_EVENT_INPUT --prefix=$INSTALL_DIR_FGFS --exec-prefix=$INSTALL_DIR_FGFS --with-osg="$INSTALL_DIR_OSG" --with-simgear="$INSTALL_DIR_SIMGEAR" --with-plib="$INSTALL_DIR_PLIB" 2>&1 | tee -a $LOGFILE


	                        cd "$CBD"
       				mkdir -p build/fgfs
	                        cd "$CBD"/build/fgfs


				echo -n "RECONFIGURE FGFS ... " >> $LOGFILE
				rm -f ../../fgfs/flightgear/CMakeCache.txt
				rm -f CMakeCache.txt

				# REMOVING BAD LINES IN CMakeLists.txt
				#echo "REMOVING BAD LINES IN CMakeLists.txt"
				#cat utils/fgadmin/src/CMakeLists.txt  | sed /X11_Xft_LIB/d | sed /X11_Xinerama_LIB/d > utils/fgadmin/src/CMakeLists_without_err.txt
				#cp -f  utils/fgadmin/src/CMakeLists_without_err.txt utils/fgadmin/src/CMakeLists.txt

		
				cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" $WITH_OPENRTI -D "WITH_FGPANEL=OFF" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGFS" -D "CMAKE_PREFIX_PATH=$INSTALL_DIR_OSG;$INSTALL_DIR_PLIB;$INSTALL_DIR_SIMGEAR;$INSTALL_DIR_OPENRTI" ../../fgfs/flightgear 2>&1 | tee -a $LOGFILE

				echo " OK" >> $LOGFILE
			fi
		fi
		
		if [ "$COMPILE" = "y" ]
		then
                        cd "$CBD"
                        mkdir -p build/fgfs
                        cd "$CBD"/build/fgfs

			echo "MAKE FGFS" >> $LOGFILE
			echo "make $JOPTION $OOPTION" >> $LOGFILE
			make $JOPTION $OOPTION 2>&1 | tee -a $LOGFILE

			echo "INSTALL FGFS" >> $LOGFILE
			make install 2>&1 | tee -a $LOGFILE
		fi
		cd ..
	fi
	cd ..

	if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="DATA"' ]]
	then
		if [ ! "$UPDATE" = "UPDATE" ]
		then
			if [ "$DOWNLOAD" = "y" ]
			then
				SET_WINDOW_TITLE " FGDATA"
				if [[  -e ../fgdata_${FGDATA_VERSION} ]]
				then
					FGDATA_DIR=../fgdata_${FGDATA_VERSION}
				fi
				if [[  -e ../../fgdata_${FGDATA_VERSION} ]]
				then
					FGDATA_DIR=../../fgdata_${FGDATA_VERSION}
				fi
				if [[ ! -e $INSTALL_DIR_FGFS/fgdata && -e ${FGDATA_DIR} ]]
				then
					ln -s ${FGDATA_DIR} $INSTALL_DIR_FGFS/fgdata
					ls -lah $INSTALL_DIR_FGFS/fgdata
				fi
				EXDIR=$(pwd)
				cd $INSTALL_DIR_FGFS
				echo -n "GIT DATA FROM $fgdata_git  ... " |tee -a $LOGFILE

				if [ -d "fgdata" ]
				then
					echo "fgdata exists already."
				else
					# no repository yet - need to clone a fresh one
					git clone $fgdata_git fgdata
				fi

				cd $INSTALL_DIR_FGFS/fgdata
				git remote set-url origin $fgdata_git
				git fetch origin
				if [ "$STABLE" = "STABLE" ]
				then
					# switch to stable branch
					# create local stable branch, ignore errors if it exists
					git branch -f $FGSG_BRANCH origin/$FGSG_BRANCH 2> /dev/null || true
					# switch to stable branch. No error is reported if we're already on the branch.
					git checkout -f $FGSG_BRANCH
					# get indicated stable version
					git reset --hard $FGSG_BRANCH
				else
					# switch to unstable branch
					# create local unstable branch, ignore errors if it exists
					git branch -f $FGDATA_BRANCH origin/$FGDATA_BRANCH 2> /dev/null || true
					# switch to unstable branch. No error is reported if we're already on the branch.
					git checkout -f $FGDATA_BRANCH
					# pull latest version from the unstable branch
					git pull
				fi

				cd ..

				echo " OK" >> $LOGFILE
				cd "$EXDIR"
			fi
		fi
	fi

	cd "$CBD"

	# IF SEPARATED FOLDER FOR AIRCRAFTS
	# --fg-aircraft=\$PWD/../aircrafts
	cat > run_fgfs.sh << ENDOFALL
#!/bin/sh
cd \$(dirname \$0)
cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin
export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib:../../$OPENRTI_INSTALL_DIR/lib
./fgfs --fg-root=\$PWD/../fgdata/ \$@
ENDOFALL
	chmod 755 run_fgfs.sh

	cat > run_fgfs_debug.sh << ENDOFALL2
#!/bin/sh
cd \$(dirname \$0)
P1=\$PWD
cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin
export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib:../../$OPENRTI_INSTALL_DIR/lib
gdb  --directory="\$P1"/fgfs/source/src/ --args fgfs --fg-root=\$PWD/../fgdata/ \$@
ENDOFALL2
	chmod 755 run_fgfs_debug.sh

	SCRIPT=run_terrasync.sh
	echo "#!/bin/sh" > $SCRIPT
	echo "cd \$(dirname \$0)" >> $SCRIPT
	echo "cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin" >> $SCRIPT
	echo "export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> $SCRIPT
	echo "./terrasync \$@" >> $SCRIPT
	chmod 755 $SCRIPT

	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# FGO!
#######################################################
SET_WINDOW_TITLE "Building FGO"
FGO_INSTALL_DIR=fgo
INSTALL_DIR_FGO=$INSTALL_DIR/$FGO_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGO"' ]]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "***************** FGO ******************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE

	if [ "$DOWNLOAD" = "y" ]
	then
		wget http://sites.google.com/site/erobosprojects/flightgear/add-ons/fgo/download/fgo-1-3-1.tar.gz?attredirects=0 -O fgo-1-3-1.tar.gz
		cd install
		tar zxvf ../fgo-1-3-1.tar.gz

		cat fgo/src/gui.py | sed s/"self.process = subprocess.Popen".*/"self.process = subprocess.Popen(self.options, cwd=self.FG_working_dir,env=os.environ)"/g > fgo/src/gui.py-new
		mv fgo/src/gui.py-new fgo/src/gui.py
		cd ..
		
	fi

	SCRIPT=run_fgo.sh
	echo "#!/bin/sh" > $SCRIPT
	echo "cd \$(dirname \$0)" >> $SCRIPT
	echo "cd $SUB_INSTALL_DIR" >> $SCRIPT
	echo "p=\$(pwd)" >> $SCRIPT
	echo "cd $FGO_INSTALL_DIR" >> $SCRIPT
        echo "export LD_LIBRARY_PATH=\$p/plib/lib:\$p/OpenSceneGraph/lib:\$p/simgear/lib"  >> $SCRIPT
	echo "python fgo" >> $SCRIPT
	chmod 755 $SCRIPT

	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# FGx
#######################################################
SET_WINDOW_TITLE "Building FGX"
FGX_INSTALL_DIR=fgx
INSTALL_DIR_FGX=$INSTALL_DIR/$FGX_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGX"' ]]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "***************** FGX ******************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE

	if [ "$DOWNLOAD" = "y" ]
	then

		echo -n "git clone git://gitorious.org/fgx/fgx.git ... " >> $LOGFILE

		if [ -d "fgx" ]
		then
			echo "fgx exists already."
		else
			git clone git://gitorious.org/fgx/fgx.git fgx
		fi

		echo " OK" >> $LOGFILE

	fi

	cd fgx/

	git branch -f $FGX_BRANCH origin/$FGX_BRANCH 2> /dev/null || true
	git checkout -f $FGX_BRANCH
	git pull

	cd ..

	cd fgx/src/

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


	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then

			echo -n "RECONFIGURE FGX ... " >> $LOGFILE

			mkdir -p $INSTALL_DIR_FGX
			cd $INSTALL_DIR_FGX

			qmake ../../fgx/src

			echo " OK" >> $LOGFILE
		fi
	fi
	
	if [ "$COMPILE" = "y" ]
	then
		cd $INSTALL_DIR_FGX
		echo "MAKE AND INSTALL FGX" >> $LOGFILE
		echo "make $JOPTION $OOPTION " >> $LOGFILE
		make $JOPTION $OOPTION | tee -a $LOGFILE
		cd ..
	fi

	cd "$CBD"

	SCRIPT=run_fgx.sh
	echo "#!/bin/sh" > $SCRIPT
	echo "cd \$(dirname \$0)" >> $SCRIPT
	echo "cd $SUB_INSTALL_DIR" >> $SCRIPT
	echo "p=\$(pwd)" >> $SCRIPT
	echo "cd $FGX_INSTALL_DIR" >> $SCRIPT
        echo "export LD_LIBRARY_PATH=\$p/plib/lib:\$p/OpenSceneGraph/lib:\$p/simgear/lib"  >> $SCRIPT
	echo "./fgx" >> $SCRIPT
	chmod 755 $SCRIPT

	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# FGRUN
#######################################################
SET_WINDOW_TITLE "Building FGRUN"
FGRUN_INSTALL_DIR=fgrun
INSTALL_DIR_FGRUN=$INSTALL_DIR/$FGRUN_INSTALL_DIR
cd "$CBD"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGRUN"' ]]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "**************** FGRUN *****************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE


		if [ "$DOWNLOAD" = "y" ]
		then
			#echo -n "CVS FROM cvs.flightgear.org:/var/cvs/FlightGear-0.9 ... " >> $LOGFILE
			#cvs -z5 -d :pserver:cvsguest:guest@cvs.flightgear.org:/var/cvs/FlightGear-0.9 login
			#cvs -z5 -d :pserver:cvsguest@cvs.flightgear.org:/var/cvs/FlightGear-0.9 co source

			echo -n "GIT FROM git://gitorious.org/fg/fgrun.git ... " >> $LOGFILE
			

			if [ -d "fgrun" ]
			then
				echo "fgrun exists already."
			else
				git clone git://gitorious.org/fg/fgrun.git fgrun
			fi

			cd fgrun
if [[ $(grep -L 'list(APPEND FLTK_LIBRARIES ${CMAKE_DL_LIBS})' CMakeLists.txt) != "" ]]
then
patch  CMakeLists.txt <<\EOD
--- master/fgrun/CMakeLists.txt	2013-05-25 06:37:31.882942339 -0400
+++ next/fgrun/CMakeLists.txt	2013-08-04 07:54:59.274097042 -0400
@@ -212,6 +212,10 @@ if ( FLTK_FOUND )
         list(APPEND FLTK_LIBRARIES ${X11_Xft_LIB})
     endif()
 
+    if ( CMAKE_DL_LIBS )
+       list(APPEND FLTK_LIBRARIES ${CMAKE_DL_LIBS}) 
+    endif()
+
     set( CMAKE_REQUIRED_INCLUDES ${FLTK_INCLUDE_DIR} )
     set( CMAKE_REQUIRED_LIBRARIES ${FLTK_LIBRARIES} )
     message(STATUS "Using FLTK_LIBRARIES for fgrun: ${FLTK_LIBRARIES}")
EOD
fi
			git fetch origin
			if [ "$STABLE" = "STABLE" ]
			then
				# switch to stable branch
				# create local stable branch, ignore errors if it exists
				ls
				git branch -f $FGRUN_BRANCH origin/$FGRUN_BRANCH 2> /dev/null || true
				# switch to stable branch. No error is reported if we're already on the branch.
				git checkout -f $FGRUN_BRANCH
				# get indicated stable version
				git reset --hard $FGRUN_BRANCH
			else
				# switch to unstable branch
				# create local unstable branch, ignore errors if it exists
				git branch -f $FGRUN_BRANCH origin/$FGRUN_BRANCH 2> /dev/null || true
				# switch to unstable branch. No error is reported if we're already on the branch.
				git checkout -f $FGRUN_BRANCH
				# pull latest version from the unstable branch
				git pull
			fi

			cd ..	

			echo " OK" >> $LOGFILE

		fi
		
		cd fgrun


	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then
                        cd "$CBD"
                        mkdir -p build/fgrun
                        cd "$CBD"/build/fgrun

			echo -n "RECONFIGURE FGRUN ... " >> $LOGFILE
			rm -f ../../fgrun/CMakeCache.txt
			rm -f CMakeCache.txt
			
			cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGRUN" -D "CMAKE_PREFIX_PATH=$INSTALL_DIR_OSG;$INSTALL_DIR_PLIB;$INSTALL_DIR_SIMGEAR" ../../fgrun/ 2>&1 | tee -a $LOGFILE

			echo " OK" >> $LOGFILE
		fi
	fi
	
	if [ "$COMPILE" = "y" ]
	then
		cd "$CBD"/build/fgrun

		echo "MAKE FGRUN" >> $LOGFILE
		echo "make $JOPTION $OOPTION" >> $LOGFILE
		make $JOPTION $OOPTION 2>1 | tee -a $LOGFILE

		echo "INSTALL FGRUN" >> $LOGFILE
		make install 2>&1 | tee -a $LOGFILE
	fi

	cd "$CBD"

	SCRIPT=run_fgrun.sh
	echo "#!/bin/sh" > $SCRIPT
	echo "cd \$(dirname \$0)" >> $SCRIPT
	echo "cd $SUB_INSTALL_DIR/$FGRUN_INSTALL_DIR/bin" >> $SCRIPT
	echo "export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> $SCRIPT
	#echo "export FG_AIRCRAFTS=\$PWD/../../$FGFS_INSTALL_DIR/aircrafts" >> $SCRIPT
	echo "./fgrun --fg-exe=\$PWD/../../$FGFS_INSTALL_DIR/bin/fgfs --fg-root=\$PWD/../../$FGFS_INSTALL_DIR/fgdata   \$@" >> $SCRIPT
	chmod 755 $SCRIPT


	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# FGCOM
#######################################################
SET_WINDOW_TITLE "Building FGCOM"
FGCOM_INSTALL_DIR=fgcom
INSTALL_DIR_FGCOM=$INSTALL_DIR/$FGCOM_INSTALL_DIR
cd "$CBD"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGCOM"' ]]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "**************** FGCOM *****************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE


	#svn checkout svn://svn.dfn.de:/fgcom/trunk fgcom
	if [ "$DOWNLOAD" = "y" ]
	then
		echo -n "git://gitorious.org/fg/fgcom.git ... " >> $LOGFILE

		if [ -d "fgcom" ]
		then 
			echo "fgcom exists already."
		else   
	                git clone git://gitorious.org/fg/fgcom.git
		fi

		cd fgcom
		git fetch origin
			
                # create local unstable branch, ignore errors if it exists
                git branch -f $FGCOM_UNSTABLE_GIT_BRANCH origin/$FGCOM_UNSTABLE_GIT_BRANCH 2> /dev/null || true
                 # switch to unstable branch. No error is reported if we're already on the branch.
                git checkout -f $FGCOM_UNSTABLE_GIT_BRANCH
                # pull latest version from the unstable branch
                git pull
		
		
		echo " OK" >> $LOGFILE
		cd ..
			
#patch for new netdb.h version.
		cat fgcom/iaxclient/lib/libiax2/src/iax.c | sed s/hp-\>h_addr,/hp-\>h_addr_list[0],/g > fgcom/iaxclient/lib/libiax2/src/iax_ok.c
		mv fgcom/iaxclient/lib/libiax2/src/iax_ok.c fgcom/iaxclient/lib/libiax2/src/iax.c
	fi
	
	cd "$CBD"
	if [ -d "fgcom" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then
		cd "$CBD"/fgcom

			cd "$CBD"
			mkdir -p build/fgcom

			cd "$CBD"/build/fgcom
			echo -n "RECONFIGURE FGCOM ... " >> $LOGFILE
			rm -f CMakeCache.txt
			# add -lpthread for UNIX
			cmake ${VERBOSE_MAKEFILE} -DCMAKE_SKIP_INSTALL_RPATH:BOOL=TRUE  -DCMAKE_SKIP_RPATH:BOOL=TRUE -DFIND_PTHREAD_LIB:BOOL=TRUE -D CMAKE_BUILD_TYPE="Release" -D "CMAKE_PREFIX_PATH=$INSTALL_DIR_PLIB"  -D "CMAKE_INSTALL_PREFIX:PATH=$INSTALL_DIR_FGCOM" "$CBD"/fgcom   2>&1  | tee -a $LOGFILE

			echo " OK" >> $LOGFILE

			cd "$CBD"/fgcom/src/

		fi

		cd "$CBD"/build/fgcom

		mkdir -p "$INSTALL_DIR_FGCOM"/bin

		if [ "$COMPILE" = "y" ]
		then
			echo "MAKE FGCOM" >> $LOGFILE
			echo "cmake --build . --config Release" >> $LOGFILE
			cmake --build . --config Release 2>&1 | tee -a $LOGFILE
		
			echo "INSTALL FGCOM" >> $LOGFILE
			cmake ${VERBOSE_MAKEFILE} -DBUILD_TYPE=Release -P cmake_install.cmake 2>&1 | tee -a $LOGFILE
		fi
		cd "$CBD"

		echo "#!/bin/sh" > run_fgcom.sh
		echo "cd \$(dirname \$0)" >> run_fgcom.sh
		echo "cd $SUB_INSTALL_DIR/$FGCOM_INSTALL_DIR/bin" >> run_fgcom.sh
		echo "export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> run_fgcom.sh
		echo "./fgcom -Sfgcom.flightgear.org.uk  \$@" >> run_fgcom.sh
		chmod 755 run_fgcom.sh
	fi
	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# FGCOMGUI
#######################################################
SET_WINDOW_TITLE "Building FGCOMGUI"
FGCOMGUI_INSTALL_DIR=fgcomgui
INSTALL_DIR_FGCOMGUI=$INSTALL_DIR/$FGCOMGUI_INSTALL_DIR
cd "$CBD"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGCOMGUI"' ]]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "*************** FGCOMGUI ***************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE


	#svn checkout svn://svn.dfn.de:/fgcom/trunk fgcom
	if [ "$DOWNLOAD" = "y" ]
	then
		FGCOMGUI_STABLE_REVISION_=""
		if [ "$STABLE" = "STABLE" ]
		then
			FGCOMGUI_STABLE_REVISION_=" -r $FGCOMGUI_STABLE_REVISION"
		fi

		echo -n "SVN FROM https://fgcomgui.googlecode.com/svn/trunk ... " >> $LOGFILE
		svn $FGCOMGUI_STABLE_REVISION_ co https://fgcomgui.googlecode.com/svn/trunk fgcomgui 
		echo " OK" >> $LOGFILE
		
	fi
	
	if [ -d "fgcomgui" ]
	then
		cd fgcomgui/
	
		mkdir -p "$INSTALL_DIR_FGCOMGUI"

		if [ "$COMPILE" = "y" ]
		then
			echo "SCONS FGCOMGUI" >> $LOGFILE
			echo "scons prefix=\"$INSTALL_DIR_FGCOMGUI\" $JOPTION" >> $LOGFILE
			scons prefix="$INSTALL_DIR_FGCOMGUI" $JOPTION 2>&1 | tee -a $LOGFILE
			echo "INSTALL FGCOM" >> $LOGFILE
			scons install 2>&1 | tee -a $LOGFILE
		fi
		cd "$CBD"

		echo "#!/bin/sh" > run_fgcomgui.sh
		echo "cd \$(dirname \$0)" >> run_fgcomgui.sh
		echo "cd $SUB_INSTALL_DIR/$FGCOMGUI_INSTALL_DIR/bin" >> run_fgcomgui.sh
		echo "export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> run_fgcomgui.sh
		echo "export PATH=../../fgcom/bin/:$PATH" >> run_fgcomgui.sh
		echo "./fgcomgui \$@" >> run_fgcomgui.sh
		chmod 755 run_fgcomgui.sh
	fi

	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi
#######################################################
# OPENRADAR
#######################################################
SET_WINDOW_TITLE "Building OPENRADAR"
OR_INSTALL_DIR=openradar
INSTALL_DIR_OR=$INSTALL_DIR/$OR_INSTALL_DIR
cd "$CBD"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="OPENRADAR"' ]]
then
	echo "****************************************" 
	echo "************** OPENRADAR ***************" 
	echo "****************************************" 


	if [ "$DOWNLOAD" = "y" ]
	then
		wget $OR_STABLE_RELEASE -O OpenRadar.zip
		cd install
		unzip ../OpenRadar.zip
		cd ..
	fi

	echo "#!/bin/sh" > run_openradar.sh
	echo "cd \$(dirname \$0)" >> run_openradar.sh
	echo "cd install/OpenRadar" >> run_openradar.sh
	echo "java -jar OpenRadar.jar" >> run_openradar.sh
	chmod 755 run_openradar.sh
	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# ATLAS
#######################################################
SET_WINDOW_TITLE "Building ATLAS"
ATLAS_INSTALL_DIR=atlas
INSTALL_DIR_ATLAS=$INSTALL_DIR/$ATLAS_INSTALL_DIR
cd "$CBD"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="ATLAS"' ]]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "**************** ATLAS *****************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE

	if [ "$DOWNLOAD" = "y" ]
	then
		echo -n "CSV FROM atlas.cvs.sourceforge.net:/cvsroot/atlas ... " >> $LOGFILE
		cvs -z3 -d:pserver:anonymous@atlas.cvs.sourceforge.net:/cvsroot/atlas co Atlas
		echo " OK" >> $LOGFILE

		echo "fixing old function name \".get_gbs_center2(\" in Subbucket.cxx"
		cd Atlas/src
		cp Subbucket.cxx Subbucket.cxx.original
		cat Subbucket.cxx.original | sed s/\.get_gbs_center2\(/\.get_gbs_center\(/g > Subbucket.cxx
		cd "$CBD"
	fi
	
	if [ -d "Atlas" ]
	then
		cd Atlas

		if [ ! "$UPDATE" = "UPDATE" ]
		then
			if [ "$RECONFIGURE" = "y" ]
			then

				cd "$CBD"
		                mkdir -p build/atlas

				cd Atlas
				echo "AUTOGEN ATLAS" >> $LOGFILE
				./autogen.sh 2>&1 | tee -a $LOGFILE
				echo "CONFIGURE ATLAS" >> $LOGFILE
				cd "$CBD"/build/atlas
				../../Atlas/configure --prefix=$INSTALL_DIR_ATLAS --exec-prefix=$INSTALL_DIR_ATLAS  --with-plib=$INSTALL_DIR_PLIB --with-simgear="$INSTALL_DIR_SIMGEAR" --with-fgbase="$INSTALL_DIR_FGFS/fgdata" CXXFLAGS="$CXXFLAGS -I$CBD/OpenSceneGraph/include" 2>&1 | tee -a $LOGFILE
				make clean
			fi
		fi
		if [ "$COMPILE" = "y" ]
		then
			echo "MAKE ATLAS" >> $LOGFILE
			echo "make $JOPTION $OOPTION" >> $LOGFILE
		
			cd "$CBD"/build/atlas
			make $JOPTION $OOPTION 2>&1 | tee -a $LOGFILE

			echo "INSTALL ATLAS" >> $LOGFILE
			make install 2>&1 | tee -a $LOGFILE
		fi
		cd "$CBD"

		echo "#!/bin/sh" > run_atlas.sh
		echo "cd \$(dirname \$0)" >> run_atlas.sh
		echo "cd $SUB_INSTALL_DIR/$ATLAS_INSTALL_DIR/bin" >> run_atlas.sh
		echo "export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> run_atlas.sh
		echo "./Atlas --fg-root=\$PWD/../../$FGFS_INSTALL_DIR/fgdata \$@" >> run_atlas.sh
		chmod 755 run_atlas.sh
	fi
fi
SET_WINDOW_TITLE "Finished Building"
echo "		finished at $(date)" >>download_and_compile.log
echo "" >>download_and_compile.log

check_build "$CBD"

echo "To start fgfs, run the run_fgfs.sh file"
echo "To start terrasync, run the run_terrasync.sh file"
echo "To start fgrun, run the run_fgrun.sh file"
echo "To start fgcom, run the run_fgcom.sh file"
echo "To start fgcom GUI, run the run_fgcomgui.sh file"
echo "To start atlas, run the run_atlas.sh file"

if [ "$HELP" = "HELP" ]
then
	echo ""
else
	echo "Usage: $0 -h"
	echo "for help"
	echo "$rebuild"  >rebuild
	chmod +x rebuild
fi




