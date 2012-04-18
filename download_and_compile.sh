#!/bin/bash
#* Written by Francesco Angelo Brisa, started January 2008.
#
# Copyright (C) 2008 Francesco Angelo Brisa
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


VERSION="1.30"

#COMPILE GIT FGFS

#######################################################
# THANKS TO
#######################################################
# Special thanks to Alessandro Garosi for FGComGui and 
# other patches
# Thanks to "pac1" for patches for fgrun compilation



LOGFILE=compilation_log.txt
LOGSEP="***********************************"

WHATTOBUILD=
UPDATE=
STABLE=

APT_GET_UPDATE="y"
DOWNLOAD_PACKAGES="y"

COMPILE="y"
RECONFIGURE="y"
DOWNLOAD="y"


JOPTION=""
OOPTION=""
DEBUG=""
WITH_EVENT_INPUT=""

while getopts "suhc:p:a:d:r:j:O:ge" OPTION
do
     case $OPTION in
         s)
             STABLE="STABLE"
             ;;
         u)
             UPDATE="UPDATE"
             ;;
         h)
             WHATTOBUILD="--help"
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


         ?)
             echo "error"
             WHATTOBUILD="--help"
             #exit
             ;;
     esac
done
shift $(($OPTIND - 1))
#printf "Remaining arguments are: %s\n" "$*"
#printf "Num: %d\n" "$#"

if [ ! "$#" = "0" ]
then
	if [ "$WHATTOBUILD" = "" ]
	then
		WHATTOBUILD="$1"
	fi
	
	if [ ! "$#" = "1" ]
	then
		UPDATE="$2"
	fi
	
fi



#######################################################
# Last stable revision: currently FlightGear 2.4.0 with 3.0.1
PLIB_STABLE_REVISION="2163"
OSG_STABLE_REVISION="http://www.openscenegraph.org/svn/osg/OpenSceneGraph/tags/OpenSceneGraph-3.0.1"

# common stable branch for flightgear, simgear and fgdata
FGSG_STABLE_GIT_BRANCH="release/2.6.0"

# unstable branch: next for sg/fg, master for fgdata
FGSG_UNSTABLE_GIT_BRANCH="next"
FGDATA_UNSTABLE_GIT_BRANCH="master"

# stable GIT revision: release tag
SIMGEAR_STABLE_REVISION="version/2.6.0-final"
FGFS_STABLE_REVISION="version/2.6.0-final"
FGFS_DATA_STABLE_REVISION="version/2.6.0-final"

FGRUN_STABLE_REVISION="655"
FGCOM_STABLE_REVISION="261"
FGCOMGUI_STABLE_REVISION="46"

# Current developer revision: latest FlightGear GIT (2.5.0) with OSG 3.0.1
OSG_UNSTABLE_REVISION="http://www.openscenegraph.org/svn/osg/OpenSceneGraph/tags/OpenSceneGraph-3.0.1"

#######################################################
# set script to stop if an error occours
set -e



if [ "$WHATTOBUILD" = "--help" ]
then
	echo "$0 Version $VERSION"
	echo "Usage:"
	echo "./$0 [-u] [-h] [-s] [-e] [-g] [-a y|n] [-c y|n] [-p y|n] [-d y|n] [-r y|n] [ALL|PLIB|OSG|SIMGEAR|FGFS|FGO|FGRUN|FGCOM|FGCOMGUI|ATLAS] [UPDATE]"
	echo "* without options it recompiles: PLIB,OSG,SIMGEAR,FGFS,FGRUN"
	echo "* Using ALL compiles everything"
	echo "* Adding UPDATE it does not rebuild all (faster but to use only after one successfull first compile)"
	echo "Switches:"
	echo "* -u  such as using UPDATE"
	echo "* -h  show this help"
	echo "* -e  compile FlightGear with --with-eventinput option (experimental)"
	echo "* -g  compile with debug info for gcc"
	echo "* -a y|n  y=do an apt-get update n=skip apt-get update                      	default=y"
	echo "* -p y|n  y=download packages n=skip download packages                      	default=y"
	echo "* -c y|n  y=compile programs  n=do not compile programs                     	default=y"
	echo "* -d y|n  y=fetch programs from internet (cvs, svn, etc...)  n=do not fetch 	default=y"
	echo "* -j X    Add -jX to the make compilation		                             	default=None"
	echo "* -O X    Add -OX to the make compilation	           				default=None"
	echo "* -r y|n  y=reconfigure programs before compiling them  n=do not reconfigure	default=y"
	echo "* -s compile only last stable known versions					default=y"
	
	exit
fi


#######################################################
#######################################################
# Warning about compilation time and size
# Idea from Jester
echo "**************************************"
echo "*                                    *"
echo "* Warning, the compilation process   *"
echo "* is going to use 9 or more Gbytes   *"
echo "* of space and at least a couple of  *"
echo "* hours to download and build FG.    *"
echo "*                                    *"
echo "* Please, be patient ......          *"
echo "*                                    *"
echo "**************************************"




#######################################################
#######################################################
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
#######################################################
#######################################################


echo $0 $* > $LOGFILE

echo "APT_GET_UPDATE=$APT_GET_UPDATE" >> $LOGFILE
echo "DOWNLOAD_PACKAGES=$DOWNLOAD_PACKAGES" >> $LOGFILE
echo "COMPILE=$COMPILE" >> $LOGFILE
echo "RECONFIGURE=$RECONFIGURE" >> $LOGFILE
echo "DOWNLOAD=$DOWNLOAD" >> $LOGFILE
echo "JOPTION=$JOPTION" >> $LOGFILE
echo "OOPTION=$OOPTION" >> $LOGFILE
echo "DEBUG=$DEBUG" >> $LOGFILE


echo "$LOGSEP" >> $LOGFILE

# discovering linux
if [ -e /etc/lsb-release ]
then
	. /etc/lsb-release
fi


# default is hardy
DISTRO_PACKAGES="libopenal-dev libalut-dev libalut0  libfltk1.1-dev libfltk1.1 cvs subversion cmake make build-essential automake zlib1g-dev zlib1g libwxgtk2.8-0 libwxgtk2.8-dev fluid gawk gettext libxi-dev libxi6 libxmu-dev libxmu6 libboost-dev libasound2-dev libasound2 libpng12-dev libpng12-0 libjasper1 libjasper-dev libopenexr-dev libboost-serialization-dev git-core libhal-dev libqt4-dev scons python-tk python-imaging-tk libsvn-dev libglew1.5-dev "

UBUNTU_PACKAGES="freeglut3-dev libjpeg62-dev libjpeg62 libapr1-dev "
DEBIAN_PACKAGES="freeglut3-dev libjpeg8-dev libjpeg8 "

# checking linux distro and version to differ needed packages
if [ "$DISTRIB_ID" = "Ubuntu" ]
then
	echo "$DISTRIB_ID $DISTRIB_RELEASE" >> $LOGFILE
	DISTRO_PACKAGES="$DISTRO_PACKAGES $UBUNTU_PACKAGES"
else
	echo "DEBIAN I SUPPOUSE" >> $LOGFILE
	DISTRO_PACKAGES="$DISTRO_PACKAGES $DEBIAN_PACKAGES"
fi
echo "$LOGSEP" >> $LOGFILE


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









COMPILE_BASE_DIR=.




#cd into compile base directory
cd "$COMPILE_BASE_DIR"

#get absolute path
CBD=$(pwd)

LOGFILE=$CBD/$LOGFILE


echo "DIRECTORY= $CBD" >> $LOGFILE
echo "$LOGSEP" >> $LOGFILE


if [ ! -d install ]
then
	mkdir install
fi

SUB_INSTALL_DIR=install
INSTALL_DIR=$CBD/$SUB_INSTALL_DIR


cd "$CBD"
mkdir -p build


#######################################################
# PLIB
#######################################################
PLIB_INSTALL_DIR=plib
INSTALL_DIR_PLIB=$INSTALL_DIR/$PLIB_INSTALL_DIR


cd "$CBD"

#svn co http://plib.svn.sourceforge.net/svnroot/plib/trunk plib

if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "PLIB" -o "$WHATTOBUILD" = "ALL" ]
then
	if [ ! "$UPDATE" = "UPDATE" ]
	then
		echo "****************************************" | tee -a $LOGFILE
		echo "**************** PLIB ******************" | tee -a $LOGFILE
		echo "****************************************" | tee -a $LOGFILE

		echo "COMPILING PLIB" >> $LOGFILE
		echo "INSTALL_DIR_PLIB=$INSTALL_DIR_PLIB" >> $LOGFILE


		PLIB_STABLE_REVISION_=""
		if [ "$STABLE" = "STABLE" ]
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
				echo -n "DOWNLOADING FROM http://plib.svn.sourceforge.net ..." >> $LOGFILE
				svn $PLIB_STABLE_REVISION_ co http://plib.svn.sourceforge.net/svnroot/plib/trunk plib 
				cat plib/src/util/ul.h | sed s/"PLIB_TINY_VERSION  5"/"PLIB_TINY_VERSION  6"/g > ul.h-v1.8.6
				mv ul.h-v1.8.6 plib/src/util/ul.h
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
			../../plib/configure --prefix="$INSTALL_DIR_PLIB" --exec-prefix="$INSTALL_DIR_PLIB" 2>&1 | tee -a $LOGFILE
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
fi


#######################################################
# OpenSceneGraph
#######################################################
OSG_INSTALL_DIR=OpenSceneGraph
INSTALL_DIR_OSG=$INSTALL_DIR/$OSG_INSTALL_DIR
cd "$CBD"

if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "OSG" -o "$WHATTOBUILD" = "ALL" ]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "**************** OSG *******************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE

	OSG_SVN=$OSG_UNSTABLE_REVISION
	if [ "$STABLE" = "STABLE" ]
	then
		OSG_SVN=$OSG_STABLE_REVISION
	fi


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
			rm -f ../../OpenSceneGraph/CMakeCache.txt
			cmake ../../OpenSceneGraph/
			echo " OK" >> $LOGFILE



			cmake -D CMAKE_BUILD_TYPE="Release" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_OSG" ../../OpenSceneGraph/ 2>&1 | tee -a $LOGFILE
			
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
fi



#######################################################
# SIMGEAR
#######################################################
SIMGEAR_INSTALL_DIR=simgear
INSTALL_DIR_SIMGEAR=$INSTALL_DIR/$SIMGEAR_INSTALL_DIR
cd "$CBD"

if [ ! -d "simgear" ]
then
	mkdir "simgear"
fi

if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "SIMGEAR" -o "$WHATTOBUILD" = "ALL" ]
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
			git branch -f $FGSG_STABLE_GIT_BRANCH origin/$FGSG_STABLE_GIT_BRANCH 2> /dev/null || true
			# switch to stable branch. No error is reported if we're already on the branch.
			git checkout -f $FGSG_STABLE_GIT_BRANCH
			# get indicated stable version
			git reset --hard $SIMGEAR_STABLE_REVISION
		else
			# switch to unstable branch
			# create local unstable branch, ignore errors if it exists
			git branch -f $FGSG_UNSTABLE_GIT_BRANCH origin/$FGSG_UNSTABLE_GIT_BRANCH 2> /dev/null || true
			# switch to unstable branch. No error is reported if we're already on the branch.
			git checkout -f $FGSG_UNSTABLE_GIT_BRANCH
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
			cmake -D CMAKE_BUILD_TYPE="Release" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_SIMGEAR" -D CMAKE_PREFIX_PATH=$INSTALL_DIR_OSG ../../simgear/simgear/ 2>&1 | tee -a $LOGFILE
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
fi


#######################################################
# FGFS
#######################################################
FGFS_INSTALL_DIR=fgfs
INSTALL_DIR_FGFS=$INSTALL_DIR/$FGFS_INSTALL_DIR
cd "$CBD"

if [ ! -d "fgfs" ]
then
	mkdir "fgfs"
fi

if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "FGFS" -o "$WHATTOBUILD" = "DATA" -o "$WHATTOBUILD" = "ALL" ]
then

	echo "****************************************" | tee -a $LOGFILE
	echo "**************** FGFS ******************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE

	cd fgfs

	if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "FGFS" -o "$WHATTOBUILD" = "ALL" ]
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

			git fetch origin
			if [ "$STABLE" = "STABLE" ]
			then
				# switch to stable branch
				# create local stable branch, ignore errors if it exists
				git branch -f $FGSG_STABLE_GIT_BRANCH origin/$FGSG_STABLE_GIT_BRANCH 2> /dev/null || true
				# switch to stable branch. No error is reported if we're already on the branch.
				git checkout -f $FGSG_STABLE_GIT_BRANCH
				# get indicated stable version
				git reset --hard $FGFS_STABLE_REVISION
			else
				# switch to unstable branch
				# create local unstable branch, ignore errors if it exists
				git branch -f $FGSG_UNSTABLE_GIT_BRANCH origin/$FGSG_UNSTABLE_GIT_BRANCH 2> /dev/null || true
				# switch to unstable branch. No error is reported if we're already on the branch.
				git checkout -f $FGSG_UNSTABLE_GIT_BRANCH
				# pull latest version from the unstable branch
				git pull
			fi

			cd ..	

			echo " OK" >> $LOGFILE

		fi
		
		cd flightgear
		
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

				# REMOVING BAD LINES IN CMakeLists.txt
				#echo "REMOVING BAD LINES IN CMakeLists.txt"
				#cat utils/fgadmin/src/CMakeLists.txt  | sed /X11_Xft_LIB/d | sed /X11_Xinerama_LIB/d > utils/fgadmin/src/CMakeLists_without_err.txt
				#cp -f  utils/fgadmin/src/CMakeLists_without_err.txt utils/fgadmin/src/CMakeLists.txt

		
				cmake -D CMAKE_BUILD_TYPE="Release" -D "WITH_FGPANEL=OFF" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGFS" -D "CMAKE_PREFIX_PATH=$INSTALL_DIR_OSG;$INSTALL_DIR_PLIB;$INSTALL_DIR_SIMGEAR" ../../fgfs/flightgear 2>&1 | tee -a $LOGFILE

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


	if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "DATA" -o "$WHATTOBUILD" = "ALL" ]
	then
		if [ ! "$UPDATE" = "UPDATE" ]
		then
			if [ "$DOWNLOAD" = "y" ]
			then
				EXDIR=$(pwd)
				cd $INSTALL_DIR_FGFS
				echo -n "GIT DATA FROM git://gitorious.org/fg/fgdata.git ... " >> $LOGFILE

				if [ -d "fgdata" ]
				then
					echo "fgdata exists already."
				else
					# no repository yet - need to clone a fresh one
					git clone git://gitorious.org/fg/fgdata.git fgdata
				fi

				cd fgdata

				git fetch origin
				if [ "$STABLE" = "STABLE" ]
				then
					# switch to stable branch
					# create local stable branch, ignore errors if it exists
					git branch -f $FGSG_STABLE_GIT_BRANCH origin/$FGSG_STABLE_GIT_BRANCH 2> /dev/null || true
					# switch to stable branch. No error is reported if we're already on the branch.
					git checkout -f $FGSG_STABLE_GIT_BRANCH
					# get indicated stable version
					git reset --hard $FGFS_DATA_STABLE_REVISION
				else
					# switch to unstable branch
					# create local unstable branch, ignore errors if it exists
					git branch -f $FGDATA_UNSTABLE_GIT_BRANCH origin/$FGDATA_UNSTABLE_GIT_BRANCH 2> /dev/null || true
					# switch to unstable branch. No error is reported if we're already on the branch.
					git checkout -f $FGDATA_UNSTABLE_GIT_BRANCH
					# pull latest version from the unstable branch
					git pull
				fi

				cd ..


				#cd $INSTALL_DIR_FGFS
				#echo -n "GIT DATA FROM git://gitorious.org/flightgear-aircraft/c172p.git ... " >> $LOGFILE

				#if [ ! -d "aircrafts" ]
				#then
				#	mkdir "aircrafts"
				#	ln ../fgdata/Aircraft/Generic/ . -s
				#	ln ../fgdata/Aircraft/Instruments . -s
				#	ln ../fgdata/Aircraft/Instruments-3d/ . -s
				#fi

				#cd aircrafts

				#if [ -d "c172p" ]
				#then
				#	echo "c172p exists already."
				#else
#
#					git clone git://gitorious.org/flightgear-aircraft/c172p.git
#				fi
#
#				cd c172p
#				git fetch origin







				echo " OK" >> $LOGFILE
				cd "$EXDIR"
			fi
		fi
	fi


	# IF SEPARATED FOLDER FOR AIRCRAFTS
	# --fg-aircraft=\$PWD/../aircrafts
	cat > run_fgfs.sh << ENDOFALL
#!/bin/sh
cd \$(dirname \$0)
cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin
export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib
./fgfs --fg-root=\$PWD/../fgdata/ \$@
ENDOFALL
	chmod 755 run_fgfs.sh

	cat > run_fgfs_debug.sh << ENDOFALL2
#!/bin/sh
cd \$(dirname \$0)
P1=\$PWD
cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin
export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib
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

fi

#######################################################
# FGO!
#######################################################
FGO_INSTALL_DIR=fgo
INSTALL_DIR_FGO=$INSTALL_DIR/$FGO_INSTALL_DIR
cd "$CBD"
if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "FGO" -o "$WHATTOBUILD" = "ALL" ]
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

fi


#######################################################
# FGRUN
#######################################################
FGRUN_INSTALL_DIR=fgrun
INSTALL_DIR_FGRUN=$INSTALL_DIR/$FGRUN_INSTALL_DIR
cd "$CBD"

if [ "$WHATTOBUILD" = "" -o "$WHATTOBUILD" = "FGRUN" -o "$WHATTOBUILD" = "ALL" ]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "**************** FGRUN *****************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE

	if [ "$DOWNLOAD" = "y" ]
	then

		FGRUN_STABLE_REVISION_=""
		if [ "$STABLE" = "STABLE" ]
		then
			FGRUN_STABLE_REVISION_=" -r $FGRUN_STABLE_REVISION"
		fi


		echo -n "SVN FROM http://fgrun.svn.sourceforge.net/svnroot/fgrun ... " >> $LOGFILE
		svn $FGRUN_STABLE_REVISION_ co http://fgrun.svn.sourceforge.net/svnroot/fgrun/trunk fgrun
		echo " OK" >> $LOGFILE

	fi
	cd fgrun/fgrun/

	if [ ! "$UPDATE" = "UPDATE" ]
	then
		if [ "$RECONFIGURE" = "y" ]
		then
                        cd "$CBD"
                        mkdir -p build/fgrun
                        cd "$CBD"/build/fgrun

			echo -n "RECONFIGURE FGRUN ... " >> $LOGFILE
			rm -f ../../fgrun/fgrun/CMakeCache.txt
			
			cmake -D CMAKE_BUILD_TYPE="Release" -D CMAKE_CXX_FLAGS="-O3 -D__STDC_CONSTANT_MACROS" -D CMAKE_C_FLAGS="-O3" -D CMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGRUN" -D "CMAKE_PREFIX_PATH=$INSTALL_DIR_OSG;$INSTALL_DIR_PLIB;$INSTALL_DIR_SIMGEAR" ../../fgrun/fgrun/ 2>&1 | tee -a $LOGFILE

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


fi



#######################################################
# FGCOM
#######################################################
FGCOM_INSTALL_DIR=fgcom
INSTALL_DIR_FGCOM=$INSTALL_DIR/$FGCOM_INSTALL_DIR
cd "$CBD"

if [ "$WHATTOBUILD" = "ALL" -o "$WHATTOBUILD" = "FGCOM" ]
then
	echo "****************************************" | tee -a $LOGFILE
	echo "**************** FGCOM *****************" | tee -a $LOGFILE
	echo "****************************************" | tee -a $LOGFILE


	#svn checkout svn://svn.dfn.de:/fgcom/trunk fgcom
	if [ "$DOWNLOAD" = "y" ]
	then

		FGCOM_STABLE_REVISION_=""
		if [ "$STABLE" = "STABLE" ]
		then
			FGCOM_STABLE_REVISION_=" -r $FGCOM_STABLE_REVISION"
		fi


		echo -n "SVN FROM https://appfgcom.svn.sourceforge.net/svnroot/fgcom/trunk ... " >> $LOGFILE
		svn $FGCOM_STABLE_REVISION_ co https://appfgcom.svn.sourceforge.net/svnroot/fgcom/trunk fgcom 
		echo " OK" >> $LOGFILE


		
#patch for new netdb.h version.
		cat fgcom/iaxclient/lib/libiax2/src/iax.c | sed s/hp-\>h_addr,/hp-\>h_addr_list[0],/g > fgcom/iaxclient/lib/libiax2/src/iax_ok.c
		mv fgcom/iaxclient/lib/libiax2/src/iax_ok.c fgcom/iaxclient/lib/libiax2/src/iax.c
	fi
	
	cd fgcom/src/
	
	if [ "$RECONFIGURE" = "y" ]
	then
        cp Makefile Makefile.original
		cat Makefile | sed s/\\//MY_SLASH_HERE/g > Makefile_NOSLASHES
	
		# 1
		INSTALL_DIR_PLIB_NO_SLASHES=$(echo "$INSTALL_DIR_PLIB" | sed -e 's/\//MY_SLASH_HERE/g')
		cat Makefile_NOSLASHES | sed s/PLIB_PREFIX\ *:=\ *MY_SLASH_HEREusrMY_SLASH_HERElocalMY_SLASH_HEREsrcMY_SLASH_HEREfgfs-builderMY_SLASH_HEREinstall/PLIB_PREFIX\ :=\ $INSTALL_DIR_PLIB_NO_SLASHES/g > Makefile_temp
		mv -f Makefile_temp Makefile_NOSLASHES
	
		#2
		CXXFLAGS=$(cat Makefile_NOSLASHES | grep ^CXXFLAGS | head -n 1)
		CXXFLAGS2=$CXXFLAGS" -I $INSTALL_DIR_SIMGEAR/include -I $INSTALL_DIR_OSG/include" 
		CXXFLAGS3=$(echo $CXXFLAGS2 | sed s/\\//MY_SLASH_HERE/g)
	
		cat Makefile_NOSLASHES | sed s/^CXXFLAGS\ *:=.*/"$CXXFLAGS3"/g  > Makefile_temp
		mv -f Makefile_temp Makefile_NOSLASHES	
	
		#3
		LDFLAGS=$(cat Makefile_NOSLASHES | grep ^LDFLAGS | head -n 1)
		LDFLAGS2=$LDFLAGS" -L $INSTALL_DIR_SIMGEAR/lib" 
		LDFLAGS3=$(echo $LDFLAGS2 | sed s/\\//MY_SLASH_HERE/g)
	
		cat Makefile_NOSLASHES | sed s/^LDFLAGS.*/"$LDFLAGS3"/g  > Makefile_temp
		mv -f Makefile_temp Makefile_NOSLASHES	
	
		#4
		INSTALL_DIR_FGCOM_NO_SLASHS=$(echo "$INSTALL_DIR_FGCOM" | sed -e 's/\//MY_SLASH_HERE/g')
		INSTALL_BIN_FGCOM_NO_SLASHS="$INSTALL_DIR_FGCOM_NO_SLASHS""MY_SLASH_HEREbin"
	
		cat Makefile_NOSLASHES | sed s/INSTALL_BIN\ *:=\ *MY_SLASH_HEREusrMY_SLASH_HERElocalMY_SLASH_HEREbin/INSTALL_BIN\ :=\ $INSTALL_BIN_FGCOM_NO_SLASHS/g > Makefile_temp		
		mv -f Makefile_temp Makefile_NOSLASHES	
	
		cat Makefile_NOSLASHES | sed s/INSTALL_DIR\ *:=\ *MY_SLASH_HEREusrMY_SLASH_HERElocal/INSTALL_DIR\ :=\ $INSTALL_DIR_FGCOM_NO_SLASHS/g > Makefile_temp		
		mv -f Makefile_temp Makefile_NOSLASHES	
		
	
		#last
		cat Makefile_NOSLASHES | sed s/MY_SLASH_HERE/\\//g > Makefile

	fi


	mkdir -p "$INSTALL_DIR_FGCOM"/bin

	if [ "$COMPILE" = "y" ]
	then
		echo "MAKE FGCOM" >> $LOGFILE
		echo "make $JOPTION $OOPTION" >> $LOGFILE
		make $JOPTION $OOPTION 2>&1 | tee -a $LOGFILE

		echo "INSTALL FGCOM" >> $LOGFILE
		make install 2>&1 | tee -a $LOGFILE
	fi
	cd -

	echo "#!/bin/sh" > run_fgcom.sh
	echo "cd \$(dirname \$0)" >> run_fgcom.sh
	echo "cd $SUB_INSTALL_DIR/$FGCOM_INSTALL_DIR/bin" >> run_fgcom.sh
	echo "export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> run_fgcom.sh
	echo "./fgcom -Sfgcom.flightgear.org.uk  \$@" >> run_fgcom.sh
	chmod 755 run_fgcom.sh

fi



#######################################################
# FGCOMGUI
#######################################################
FGCOMGUI_INSTALL_DIR=fgcomgui
INSTALL_DIR_FGCOMGUI=$INSTALL_DIR/$FGCOMGUI_INSTALL_DIR
cd "$CBD"

if [ "$WHATTOBUILD" = "ALL" -o "$WHATTOBUILD" = "FGCOMGUI" ]
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
	cd -

	echo "#!/bin/sh" > run_fgcomgui.sh
	echo "cd \$(dirname \$0)" >> run_fgcomgui.sh
	echo "cd $SUB_INSTALL_DIR/$FGCOMGUI_INSTALL_DIR/bin" >> run_fgcomgui.sh
	echo "export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> run_fgcomgui.sh
	echo "export PATH=../../fgcom/bin/:$PATH" >> run_fgcomgui.sh
	echo "./fgcomgui \$@" >> run_fgcomgui.sh
	chmod 755 run_fgcomgui.sh

fi


#######################################################
# ATLAS
#######################################################
ATLAS_INSTALL_DIR=atlas
INSTALL_DIR_ATLAS=$INSTALL_DIR/$ATLAS_INSTALL_DIR
cd "$CBD"

if [ "$WHATTOBUILD" = "ALL" -o "$WHATTOBUILD" = "ATLAS" ]
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
	cd -

	echo "#!/bin/sh" > run_atlas.sh
	echo "cd \$(dirname \$0)" >> run_atlas.sh
	echo "cd $SUB_INSTALL_DIR/$ATLAS_INSTALL_DIR/bin" >> run_atlas.sh
	echo "export LD_LIBRARY_PATH=../../$PLIB_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$SIMGEAR_INSTALL_DIR/lib" >> run_atlas.sh
	echo "./Atlas --fg-root=\$PWD/../../$FGFS_INSTALL_DIR/fgdata \$@" >> run_atlas.sh
	chmod 755 run_atlas.sh

fi



echo "To start fgfs, run the run_fgfs.sh file"
echo "To start terrasync, run the run_terrasync.sh file"
echo "To start fgrun, run the run_fgrun.sh file"
echo "To start fgcom, run the run_fgcom.sh file"
echo "To start fgcom GUI, run the run_fgcomgui.sh file"
echo "To start atlas, run the run_atlas.sh file"


if [ "$WHATTOBUILD" = "--help" ]
then
	echo ""
else
	echo "Usage: $0 -h"
	echo "for help"
fi
