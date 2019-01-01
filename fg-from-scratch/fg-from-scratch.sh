 #!/bin/bash

# fg-from-scratch - Linux utility to download, compile, and stage TerraGear and its dependencies
# Copyright (C) 2018  Scott Giese (xDraconian) scttgs0@gmail.com

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

QT_SELECT=qt5
ROOT_DIR=${PWD}
PATH=${ROOT_DIR}/vcpkg-git/installed/x64-linux/bin:${PATH}
CMAKE_TOOLCHAIN="Ninja"
CHIPSET=$(gcc -march=native -Q --help=target | grep -- '-march=' | cut -f3)

QT5x64=$(qtpaths --install-prefix)
QT5x64_LIB=${QT5x64}/lib
QT5x64_CMAKE=${QT5x64_LIB}/cmake
QT5x64_PKGCONFIG=${QT5x64_LIB}/pkgconfig
export PKG_CONFIG_PATH=${ROOT_DIR}/scratch-install/lib64/pkgconfig:${ROOT_DIR}/vcpkg-git/installed/x64-linux/lib/pkgconfig:${QT5x64_PKGCONFIG}

echo ${QT5x64}

if [ ! -d "vcpkg-git" ]
then
    echo Preparing to install external libraries via vcpkg . . .
	git clone https://github.com/Microsoft/vcpkg.git vcpkg-git

	echo Compiling vcpkg
	cd vcpkg-git
	./bootstrap-vcpkg.sh

	echo Compiling external libraries . . .
	./vcpkg install --triplet x64-linux boost cgal curl freeglut freetype glew jasper libxml2 openal-soft openssl plib sdl2 tiff zlib
else
    echo Updating vcpkg . . .
	cd vcpkg-git
	PULL_RESULT=$(git pull)

    if [ "${PULL_RESULT}" != "Already up to date." ]
    then
        echo Compiling vcpkg
        ./bootstrap-vcpkg.sh
    fi

	echo Updating external libraries . . .
	./vcpkg update
	./vcpkg upgrade --triplet x64-linux --no-dry-run

    echo Compiling external libraries . . .
	./vcpkg install --triplet x64-linux boost cgal curl freeglut freetype glew jasper libxml2 openal-soft openssl plib sdl2 tiff zlib
fi
cd ${ROOT_DIR}

if [ ! -d "scratch-source" ]
then
    mkdir scratch-source
fi
if [ ! -d "scratch-build" ]
then
    mkdir scratch-build
fi
if [ ! -d "scratch-install" ]
then
    mkdir scratch-install
fi

if [ ! -d "scratch-build/openscenegraph-3.4" ]
then
    mkdir scratch-build/openscenegraph-3.4
fi
if [ ! -d "scratch-source/openscenegraph-3.4-git" ]
then
	echo Downloading OpenSceneGraph . . .
	git clone -b OpenSceneGraph-3.4 https://github.com/openscenegraph/OpenSceneGraph.git scratch-source/openscenegraph-3.4-git
else
	echo Updating OpenSceneGraph . . .
	cd scratch-source/openscenegraph-3.4-git
	git pull
fi
cd ${ROOT_DIR}

if [ ! -d "scratch-build/simgear" ]
then
    mkdir scratch-build/simgear
fi
if [ ! -d "scratch-source/simgear-git" ]
then
	echo Downloading SimGear . . .
	git clone -b next https://git.code.sf.net/p/flightgear/simgear scratch-source/simgear-git
else
	echo Updating SimGear . . .
	cd scratch-source/simgear-git
	git pull
fi
cd ${ROOT_DIR}

if [ ! -d "scratch-build/flightgear" ]
then
    mkdir scratch-build/flightgear
fi
if [ ! -d "scratch-source/flightgear-git" ]
then
	echo Downloading FlightGear . . .
	git clone -b next https://git.code.sf.net/p/flightgear/flightgear scratch-source/flightgear-git
else
	echo Updating FlightGear . . .
	cd scratch-source/flightgear-git
	git pull
fi
cd ${ROOT_DIR}

if [ ! -d "scratch-build/terragear" ]
then
    mkdir scratch-build/terragear
fi
if [ ! -d "scratch-source/terragear-git" ]
then
	echo Downloading TerraGear . . .
	git clone -b next https://git.code.sf.net/p/flightgear/terragear scratch-source/terragear-git
else
	echo Updating TerraGear . . .
	cd scratch-source/terragear-git
	git pull
fi
cd ${ROOT_DIR}

echo Compiling OpenSceneGraph . . .
cd scratch-build/openscenegraph-3.4
cmake ../../scratch-source/openscenegraph-3.4-git -G ${CMAKE_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/scratch-install \
	-DCMAKE_PREFIX_PATH=${ROOT_DIR}/scratch-install/lib:${ROOT_DIR}/vcpkg-git/installed/x64-linux/lib:${QT5x64_LIB} \
    -DCMAKE_CXX_FLAGS="-march=${CHIPSET} -mtune=${CHIPSET}" \
    -DCMAKE_C_FLAGS="-march=${CHIPSET} -mtune=${CHIPSET}" \
    -DBUILD_DOCUMENTATION:BOOL=1 \
    -DBUILD_OSG_APPLICATIONS:BOOL=1 \
    -DQt5Core_DIR=${QT5x64_CMAKE}/Qt5Core \
    -DQt5Gui_DIR=${QT5x64_CMAKE}/Qt5Gui \
    -DQt5OpenGL_DIR=${QT5x64_CMAKE}/Qt5OpenGL \
    -DQt5Widgets_DIR=${QT5x64_CMAKE}/Qt5Widgets
cmake --build . --config Release --target install
cd ${ROOT_DIR}

echo Compiling SimGear . . .
cd scratch-build/simgear
cmake ../../scratch-source/simgear-git -G  ${CMAKE_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/scratch-install \
	-DCMAKE_PREFIX_PATH=${ROOT_DIR}/scratch-install/lib:${ROOT_DIR}/vcpkg-git/installed/x64-linux/lib:${QT5x64} \
    -DCMAKE_CXX_FLAGS="-march=${CHIPSET} -mtune=${CHIPSET}" \
    -DCMAKE_C_FLAGS="-march=${CHIPSET} -mtune=${CHIPSET}"
cmake --build . --config Release --target install
cd ${ROOT_DIR}

echo Compiling FlightGear . . .
cd scratch-build/flightgear
cmake ../../scratch-source/flightgear-git -G  ${CMAKE_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/scratch-install \
	-DCMAKE_PREFIX_PATH=${ROOT_DIR}/scratch-install/lib:${ROOT_DIR}/vcpkg-git/installed/x64-linux/lib:${QT5x64_LIB} \
    -DCMAKE_CXX_FLAGS="-march=${CHIPSET} -mtune=${CHIPSET}" \
    -DCMAKE_C_FLAGS="-march=${CHIPSET} -mtune=${CHIPSET}" \
	-DOSG_FSTREAM_EXPORT_FIXED:BOOL=1 \
	-DENABLE_JSBSIM:BOOL=1 \
	-DENABLE_GPSSMOOTH:BOOL=1 \
	-DENABLE_FGVIEWER:BOOL=1 \
	-DENABLE_STGMERGE:BOOL=0 \
    -DQt5Core_DIR=${QT5x64_CMAKE}/Qt5Core \
    -DQt5Gui_DIR=${QT5x64_CMAKE}/Qt5Gui \
    -DQt5LinguistTools_DIR=${QT5x64_CMAKE}/Qt5LinguistTools \
    -DQt5Network_DIR=${QT5x64_CMAKE}/Qt5Network \
    -DQt5Qml_DIR=${QT5x64_CMAKE}/Qt5Qml \
    -DQt5Quick_DIR=${QT5x64_CMAKE}/Qt5Quick \
    -DQt5Svg_DIR=${QT5x64_CMAKE}/Qt5Svg \
    -DQt5Widgets_DIR=${QT5x64_CMAKE}/Qt5Widgets \
    -DQt5_DIR=${QT5x64_CMAKE}/Qt5
cmake --build . --config Release --target install
cd ${ROOT_DIR}

echo Compiling TerraGear . . .
cd scratch-build/terragear
cmake ../../scratch-source/terragear-git -G  ${CMAKE_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/scratch-install \
	-DCMAKE_PREFIX_PATH=${ROOT_DIR}/scratch-install/lib:${ROOT_DIR}/vcpkg-git/installed/x64-linux/lib:${QT5x64_LIB} \
    -DCMAKE_CXX_FLAGS="-march=${CHIPSET} -mtune=${CHIPSET}" \
    -DCMAKE_C_FLAGS="-march=${CHIPSET} -mtune=${CHIPSET}"
cmake --build . --config Release --target install
cd ${ROOT_DIR}

echo All done!
