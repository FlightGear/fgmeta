@ECHO OFF

REM fg-from-scratch - Windows utility to download, compile, and stage TerraGear and its dependencies
REM Copyright (C) 2018  Scott Giese (xDraconian) scttgs0@gmail.com

REM This program is free software; you can redistribute it and/or
REM modify it under the terms of the GNU General Public License
REM as published by the Free Software Foundation; either version 2
REM of the License, or (at your option) any later version.

REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU General Public License for more details.

REM You should have received a copy of the GNU General Public License
REM along with this program; if not, write to the Free Software
REM Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

SET ROOT_DIR=%CD%
SET PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/bin;%PATH%
SET CMAKE_TOOLCHAIN="Visual Studio 15 2017 Win64"
SET QT5x64=C:/Qt/Qt5/5.10.1/msvc2017_64

IF NOT EXIST vcpkg-git/NUL (
	echo Preparing to install external libraries via vcpkg . . .
	git clone https://github.com/Microsoft/vcpkg.git vcpkg-git

	echo Compiling vcpkg
	cd vcpkg-git
	call ./bootstrap-vcpkg

	echo Compiling external libraries . . .
	vcpkg install --triplet x64-windows boost cgal curl freeglut freetype gdal glew jasper libxml2 openal-soft openjpeg openssl sdl2 tiff zlib
) ELSE (
	echo Updating vcpkg . . .
	cd vcpkg-git
	git pull

	echo Updating external libraries . . .
	vcpkg update
	vcpkg upgrade --triplet x64-windows --no-dry-run

    REM Okay to comment out this line once all the packages have been confirmed to have been installed
	vcpkg install --triplet x64-windows boost cgal curl freeglut freetype gdal glew jasper libxml2 openal-soft openjpeg openssl sdl2 tiff zlib
)
cd %ROOT_DIR%

IF NOT EXIST openscenegraph-3.4-git/NUL (
	mkdir openscenegraph-3.4-build
	echo Downloading OpenSceneGraph . . .
	git clone -b OpenSceneGraph-3.4 https://github.com/openscenegraph/OpenSceneGraph.git openscenegraph-3.4-git
) ELSE (
	echo Updating OpenSceneGraph . . .
	cd openscenegraph-3.4-git
	git pull
)
cd %ROOT_DIR%

IF NOT EXIST simgear-git/NUL (
	mkdir simgear-build
	echo Downloading SimGear . . .
	git clone -b next https://git.code.sf.net/p/flightgear/simgear simgear-git
) ELSE (
	echo Updating SimGear . . .
	cd simgear-git
	git pull
)
cd %ROOT_DIR%

REM Intended for future use.
REM IF NOT EXIST flightgear-git/NUL (
REM 	mkdir flightgear-build
REM 	echo Downloading FlightGear . . .
REM 	git clone -b next https://git.code.sf.net/p/flightgear/flightgear flightgear-git
REM ) ELSE (
REM 	echo Updating FlightGear . . .
REM 	cd flightgear-git
REM 	git pull
REM )
cd %ROOT_DIR%

IF NOT EXIST terragear-ws2.0-git/NUL (
	mkdir terragear-ws2.0-build
	echo Downloading TerraGear . . .
	git clone -b scenery/ws2.0 https://git.code.sf.net/p/flightgear/terragear terragear-ws2.0-git
) ELSE (
	echo Updating TerraGear . . .
	cd terragear-ws2.0-git
	git pull
)
cd %ROOT_DIR%

ECHO Compiling OpenSceneGraph . . .
cd openscenegraph-3.4-build
cmake ..\openscenegraph-3.4-git -G %CMAKE_TOOLCHAIN% ^
	-DACTUAL_3RDPARTY_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows ^
	-DCMAKE_CONFIGURATION_TYPES=Debug;Release ^
	-DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%/Stage ^
	-DOSG_USE_UTF8_FILENAME:BOOL=1 ^
	-DWIN32_USE_MP:BOOL=1 ^
	-DCURL_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DCURL_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libcurl.lib ^
	-DFREETYPE_INCLUDE_DIR_ft2build=%ROOT_DIR%/vcpkg-git/packages/freetype_x64-windows/include ^
	-DFREETYPE_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DFREETPE_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/freetype.lib ^
	-DGDAL_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DGDAL_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/gdal.lib ^
	-DGLUT_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DGLUT_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/freeglut.lib ^
	-DJPEG_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DJPEG_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/jpeg.lib ^
	-DLIBXML2_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DLIBXML2_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libxml2.lib ^
	-DPNG_PNG_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DPNG_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libpng16.lib ^
	-DSDL2_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DSDL2_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/SDL2.lib ^
	-DSDL2MAIN_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/manual-link/SDL2main.lib ^
	-DTIFF_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DTIFF_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/tiff.lib ^
	-DZLIB_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DZLIB_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/zlib.lib
cmake --build . --config Release --target INSTALL
cd %ROOT_DIR%

ECHO Compiling SimGear . . .
cd simgear-build
cmake ..\simgear-git -G  %CMAKE_TOOLCHAIN% ^
	-DCMAKE_BUILD_TYPE=Release ^
	-DMSVC_3RDPARTY_ROOT=%ROOT_DIR%/vcpkg-git/installed/x64-windows ^
	-DCMAKE_PREFIX_PATH:PATH=%ROOT_DIR%/Stage/lib;%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib ^
	-DCMAKE_CONFIGURATION_TYPES=Debug;Release ^
	-DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%/Stage ^
	-DOSG_FSTREAM_EXPORT_FIXED:BOOL=1 ^
	-DENABLE_GDAL:BOOL=1 ^
	-DENABLE_OPENMP:BOOL=1 ^
	-DUSE_AEONWAVE:BOOL=0 ^
	-DBOOST_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DBOOST_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows ^
	-DCURL_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DCURL_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libcurl.lib ^
	-DGDAL_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DGDAL_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/gdal.lib ^
	-DOPENAL_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DOPENAL_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/OpenAL32.lib ^
	-DZLIB_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DZLIB_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/zlib.lib
cmake --build . --config Release --target INSTALL
cd %ROOT_DIR%

REM Currently broken. Intended for future use.
REM ECHO Compiling FlightGear . . .
REM cd flightgear-build
REM cmake ..\flightgear-git -G  %CMAKE_TOOLCHAIN% ^
	REM -DMSVC_3RDPARTY_ROOT=%ROOT_DIR%/vcpkg-git/installed/x64-windows ^
	REM -DCMAKE_PREFIX_PATH:PATH=%ROOT_DIR%/Stage/lib;%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib;%QT5x64% ^
	REM -DCMAKE_CONFIGURATION_TYPES=Debug;Release ^
	REM -DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%/Stage ^
	REM -DOSG_FSTREAM_EXPORT_FIXED:BOOL=1 ^
	REM -DENABLE_GDAL:BOOL=1 ^
	REM -DENABLE_OPENMP:BOOL=1 ^
	REM -DENABLE_JSBSIM:BOOL=1 ^
	REM -DENABLE_GPSSMOOTH:BOOL=1 ^
	REM -DENABLE_FGVIEWER:BOOL=0 ^
	REM -DENABLE_STGMERGE:BOOL=0 ^
	REM -DWITH_FGPANEL:BOOL=0 ^
	REM -DUSE_AEONWAVE:BOOL=0 ^
	REM -DHAVE_CONFIG_H:BOOL=0 ^
	REM -DFREETYPE_INCLUDE_DIR_ft2build=%ROOT_DIR%/vcpkg-git/packages/freetype_x64-windows/include ^
	REM -DGDAL_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	REM -DGDAL_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/gdal.lib ^
	REM -DOPENAL_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	REM -DOPENAL_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/OpenAL32.lib ^
	REM -DPLIB_INCLUDE_DIR=C:/src/3rdParty.x64/VS2017-x64-MD/include ^
	REM -DPNG_PNG_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	REM -DPNG_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libpng16.lib ^
	REM -DZLIB_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	REM -DZLIB_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/zlib.lib
REM cmake --build . --config Release --target INSTALL
REM cd %ROOT_DIR%

ECHO Compiling TerraGear . . .
cd terragear-ws2.0-build
cmake ..\terragear-ws2.0-git -G  %CMAKE_TOOLCHAIN% ^
	-DCMAKE_PREFIX_PATH:PATH=%ROOT_DIR%/Stage/lib;%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib;%QT5x64% ^
	-DCMAKE_CONFIGURATION_TYPES=Debug;Release ^
	-DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%/Stage ^
	-DMSVC-3RDPARTY_ROOT= ^
	-DBoost_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DBoost_LIBRARY_DIR_DEBUG=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib ^
	-DBoost_LIBRARY_DIR_RELEASE=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib ^
	-DCGAL_DIR=%ROOT_DIR%/vcpkg-git/buildtrees/cgal/x64-windows-rel ^
	-DGDAL_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DGDAL_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/gdal.lib ^
	-DJPEG_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DJPEG_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/jpeg.lib ^
	-DTIFF_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DTIFF_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/tiff.lib ^
	-DZLIB_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DZLIB_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/zlib.lib ^
	-DSIMGEAR_INCLUDE_DIR=%ROOT_DIR%/Stage/include ^
	-DSIMGEAR_CORE_LIBRARY=%ROOT_DIR%/Stage/lib/SimGearCore.lib ^
	-DSIMGEAR_SCENE_LIBRARY=%ROOT_DIR%/Stage/lib/SimGearScene.lib
cmake --build . --config Release --target INSTALL
cd %ROOT_DIR%

REM TerraGear is expecting proj.dll instead of proj_4_9.dll, clone it so TG may find it.
for %%i in (vcpkg-git\installed\x64-windows\bin\proj*.dll) do copy /Y %%i Stage\bin\proj.dll

ECHO All done!
