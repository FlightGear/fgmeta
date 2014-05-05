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

# Setting up for download_and_compile.sh is documented 
# on 

VERSION="1.9-14a" 
# See change log below
# 
# Changes in 1.9.14a
# 
# fixed distribution detection.
#
# Changes in 1.9.14
# 1. Version bump for 2.99.9 now 3.0.0
# 2. changed logging to log entire output of a sub-process 
#    rather than write individual lines of output to a logfile.
# 3. logs are versioned.
# 4. fix to support a change in fgdata version when fgdata is a symlink
# 5. Automatic j option # of cores + 1
# 6. fixed stable fgrun build 
# 7. stable is now 2.12.0 for fgfs & simgear, 2.12.1 for fgdata
# 8. fixed broken stable build for 2.12.0
# 9. Added section on setup
# 10. once built, unless specifically requested by parameter OSG or PLIB:
#	Don't rebuild OSG or plib 
#       Don't update OSG or plib sources
# 12. self testing with ./download_and_compile.sh test.  
#
# Note: using the self test multiple times can cause problems.  Only so much bandwidth is allocated
#       to you when downloading OSG.  Use it up and you will be shut off for a while.  As an alternative
#       provide copies of the OSG sources in the same directory as download_and_compile.sh
# 	the copy should be labeled with the version of OSG it contains. OpenSceneGraph-3.0.1 and OpenSceneGraph-3.2.0
#       plib is handled the same way, but only one version of it exists so its just plib.
#
#	the symptom of overuse of svn.openscenegraph.org is:
#	svn: E175002: OPTIONS of 'http://svn.openscenegraph.org/osg/OpenSceneGraph/tags/OpenSceneGraph-3.0.1': 
#	could not connect to server (http://svn.openscenegraph.org)
#
# setup and minimal instructions: 
# see http://wiki.flightgear.org/Scripted_Compilation_on_Linux_Debian/Ubuntu#Cut_to_the_Chase:_for_the_impatient
#

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
# Script Section: Self Test
# ---------------------------------------------------------

function self_test_one(){
	test_dir="$1$3"
	test_options_and_parameters="$2"
	test_sub_dir="$3"
	mkdir -p ${test_dir}${test_sub_dir} 
	if [[ "$test_sub_dir" != "" ]]
	then
		cp -f download_and_compile.sh ${test_dir}/../
	fi

	cd ${test_dir}
	$test_start_dir/download_and_compile.sh $test_options_and_parameters

	cd $test_start_dir
	if [[ -e $test_dir/install/fgfs/bin/fgfs && -e $test_dir/install/fgrun/bin/fgrun ]]
	then	
		test_dir="$1"
		touch ${test_dir}_ok
		ls -lah  ${test_dir}/install/fgfs
	else	
		test_dir="$1"
		touch ${test_dir}_failed
	fi
	echo '----------------------------------------------------------'
	echo '----------------------------------------------------------'
	echo '----------------------------------------------------------'
	echo                Finished test build in ${test_dir}
	echo '----------------------------------------------------------'
	echo '----------------------------------------------------------'
	echo '----------------------------------------------------------'

}
if [[ "$1" = "selftest" || "$1" = "test" ]]
then
	# this takes a LOT of disk space.
	set -x
	set -v
	test_start_dir=$(pwd)
	pwd
	ls
	if [[ "$2" = "reset" ]]
	then
		rm -rf b_stable 
		rm -rf b_next
		rm -rf b_master
		rm -rf b_3.0.0
		rm -rf b_2.12.1
		rm -rf b_selftest
	fi
	if test -n "$(find . -maxdepth 1 -name 'b_*_ok' -print -quit)"
	then	
		rm b_*_ok
	fi
	if test -n "$(find . -maxdepth 1 -name 'b_*_failed' -print -quit)"
	then	
		rm b_*_failed
	fi
	mkdir -p fgsrc
	mkdir -p othersrc

	# fgdata_2.12.0 and fgdata_3.0.0 contain complete copies of fgdata
	# so multiple versions can be built and then tested.
	# the fgdata_ directories can exist in  ../, ../../ or ../../..
	# if you already have an fgdata downloaded for 2.12.0, 2.12.1 or 3.0.0, 
	# you can copy the entire fgdata folder to any empty fgdata_ folder in the
	# same folder as download_and_compile.sh is being tested from The script will use these 
        # where appropriate.  If you choose not to put an fgdata in the fgdata_${version} directories,
        # fgdata will be downloaded and place there for future use. 
	 
	# mv $path_to_fgdata_2.12/fgdata -R fgdata_2.12.0/
	# mv $path_to_fgdata_3.0.0/fgdata -R fgdata_3.0.0/

	self_test_one b_stable   "-sxvp n"		              
	self_test_one b_next     "-xvp n -G 3.2.0" 	            
	self_test_one b_2.12.1   "-xvp n -B release/2.12.1 -G 3.2.0" 
	self_test_one b_3.0.0    "-xvp n -B release/3.0.0 -G 3.2.0"  
	self_test_one b_master   "-xvp n -B master -G 3.2.0"  	    
	self_test_one b_selftest "-xvp n  -G 3.2.0" 	  		"/selftest/selftest"

	# note the b_selftest is guaranteed to download everything but OSG and plib.

	echo "Test Results:"

	ls -l |grep ' b_*'
 	exit 0
fi

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
function write_log_and_exec_subprocess(){
	write_log "$1 $2"
	if [[ "$3" = "noerror" ]]
	then
		$1 2>/dev/null || true
	else
		$1
	fi
}	
function git_check_branch_or_tag(){
	if [[ "$1" != "" ]]
	then
		branch="$(git branch |sed "s/* //" |grep $1)"
		tag="$(git tag |sed "s/* //" |grep $1)"
		echo $branch$tag
	fi
}
function SET_WINDOW_TITLE(){
	echo -ne "\033]0;Build Flightgear:  -  ${current_build_dir} - $1\007"
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
	INSTALL_DIR_FGFS=""
	install_dir_fgrun=""
	install_dir_fgcom=""
	install_dir_fgcomgui=""
	no_exe_fgfs=""
	no_exe_fgrun=""
	no_exe_fgcom=""
	no_exe_fgcomgui=""
	no_INSTALL_DIR_FGFS=""
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

	if [[ -e "${install_dir}/fgfs/bin/fgcom" ]] 
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
		INSTALL_DIR_FGFS="fgfs"
	else
		no_INSTALL_DIR_FGFS="fgfs"
	fi

	if [[ -e "${install_dir}/fgrun" ]] 
	then
		install_dir_fgrun="fgrun"
	else
		no_install_dir_fgrun="fgrun"
	fi

	if [[ -e "${install_dir}/fgfs" ]] 
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
	found_install_dir="$INSTALL_DIR_FGFS $install_dir_fgrun $install_dir_fgcom $install_dir_fgcomgui"
	no_install_dir="$no_INSTALL_DIR_FGFS $no_install_dir_fgrun $no_install_dir_fgcom $no_install_dir_fgcomgui"
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
set -x
if [[ "$DOWNLOAD_AND_COMPILE_LOG" == "" ]]
then
	log_version=0
	if test -n "$(find . -maxdepth 1 -name 'download_and_compile.log:*' -print -quit)"
	then
		for f in download_and_compile.log:*
		do
			log_version_found=$(( 10#${f##*:} ))
			if [[ $log_version_found -gt $log_version ]]
			then
				log_version=$log_version_found
			fi
		done

	fi
	if [[ -e download_and_compile.log ]]
	then
		let log_version=$(( $log_version + 1))
		if [[ $log_version -lt 10 ]]
		then 
			log_version='0'$log_version
		fi
		mv download_and_compile.log download_and_compile.log:$log_version
	fi
	export 	DOWNLOAD_AND_COMPILE_LOG=download_and_compile.log
	bash $0 $* 2>&1 |tee $DOWNLOAD_AND_COMPILE_LOG
    	exit
fi

rebuild_command="$0 $*"

echo $0 $* 
echo "		started building in $(pwd)" 
echo "		        at $(date)" 

LOGSEP="***********************************"
UPDATE=
STABLE=
STOP_AFTER_ONE_MODULE=false 

APT_GET_UPDATE="y"
DOWNLOAD_PACKAGES="y"

COMPILE="y"
RECONFIGURE="y"
DOWNLOAD="y"

JOPTION="-j $(( $(nproc) + 1))"
OOPTION=""
DEBUG=""
WITH_EVENT_INPUT=""
WITH_OPENRTI=""
FGSG_BRANCH="next"
FGSG_REVISION="HEAD"
osg_version="3.2.0"
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
             FGSG_BRANCH="2.12.1"
	     FGSG_REVISION="HEAD"
             ;;
         B)
             FGSG_BRANCH=$OPTARG
             ;;
         R)
             FGSG_REVISION=$OPTARG
             ;;
         G)
	     osg_version=${OPTARG^^} #3.0.1, 3.0.1d 3.1.9 3.1.9d, 3.2.0 next nextd, etc
	     OSG_DEBUG_OR_RELEASE='Release'
	     if [[ ${osg_version%d} != ${osg_version} ]]
	     then
		    OSG_DEBUG_OR_RELEASE='Debug'
		    osg_version= ${osg_version%d}
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

opts=$-

# ---------------------------------------------------------
# Script Section: Set Source Archive Version Variables
# ---------------------------------------------------------

# Last stable revision: currently FlightGear 2.10.0 with 3.0.1
PLIB_STABLE_REVISION="2172"
OSG_SVN="http://svn.openscenegraph.org/osg/OpenSceneGraph/tags/OpenSceneGraph-${osg_version}/"

declare -A OPENRTI_MAP
declare -A FGSG_MAP
declare -A FGRUN_MAP
declare -A fgdata_map
FGSG_MAP=( [next]="next HEAD"  \
		[master]="master HEAD "  \
		[3.0.0]="release/3.0.0 HEAD"  \
		[2.12.1]="release/2.12.0 HEAD"  \
		[2.12.0]="release/2.12.0 HEAD"  \
		[2.10.0]="release/2.10.0 HEAD "  \
		[2.8.0]="release/2.8.0 version/2.8.0-final" )
FGRUN_MAP=( [next]="next HEAD"  \
		[master]="master HEAD "  \
		[3.0.0]="release/3.0.0 HEAD "  \
		[2.12.1]="release/2.12 HEAD"  \
		[2.12.0]="release/2.12 HEAD"  \
		[2.10.0]="release/2.12 HEAD "  \
		[2.8.0]="release/2.12 HEAD" )
fgdata_map=([next]="master HEAD 3.0.0"  \
		[master]="master HEAD 3.0.0"  \
		[3.0.0]="release/3.0.0 HEAD 3.0.0"  \
		[2.12.1]="release/2.12.0 HEAD 2.12.1 "  \
		[2.12.0]="release/2.12.0 HEAD 2.12.1"  \
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

MAP_ITEM=( ${FGRUN_MAP[${FG_SG_VERSION}]} )
FGRUN_BRANCH=${MAP_ITEM[0]}
FGRUN_REVISION=${MAP_ITEM[1]}

MAP_ITEM=( ${fgdata_map[${FG_SG_VERSION}]} )
fgdata_branch=${MAP_ITEM[0]}
fgdata_revision=${MAP_ITEM[1]}
fgdata_version=${MAP_ITEM[2]}

MAP_ITEM=( ${OPENRTI_MAP[${FG_SG_VERSION}]} )
OPENRTI_BRANCH=${MAP_ITEM[0]}
OPENRTI_REVISION=${MAP_ITEM[1]}


# FGCOMGUI
FGCOMGUI_STABLE_REVISION="46"

#OpenRadar
OR_STABLE_RELEASE="http://wagnerw.de/OpenRadar.zip"

fgdata_git="git://gitorious.org/fg/fgdata.git"
echo $(pwd)

# ---------------------------------------------------------
# Script Section: Display Script Help
# ---------------------------------------------------------
set +x
if [ "$HELP" = "HELP" ]
then
	echo "$0 Version $VERSION"
	echo "Usage:"
	echo "./$0 [-u] [-h] [-s] [-e] [-i] [-g] [-a y|n] [-c y|n] [-p y|n] [-d y|n] [-r y|n] [ALL|PLIB|OSG|OPENRTI|SIMGEAR|FGFS|FGO|FGX|FGRUN|FGCOMGUI|ATLAS] [UPDATE]"
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



echo $0 $* 

echo "APT_GET_UPDATE=$APT_GET_UPDATE"
echo "DOWNLOAD_PACKAGES=$DOWNLOAD_PACKAGES"
echo "COMPILE=$COMPILE"
echo "RECONFIGURE=$RECONFIGURE"
echo "DOWNLOAD=$DOWNLOAD"
echo "JOPTION=$JOPTION"
echo "OOPTION=$OOPTION"
echo "DEBUG=$DEBUG"
echo "FGSG_VERSION=$FGSG_VERSION"
echo "FGSG_REVISION=$FGSG_REVISION"
echo "fgdata_branch=$fgdata_branch"
echo "fgdata_revision=$fgdata_revision"
echo "fgdata_version=$fgdata_version"

echo "$LOGSEP"
set -$opts

# ---------------------------------------------------------
# Script Section: Determine Linux Distribution
# ---------------------------------------------------------

if [ -e /etc/lsb-release ]
then
	. /etc/lsb-release
fi

# default is hardy
DISTRO_PACKAGES="libopenal-dev libalut-dev libalut0 cvs subversion cmake make build-essential automake zlib1g-dev zlib1g libwxgtk2.8-0 libwxgtk2.8-dev fluid gawk gettext libxi-dev libxi6 libxmu-dev libxmu6 libboost-dev libasound2-dev libasound2 libpng12-dev libpng12-0 libjasper1 libjasper-dev libopenexr-dev libboost-serialization-dev git-core libqt4-dev scons python-tk python-imaging-tk libsvn-dev libglew1.5-dev  libxft2 libxft-dev libxinerama1 libxinerama-dev"

UBUNTU_PACKAGES="freeglut3-dev libjpeg62-dev libjpeg62 libapr1-dev libfltk1.3-dev libfltk1.3"

if [[ ( "$DISTRIB_ID" = "Ubuntu" || "$DISTRIB_ID" = "LinuxMint" ) &&  "$DISTRIB_RELEASE" < "13.10" ]]
then	
	UBUNTU_PACKAGES="$UBUNTU_PACKAGES libhal-dev"
fi
DEBIAN_PACKAGES_STABLE="freeglut3-dev libjpeg8-dev libjpeg8 libfltk1.1-dev libfltk1.1"
DEBIAN_PACKAGES_TESTING="freeglut3-dev libjpeg8-dev libjpeg8 libfltk1.3-dev libfltk1.3"
DEBIAN_PACKAGES_UNSTABLE="freeglut3-dev libjpeg8-dev libjpeg8 libfltk1.3-dev libfltk1.3"

if [ "$DISTRIB_ID" = "Ubuntu" -o "$DISTRIB_ID" = "LinuxMint" ]
then	
	echo "$DISTRIB_ID $DISTRIB_RELEASE"
	DISTRO_PACKAGES="$DISTRO_PACKAGES $UBUNTU_PACKAGES"
else
	echo "DEBIAN I SUPPOUSE"

	DEBIAN_PACKAGES=$DEBIAN_PACKAGES_STABLE
	if [ ! "$(apt-cache search libfltk1.3)" = "" ]
	then
	  #TESTING MAYBE
	  DEBIAN_PACKAGES=$DEBIAN_PACKAGES_TESTING
	fi

	DISTRO_PACKAGES="$DISTRO_PACKAGES $DEBIAN_PACKAGES"
fi
echo "$LOGSEP"

# ---------------------------------------------------------
# Script Section: Install Prerequisite Development Packages
# ---------------------------------------------------------
SET_WINDOW_TITLE "Install Prerequisite Development Packages"


if [ "$DOWNLOAD_PACKAGES" = "y" ]
then
	echo -n "PACKAGE INSTALLATION ... "

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

	echo " OK"
fi


# -------------------------------------------------------------
# Script Section: Create Required Build and install Directories
# -------------------------------------------------------------
SET_WINDOW_TITLE "Create Required Build and install Directories"

COMPILE_BASE_DIR=.

#cd into compile base directory
cd "$COMPILE_BASE_DIR"

#get absolute path
current_build_dir=$(pwd)
current_build_dir=$(pwd)
# ----------------------------------------------------------------------------------------
# Special handling for plib and OpenSceneGraph
#
# These container, src, install and build directories support 
# doing a single download, configure and build for osg versions and plib-1.8.5
# This means that src, build and install directories for OSG can be separate from
# the build and install directories for openrti, simgear, flightgear, fgrun and fgcom
# this is optional and is conditioned on the existence of certain directories in the parent
# of where you are building.  The scheme supports as many osg versions as you care to download.
# it should also support debug versions of the osg libraries, but this has not been tried yet. 
# care to build.

# handling plib and OSG in this way will save 
# 	time
#	network bandwidth 
#	disk space
#	
# To trigger this option,  two things are required:
# 1. create a folder othersrc in the directory containing download_and_compile.sh
# 2. always build in a subdirectory of the one containing download_and_compile.sh
# 

# Directory Scheme:
# download_and_compile.sh
# othersrc
# 	plib-1.8.5
#		plib
#	osg${osg_version1}
#	osg${osg_version2}
# install
#	plib
#	osg${osg_version}
# build
#	plib
#	osg${osg_version1}
# next
# master
# stable
# 2.12.0
# 3.0.0
# to build, cd into one of next, master, stable, 2.12.0 or 3.0.0 
# and run ../download_and_compile.sh with appropriate parameters.

# first the defaults
plib_src_container=$current_build_dir
osg_src_container=$current_build_dir
install_dir_osg=

# then override with the optional scheme for othersrc
if [[ -e ../othersrc ]]
then
	mkdir -p ../othersrc/plib-1.8.5
	mkdir -p ../build/plib
	mkdir -p ../install/plib
	plib_src_container=$(cd ../othersrc/plib-1.8.5; pwd;)
	build_dir_plib=$(cd ../build/plib; pwd;)
	install_dir_plib=$(cd ../install/plib; pwd;)

	mkdir -p ../othersrc/OpensceneGraph-${osg_version}
	mkdir -p ../build/osg-${osg_version}
	mkdir -p ../install/osg-${osg_version}
	osg_src_container=$(cd ../othersrc/OpensceneGraph-${osg_version}; pwd;)	
	install_dir_osg=$(cd ../install/osg-${osg_version}; pwd;)
	build_dir_osg=$(cd ../build/osg-${osg_version}; pwd;)
fi
if [[ "${install_dir_osg}" = "" ]]
then
	mkdir -p build/plib
	mkdir -p install/plib
	mkdir -p build/osg
	mkdir -p install/osg
	install_dir_osg=$(cd build/plib; pwd;)
	install_dir_plib=$(cd install/plib; pwd;)
	build_dir_osg=$(cd build/osg; pwd;)
	build_dir_plib=$(cd install/osg; pwd;)
fi
# set it all up ahead of time:
mkdir -p ${plib_src_container}
mkdir -p ${osg_src_container}
mkdir -p ${install_dir_osg}
mkdir -p ${install_dir_plib}
mkdir -p ${build_dir_osg}
mkdir -p ${build_dir_plib}
plib_src=$plib_src_container/plib
osg_src=$osg_src_container/OpenSceneGraph

# ---------------------------------------------------------
# Script Section: Build Argument Interpretation
# ---------------------------------------------------------
#SET_WINDOW_TITLE "Option Interpretation"


shift $(($OPTIND - 1))

WHATTOBUILD=
# supress build of plib and osg if the libraries are in place
if [[ ! -e ${install_dir_plib}/lib/libplibsg.a ]]
then
	build_plib=PLIB
fi
if [[ ! -e ${install_dir_osg}/lib/libosgWidget.so.${osg_version} ]]
then
	build_osg=OSG
fi

WHATTOBUILDALL=( $build_plib $build_osg OPENRTI SIMGEAR FGFS DATA FGRUN )

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

# 
# 

printf "%s\n" "${WHATTOBUILD[@]}"


echo "DIRECTORY= $current_build_dir"
echo "$LOGSEP"

mkdir -p install

SUB_INSTALL_DIR=install
INSTALL_DIR=$current_build_dir/$SUB_INSTALL_DIR


cd "$current_build_dir"
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
export INSTALL_DIR_PLIB=${install_dir_plib}
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="PLIB"' ]]
then
	if [ ! "$UPDATE" = "UPDATE" ]
	then
		set +x
		echo "****************************************"
		echo "**************** PLIB ******************"
		echo "****************************************"
		SET_WINDOW_TITLE "Building PLIB"

		echo "BUILDING PLIB"
		echo "plib_src_container:$plib_src_container"
		echo "plib_src:          $install_dir_plib"
		echo "install_dir_plib:  $install_dir_plib"
		set -$opts

		if [ "$DOWNLOAD" = "y" ]
		then
			if [ -d "${plib_src_dir}/.svn" ]
			then
				echo -n "updating plib svn"
				cd ${plib_src}
				svn update 
            		else
				echo -n "DOWNLOADING FROM http://svn.code.sf.net/p/plib/code/trunk/ ..."
				cd ${plib_src_container}
				svn  co http://svn.code.sf.net/p/plib/code/trunk/ plib  
				echo " OK"
            		fi
		fi 

		if [ "$RECONFIGURE" = "y" ]
		then
			cd ${plib_src}

			echo "AUTOGEN plib"
			./autogen.sh
			echo "CONFIGURING plib"
			cd ${build_dir_plib}
			
			${plib_src}/configure  --disable-pw --disable-sl --disable-psl --disable-ssg --disable-ssgaux  --prefix="$INSTALL_DIR_PLIB" --exec-prefix="$INSTALL_DIR_PLIB"
			echo "CONFIGURE/RECONFIGURE OSG DONE."
		else
			echo "NO RECONFIGURE FOR plib"
		fi
		
		if [ "$COMPILE" = "y" ]
		then
			
			echo "MAKE plib"
			echo "make $JOPTION $OOPTION"
			
			cd $build_dir_plib
			make $JOPTION $OOPTION
			echo "INSTALL plib"
			echo "make install"
			make install
		fi
	fi
	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# OpenSceneGraph
#######################################################
SET_WINDOW_TITLE "Building OpenSceneGraph"
export INSTALL_DIR_OSG=${install_dir_osg}

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="OSG"' ]]
then
	set +x
	echo "****************************************"
	echo "**************** OSG *******************"
	echo "****************************************"
	echo "BUILDING PLIB"
	echo "osg_src_container:$osg_src_container"
	echo "osg_src:          $install_dir_osg"
	echo "install_dir_osg:  $install_dir_osg"
	set -$opts

	if [ "$DOWNLOAD" = "y" ]
	then
		
		echo -n "SVN FROM $OSG_SVN ... "
		if [ -d "${osg_src}/.svn" ]
		then
			echo -n "updating OpenSceneGraph svn"
			cd ${osg_src}
			svn update
            	else
			echo -n "downloadING FROM $OSG_SVN ..."
			cd $osg_src_container
			svn co "$OSG_SVN" OpenSceneGraph
            	fi
	fi
	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then

			cd ${build_dir_osg}		
			echo -n "RECONFIGURE OSG ... "
			rm -f CMakeCache.txt ${osg_src}/CMakeCache.txt CMakeCache.txt
			cmake ${osg_src}
			cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_OSG" $osg_src
			
			echo "RECONFIGURE OSG DONE."	
		fi
	fi

	if [ "$COMPILE" = "y" ]
	then
		echo "COMPILING OSG"
		cd ${build_dir_osg}
		make $JOPTION $OOPTION
		echo "INSTALLING OSG"
		make install
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
	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# OPENRTI
#######################################################
SET_WINDOW_TITLE "Building OPENRTI"
OPENRTI_INSTALL_DIR=openrti
INSTALL_DIR_OPENRTI=$INSTALL_DIR/$OPENRTI_INSTALL_DIR
cd "$current_build_dir"

if [ ! -d "openrti" ]
then
	mkdir "openrti"
fi

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="OPENRTI"' ]]
then
	echo "****************************************"
	echo "**************** OPENRTI ***************"
	echo "****************************************"


	if [ "$DOWNLOAD" = "y" ]
	then
		cd openrti

		echo -n "git FROM git://gitorious.org/openrti/openrti.git ... "

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

		echo " OK"
		cd ..
	
	fi
	
	cd "openrti/openrti"
	
	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then

			cd "$current_build_dir"
			mkdir -p build/openrti
			cd "$current_build_dir"/build/openrti
			echo -n "RECONFIGURE OPENRTI ... "
			rm -f ../../openrti/openrti/CMakeCache.txt
			cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_OPENRTI" ../../openrti/openrti/
			echo " OK"



		fi
	fi
	
	if [ "$COMPILE" = "y" ]
	then


		cd "$current_build_dir"/build/openrti
		echo "MAKE OPENRTI"
		echo "make $JOPTION $OOPTION "
		make $JOPTION $OOPTION

		echo "INSTALL OPENRTI"
		make install
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
cd "$current_build_dir"

if [ ! -d "simgear" ]
then
	mkdir "simgear"
fi

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="SIMGEAR"' ]]
then
	echo "****************************************"
	echo "**************** SIMGEAR ***************"
	echo "****************************************"


	if [ "$DOWNLOAD" = "y" ]
	then
		cd simgear
		echo -n "git FROM git://gitorious.org/fg/simgear.git ... "

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

		echo " OK"
		cd ..
	
	fi
	

	cd "simgear/simgear"
	
	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then

			cd "$current_build_dir"
			mkdir -p build/simgear
			cd "$current_build_dir"/build/simgear
			echo -n "RECONFIGURE SIMGEAR ... "
			rm -f ../../simgear/simgear/CMakeCache.txt
			rm -f CMakeCache.txt
			cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" $WITH_OPENRTI -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_SIMGEAR" -D "CMAKE_PREFIX_PATH=$INSTALL_DIR_OSG;$INSTALL_DIR_OPENRTI" ../../simgear/simgear/
			echo " OK"



		fi
	fi
	
	if [ "$COMPILE" = "y" ]
	then


		cd "$current_build_dir"/build/simgear
		echo "MAKE SIMGEAR"
		echo "make $JOPTION $OOPTION "
		make $JOPTION $OOPTION

		echo "INSTALL SIMGEAR"
		make install
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
cd "$current_build_dir"

if [ ! -d "fgfs" ]
then
	mkdir "fgfs"
fi

#if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "FGFS" -o "$WHATTOBUILD" = "DATA" -o "$WHATTOBUILD" = "ALL" ]
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGFS"' || "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="DATA"' ]]
then

	echo "****************************************"
	echo "**************** FGFS ******************"
	echo "****************************************"

	cd fgfs

	if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGFS"' ]]
	then
		if [ "$DOWNLOAD" = "y" ]
		then

			echo -n "GIT FROM git://gitorious.org/fg/flightgear.git ... "
			

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

			echo " OK"

		fi
		
		cd flightgear
		if [[ "$STABLE" = "STABLE" && $(grep -L 'list(APPEND FLTK_LIBRARIES ${CMAKE_DL_LIBS})' CMakeLists.txt) != "" ]]
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
	                        cd "$current_build_dir"
       				mkdir -p build/fgfs
	                        cd "$current_build_dir"/build/fgfs

				echo -n "RECONFIGURE FGFS ... "
				rm -f ../../fgfs/flightgear/CMakeCache.txt
				rm -f CMakeCache.txt

				# REMOVING BAD LINES IN CMakeLists.txt
				#echo "REMOVING BAD LINES IN CMakeLists.txt"
				#cat utils/fgadmin/src/CMakeLists.txt  | sed /X11_Xft_LIB/d | sed /X11_Xinerama_LIB/d > utils/fgadmin/src/CMakeLists_without_err.txt
				#cp -f  utils/fgadmin/src/CMakeLists_without_err.txt utils/fgadmin/src/CMakeLists.txt

		
				cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" $WITH_OPENRTI -D "WITH_FGPANEL=OFF" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGFS" -D "CMAKE_PREFIX_PATH=$INSTALL_DIR_OSG;$INSTALL_DIR_PLIB;$INSTALL_DIR_SIMGEAR;$INSTALL_DIR_OPENRTI" ../../fgfs/flightgear

				echo " OK"
			fi
		fi
		
		if [ "$COMPILE" = "y" ]
		then
                        cd "$current_build_dir"
                        mkdir -p build/fgfs
                        cd "$current_build_dir"/build/fgfs

			echo "MAKE FGFS"
			echo "make $JOPTION $OOPTION"
			make $JOPTION $OOPTION

			echo "INSTALL FGFS"
			make install
		fi

	fi

	
#
# Use a  scheme similar to the one for osg and plib for fgdata 
#
#fgdata-2.12.1
# 	fgdata
#fgdata-3.0.0
#	fgdata
	if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="DATA"' ]]
	then
		if [ ! "$UPDATE" = "UPDATE" ]
		then
			if [ "$DOWNLOAD" = "y" ]
			then
				cd $current_build_dir
				fgdata_container=
				echo "fgdata_version: ${fgdata_version}"
				for f in ../../../fgdata[-_]${fgdata_version} \
					 ../../fgdata[-_]${fgdata_version} \
					 ../fgdata[-_]${fgdata_version} \
					 ./fgdata[-_]${fgdata_version}
				do
				   if [[ -e $f ]]
				      then

					echo checking $f
					fgdata_container=$(cd ${f}; pwd;)
					fgdata_directory=$fgdata_container/fgdata
					if [[ -L $INSTALL_DIR_FGFS/fgdata ]] 
					then
						rm $INSTALL_DIR_FGFS/fgdata
					fi
					if [[ -d $INSTALL_DIR_FGFS/fgdata  ]]
					then
						rm -rf $INSTALL_DIR_FGFS/fgdata 
					fi
					ln -s -T $fgdata_directory $INSTALL_DIR_FGFS/fgdata 
					echo "$INSTALL_DIR_FGFS/fgdata is a symbolic link"
					echo "It points to $(readlink -f $INSTALL_DIR_FGFS/fgdata)"		
				   fi
				done
				if [[ "$fgdata_container" = "" ]]
				then
					fgdata_container=$(cd $INSTALL_DIR_FGFS; pwd;)
					fgdata_directory=${f}/fgdata
					if [[ -e $INSTALL_DIR_FGFS/fgdata ]]
					then
						echo "$fgdata_directory is a directory"
						echo "fgdata has been downloaded"
					fi
				fi
				if [[ -e $INSTALL_DIR_FGFS/fgdata ]]
				then
					echo "fgdata version $fgdata_version has been downloaded"
				else
					echo "fgdata version $fgdata_version will be downloaded."
				fi
				SET_WINDOW_TITLE " FGDATA"
				EXDIR=$(pwd)
				cd $INSTALL_DIR_FGFS
				echo  "GIT DATA FROM $fgdata_git  ... "

				if [ ! -e "fgdata" ]
				then
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
					if [[ "$(git_check_branch_or_tag $fgdata_branch)" = "" ]]
					then
						write_log_and_exec \
						  "git branch -f $fgdata_branch origin/$fgdata_branch" 
					fi
					# switch to stable branch. No error is reported if we're already on the branch.
					write_log_and_exec "git checkout -f $fgdata_branch"
 
					# get indicated stable version
					
					write_log_and_exec  "git reset --hard $fgdata_branch"
				else
					# switch to unstable branch
					# create local unstable branch, ignore errors if it exists
					$(git_check_branch_or_tag)
					if [[ "$(git_check_branch_or_tag $fgdata_branch)" = "" ]]
					then
						write_log_and_exec \
						  "git branch -f $fgdata_branch origin/$fgdata_branch" 
					fi
					# switch to unstable branch. No error is reported if we're already on the branch.
					write_log_and_exec  "git checkout -f $fgdata_branch"
					# pull latest version from the unstable branch
					write_log_and_exec  "git pull"
				fi
			fi
		fi
	fi

	cd "$current_build_dir"

	# IF SEPARATED FOLDER FOR AIRCRAFTS
	# --fg-aircraft=\$PWD/../aircrafts
	cat > run_fgfs.sh << ENDOFALL
#!/bin/sh
cd \$(dirname \$0)
cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin
export LD_LIBRARY_PATH=$install_dir_plib/lib:$install_dir_osg/lib:../../$SIMGEAR_INSTALL_DIR/lib:../../$OPENRTI_INSTALL_DIR/lib
./fgfs --fg-root=\$PWD/../fgdata/ \$@
ENDOFALL
	chmod 755 run_fgfs.sh

	cat > run_fgfs_debug.sh << ENDOFALL2
#!/bin/sh
cd \$(dirname \$0)
P1=\$PWD
cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin
export LD_LIBRARY_PATH=$install_dir_plib/lib:$install_dir_osg/lib:../../$SIMGEAR_INSTALL_DIR/lib:../../$OPENRTI_INSTALL_DIR/lib
gdb  --directory="\$P1"/fgfs/source/src/ --args fgfs --fg-root=\$PWD/../fgdata/ \$@
ENDOFALL2
	chmod 755 run_fgfs_debug.sh

	SCRIPT=run_terrasync.sh
	echo "#!/bin/sh" > $SCRIPT
	echo "cd \$(dirname \$0)" >> $SCRIPT
	echo "cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin" >> $SCRIPT
	echo "export LD_LIBRARY_PATH=$install_dir_plib/lib:$install_dir_osg/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> $SCRIPT
	echo "./terrasync \$@" >> $SCRIPT
	chmod 755 $SCRIPT

	SCRIPT=run_fgcom.sh
	echo "#!/bin/sh" > $SCRIPT
	echo "cd \$(dirname \$0)" >> $SCRIPT
	echo "cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin" >> $SCRIPT
	echo "export LD_LIBRARY_PATH=$install_dir_plib/lib:$install_dir_osg/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> $SCRIPT
	echo "./fgcom \$@" >> $SCRIPT
	chmod 755 $SCRIPT

	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# FGO!
#######################################################
SET_WINDOW_TITLE "Building FGO"
FGO_INSTALL_DIR=fgo
INSTALL_DIR_FGO=$INSTALL_DIR/$FGO_INSTALL_DIR
cd "$current_build_dir"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGO"' ]]
then
	echo "****************************************"
	echo "***************** FGO ******************"
	echo "****************************************"

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
cd "$current_build_dir"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGX"' ]]
then
	echo "****************************************"
	echo "***************** FGX ******************"
	echo "****************************************"

	if [ "$DOWNLOAD" = "y" ]
	then

		echo -n "git clone git://gitorious.org/fgx/fgx.git ... "

		if [ -d "fgx" ]
		then
			echo "fgx exists already."
		else
			git clone git://gitorious.org/fgx/fgx.git fgx
		fi

		echo " OK"

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
	cat tmp3 | sed s/\\/usr\\/bin\\/fgcom/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgfsMY_SLASH_HEREbinMY_SLASH_HEREfgcom/g > tmp4
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

			echo -n "RECONFIGURE FGX ... "

			mkdir -p $INSTALL_DIR_FGX
			cd $INSTALL_DIR_FGX

			qmake ../../fgx/src

			echo " OK"
		fi
	fi
	
	if [ "$COMPILE" = "y" ]
	then
		cd $INSTALL_DIR_FGX
		echo "MAKE AND INSTALL FGX"
		echo "make $JOPTION $OOPTION "
		make $JOPTION $OOPTION
		cd ..
	fi

	cd "$current_build_dir"

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
cd "$current_build_dir"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGRUN"' ]]
then
	echo "****************************************"
	echo "**************** FGRUN *****************"
	echo "****************************************"


		if [ "$DOWNLOAD" = "y" ]
		then
			echo -n "GIT FROM git://gitorious.org/fg/fgrun.git ... "

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

			echo " OK"

		fi
		
		cd fgrun


	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then
                        cd "$current_build_dir"
                        mkdir -p build/fgrun
                        cd "$current_build_dir"/build/fgrun

			echo -n "RECONFIGURE FGRUN ... "
			rm -f ../../fgrun/CMakeCache.txt
			rm -f CMakeCache.txt
			
			cmake ${VERBOSE_MAKEFILE} -D CMAKE_BUILD_TYPE="Release" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGRUN" -D "CMAKE_PREFIX_PATH=$INSTALL_DIR_OSG;$INSTALL_DIR_PLIB;$INSTALL_DIR_SIMGEAR" ../../fgrun/

			echo " OK"
		fi
	fi
	
	if [ "$COMPILE" = "y" ]
	then
		cd "$current_build_dir"/build/fgrun

		echo "MAKE FGRUN"
		echo "make $JOPTION $OOPTION"
		make $JOPTION $OOPTION 2>1

		echo "INSTALL FGRUN"
		make install
	fi

	cd "$current_build_dir"

	SCRIPT=run_fgrun.sh
	echo "#!/bin/sh" > $SCRIPT
	echo "cd \$(dirname \$0)" >> $SCRIPT
	echo "cd $SUB_INSTALL_DIR/$FGRUN_INSTALL_DIR/bin" >> $SCRIPT
	echo "export LD_LIBRARY_PATH=$install_dir_plib/lib:$install_dir_osg/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> $SCRIPT
	#echo "export FG_AIRCRAFTS=\$PWD/../../$FGFS_INSTALL_DIR/aircrafts" >> $SCRIPT
	echo "./fgrun --fg-exe=\$PWD/../../$FGFS_INSTALL_DIR/bin/fgfs --fg-root=\$PWD/../../$FGFS_INSTALL_DIR/fgdata   \$@" >> $SCRIPT
	chmod 755 $SCRIPT


	if [[ $STOP_AFTER_ONE_MODULE = true ]]; then exit; fi
fi

#######################################################
# FGCOMGUI
#######################################################
SET_WINDOW_TITLE "Building FGCOMGUI"
FGCOMGUI_INSTALL_DIR=fgcomgui
INSTALL_DIR_FGCOMGUI=$INSTALL_DIR/$FGCOMGUI_INSTALL_DIR
cd "$current_build_dir"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGCOMGUI"' ]]
then
	echo "****************************************"
	echo "*************** FGCOMGUI ***************"
	echo "****************************************"


	#svn checkout svn://svn.dfn.de:/fgcom/trunk fgcom
	if [ "$DOWNLOAD" = "y" ]
	then
		FGCOMGUI_STABLE_REVISION_=""
		if [ "$STABLE" = "STABLE" ]
		then
			FGCOMGUI_STABLE_REVISION_=" -r $FGCOMGUI_STABLE_REVISION"
		fi

		echo -n "SVN FROM https://fgcomgui.googlecode.com/svn/trunk ... "
		svn $FGCOMGUI_STABLE_REVISION_ co https://fgcomgui.googlecode.com/svn/trunk fgcomgui 
		echo " OK"
		
	fi
	
	if [ -d "fgcomgui" ]
	then
		cd fgcomgui/
	
		mkdir -p "$INSTALL_DIR_FGCOMGUI"

		if [ "$COMPILE" = "y" ]
		then
			echo "SCONS FGCOMGUI"
			echo "scons prefix=\"$INSTALL_DIR_FGCOMGUI\" $JOPTION"
			scons prefix="$INSTALL_DIR_FGCOMGUI" $JOPTION
			echo "INSTALL FGCOM"
			scons install
		fi
		cd "$current_build_dir"

		echo "#!/bin/sh" > run_fgcomgui.sh
		echo "cd \$(dirname \$0)" >> run_fgcomgui.sh
		echo "cd $SUB_INSTALL_DIR/$FGCOMGUI_INSTALL_DIR/bin" >> run_fgcomgui.sh
		echo "export LD_LIBRARY_PATH=$install_dir_plib/lib:$install_dir_osg/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> run_fgcomgui.sh
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
cd "$current_build_dir"

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
cd "$current_build_dir"

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="ATLAS"' ]]
then
	echo "****************************************"
	echo "**************** ATLAS *****************"
	echo "****************************************"

	if [ "$DOWNLOAD" = "y" ]
	then
		echo -n "CSV FROM atlas.cvs.sourceforge.net:/cvsroot/atlas ... "
		cvs -z3 -d:pserver:anonymous@atlas.cvs.sourceforge.net:/cvsroot/atlas co Atlas
		echo " OK"

		echo "fixing old function name \".get_gbs_center2(\" in Subbucket.cxx"
		cd Atlas/src
		cp Subbucket.cxx Subbucket.cxx.original
		cat Subbucket.cxx.original | sed s/\.get_gbs_center2\(/\.get_gbs_center\(/g > Subbucket.cxx
		cd "$current_build_dir"
	fi
	
	if [ -d "Atlas" ]
	then
		cd Atlas

		if [ ! "$UPDATE" = "UPDATE" ]
		then
			if [ "$RECONFIGURE" = "y" ]
			then

				cd "$current_build_dir"
		                mkdir -p build/atlas

				cd Atlas
				echo "AUTOGEN ATLAS"
				./autogen.sh
				echo "CONFIGURE ATLAS"
				cd "$current_build_dir"/build/atlas
				../../Atlas/configure --prefix=$INSTALL_DIR_ATLAS --exec-prefix=$INSTALL_DIR_ATLAS  --with-plib=$INSTALL_DIR_PLIB --with-simgear="$INSTALL_DIR_SIMGEAR" --with-fgbase="$INSTALL_DIR_FGFS/fgdata" CXXFLAGS="$CXXFLAGS -I$current_build_dir/OpenSceneGraph/include"
				make clean
			fi
		fi
		if [ "$COMPILE" = "y" ]
		then
			echo "MAKE ATLAS"
			echo "make $JOPTION $OOPTION"
		
			cd "$current_build_dir"/build/atlas
			make $JOPTION $OOPTION

			echo "INSTALL ATLAS"
			make install
		fi
		cd "$current_build_dir"

		echo "#!/bin/sh" > run_atlas.sh
		echo "cd \$(dirname \$0)" >> run_atlas.sh
		echo "cd $SUB_INSTALL_DIR/$ATLAS_INSTALL_DIR/bin" >> run_atlas.sh
		echo "export LD_LIBRARY_PATH=$install_dir_plib/lib:$install_dir_osg/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> run_atlas.sh
		echo "./Atlas --fg-root=\$PWD/../../$FGFS_INSTALL_DIR/fgdata \$@" >> run_atlas.sh
		chmod 755 run_atlas.sh
	fi
fi
SET_WINDOW_TITLE "Finished Building"
echo "		finished at $(date)" >>download_and_compile_summary.log
echo "" >>download_and_compile_summary.log

check_build "$current_build_dir"

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
	echo "$rebuild_command"  >rebuild
	chmod +x rebuild
fi




