@echo OFF

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

REM Defaults
set ROOT_DIR=%CD%
set WHITE_TEXT_FIX=0
set OSG_SOURCE_PATH=scratch-source/openscenegraph-3.6-git
set OSG_BUILD_PATH=scratch-build/openscenegraph-3.6
set WT_GDAL_INCLUDE_DIR=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include
set WT_GDAL_LIBRARY=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/gdal.lib
set WT_GDAL_LIBRARY_DEBUG=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/gdald.lib

REM Process arguments
:parse
if "%~1"=="" goto endparse
if "%~1"=="-wt" (
    set WHITE_TEXT_FIX=1
    set OSG_SOURCE_PATH=scratch-source/openscenegraph-fix-git
    set OSG_BUILD_PATH=scratch-build/openscenegraph-fix
	set WT_GDAL_INCLUDE_DIR=
	set WT_GDAL_LIBRARY=
	set WT_GDAL_LIBRARY_DEBUG=
)
if "%~1"=="--whitetext" (
    set WHITE_TEXT_FIX=1
    set OSG_SOURCE_PATH=scratch-source/openscenegraph-fix-git
    set OSG_BUILD_PATH=scratch-build/openscenegraph-fix
	set WT_GDAL_INCLUDE_DIR=
	set WT_GDAL_LIBRARY=
	set WT_GDAL_LIBRARY_DEBUG=
)
SHIFT
goto parse
:endparse

echo White Text Fix: %WHITE_TEXT_FIX%
echo %OSG_SOURCE_PATH%
echo %OSG_BUILD_PATH%

set PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/bin;%ROOT_DIR%/vcpkg-git/installed/x64-windows/include;%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib;%PATH%

REM Determine location of Qt5
set QT_SELECT=qt5
for /f %%i in ('"qtpaths.exe --install-prefix"') do set QT5x64=%%i
set QT5x64_LIB=%QT5x64%/lib
set QT5x64_CMAKE=%QT5x64_LIB%/cmake
echo QT Folder: %QT5x64%

REM Determine CMake toolchain
set CMAKE_TOOLCHAIN=Visual Studio 14 2015 Win64
for /f %%v in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere" -latest -property catalog_productlineversion') do set VSx64=%%v
if %VSx64%==2019 (set CMAKE_TOOLCHAIN="Visual Studio 16 2019")
if %VSx64%==2017 (set CMAKE_TOOLCHAIN="Visual Studio 15 2017 Win64")
if %VSx64%==2015 (set CMAKE_TOOLCHAIN="Visual Studio 14 2015 Win64")
echo CMake Toolchain: %CMAKE_TOOLCHAIN%

if not exist vcpkg-git/NUL (
	echo Preparing to install external libraries via vcpkg . . .
	git clone https://github.com/Microsoft/vcpkg.git vcpkg-git

	echo Compiling vcpkg
	cd vcpkg-git
	call .\bootstrap-vcpkg

	echo Compiling external libraries . . .
	vcpkg install --triplet x64-windows boost cgal curl freeglut freetype gdal glew jasper libpng libxml2 mpfr openal-soft openjpeg openssl plib sdl2 tiff zlib
) else (
	echo Updating vcpkg . . .
	cd vcpkg-git
	git pull

REM	for /f "delims=" %%G in ('"git pull"') do if not %%G == "Already up to date." (
	echo Compiling vcpkg
	call .\bootstrap-vcpkg
REM		break
REM	)

	echo Updating external libraries . . .
	vcpkg update
	vcpkg upgrade --triplet x64-windows --no-dry-run

	echo Compiling external libraries . . .
	vcpkg install --triplet x64-windows boost cgal curl freeglut freetype gdal glew jasper libxml2 libpng mpfr openal-soft openjpeg openssl plib sdl2 tiff zlib
)
cd %ROOT_DIR%

if not exist scratch-source/NUL (
	mkdir scratch-source
)
if not exist scratch-build/NUL (
	mkdir scratch-build
)
if not exist scratch-install/NUL (
	mkdir scratch-install
)

if %WHITE_TEXT_FIX%==1 (
    if not exist scratch-build/openscenegraph-fix/NUL (
	    mkdir scratch-build\openscenegraph-fix
    )
    if not exist scratch-source/openscenegraph-fix-git/NUL (
	    echo Downloading OpenSceneGraph . . .
	    git clone -b fgfs-342-1 https://github.com/zakalawe/osg.git scratch-source/openscenegraph-fix-git
    ) else (
	    echo Updating OpenSceneGraph . . .
	    cd scratch-source/openscenegraph-fix-git
	    git pull
    )
) else (
    if not exist scratch-build/openscenegraph-3.6/NUL (
	    mkdir scratch-build\openscenegraph-3.6
    )
    if not exist scratch-source/openscenegraph-3.6-git/NUL (
	    echo Downloading OpenSceneGraph . . .
	    git clone -b OpenSceneGraph-3.6 https://github.com/openscenegraph/OpenSceneGraph.git scratch-source/openscenegraph-3.6-git
    ) else (
	    echo Updating OpenSceneGraph . . .
	    cd scratch-source/openscenegraph-3.6-git
	    git pull
    )
)
cd %ROOT_DIR%

if not exist scratch-build/simgear/NUL (
	mkdir scratch-build\simgear
)
if not exist scratch-source/simgear-git/NUL (
	echo Downloading SimGear . . .
	git clone -b next https://git.code.sf.net/p/flightgear/simgear scratch-source/simgear-git
) else (
	echo Updating SimGear . . .
	cd scratch-source/simgear-git
	git pull
)
cd %ROOT_DIR%

if not exist scratch-build/flightgear/NUL (
	mkdir scratch-build\flightgear
)
if not exist scratch-source/flightgear-git/NUL (
	echo Downloading FlightGear . . .
	git clone -b next https://git.code.sf.net/p/flightgear/flightgear scratch-source/flightgear-git
) else (
	echo Updating FlightGear . . .
	cd scratch-source/flightgear-git
	git pull
)
cd %ROOT_DIR%

if not exist scratch-build/terragear/NUL (
	mkdir scratch-build\terragear
)
if not exist scratch-source/terragear-git/NUL (
	echo Downloading TerraGear . . .
	git clone -b next https://git.code.sf.net/p/flightgear/terragear scratch-source/terragear-git
) else (
	echo Updating TerraGear . . .
	cd scratch-source/terragear-git
	git pull
)
cd %ROOT_DIR%

REM -DQt5Core_DIR=%QT5x64_CMAKE%/Qt5Core ^
REM -DQt5Gui_DIR=%QT5x64_CMAKE%/Qt5Gui ^
REM -DQt5OpenGL_DIR=%QT5x64_CMAKE%/Qt5OpenGL ^
REM -DQt5Widgets_DIR=%QT5x64_CMAKE%/Qt5Widgets ^

echo Compiling OpenSceneGraph . . .
cd %OSG_BUILD_PATH%
cmake ..\..\%OSG_SOURCE_PATH% -G %CMAKE_TOOLCHAIN% ^
	-DCMAKE_CONFIGURATION_TYPES:STRING=Debug;Release ^
	-DCMAKE_BUILD_TYPE:STRING=Release ^
	-DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%/scratch-install ^
	-DCMAKE_PREFIX_PATH:STRING=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib;%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib ^
	-DACTUAL_3RDPARTY_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows ^
	-DOSG_USE_UTF8_FILENAME:BOOL=1 ^
	-DWIN32_USE_MP:BOOL=1 ^
	-DCURL_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DCURL_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libcurl.lib ^
	-DCURL_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/libcurl.lib ^
	-DFREETYPE_INCLUDE_DIR_ft2build:PATH=%ROOT_DIR%/vcpkg-git/packages/freetype_x64-windows/include ^
	-DFREETYPE_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/freetype.lib ^
	-DFREETYPE_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/freetyped.lib ^
	-DGDAL_INCLUDE_DIR:PATH=%WT_GDAL_INCLUDE_DIR% ^
	-DGDAL_LIBRARY:FILEPATH=%WT_GDAL_LIBRARY% ^
	-DGDAL_LIBRARY_DEBUG:FILEPATH=%WT_GDAL_LIBRARY_DEBUG% ^
	-DGLUT_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DGLUT_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/freeglut.lib ^
	-DGLUT_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/freeglut.lib ^
	-DJPEG_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DJPEG_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/jpeg.lib ^
	-DJPEG_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/jpeg.lib ^
	-DLIBXML2_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DLIBXML2_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libxml2.lib ^
	-DLIBXML2_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/libxml2.lib ^
	-DPNG_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DPNG_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libpng16.lib ^
	-DPNG_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/libpng16d.lib ^
	-DSDL2_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DSDL2_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/SDL2.lib ^
	-DSDL2MAIN_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/manual-link/SDL2main.lib ^
	-DTIFF_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DTIFF_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/tiff.lib ^
	-DTIFF_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/tiffd.lib ^
	-DZLIB_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DZLIB_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/zlib.lib ^
	-DZLIB_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/zlibd.lib
cmake --build . --config Release --target INSTALL
cd %ROOT_DIR%

echo Compiling SimGear . . .
cd scratch-build\simgear
cmake ..\..\scratch-source\simgear-git -G  %CMAKE_TOOLCHAIN% ^
	-DCMAKE_CONFIGURATION_TYPES:STRING=Debug;Release ^
	-DCMAKE_BUILD_TYPE:STRING=Release ^
	-DMSVC_3RDPARTY_ROOT:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows ^
	-DCMAKE_PREFIX_PATH:STRING=%ROOT_DIR%/scratch-install/lib;%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib ^
	-DCMAKE_INCLUDE_PATH:STRING=%ROOT_DIR%/scratch-install/include;%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%/scratch-install ^
	-DOSG_FSTREAM_EXPORT_FIXED:BOOL=1 ^
	-DENABLE_GDAL:BOOL=1 ^
	-DENABLE_OPENMP:BOOL=1 ^
	-DUSE_AEONWAVE:BOOL=0 ^
	-DBoost_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DBoost_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows ^
	-DCURL_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DCURL_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/libcurl.lib ^
	-DCURL_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libcurl.lib ^
	-DGDAL_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DGDAL_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/gdal.lib ^
	-DOPENAL_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DOPENAL_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/OpenAL32.lib ^
	-DOPENTHREADS_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOPENTHREADS_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/OpenThreads.lib ^
	-DOPENTHREADS_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGDB_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGDB_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGDB_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgDB.lib ^
	-DOSGGA_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGGA_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGGA_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgGA.lib ^
	-DOSGPARTICLE_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGPARTICLE_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGPARTICLE_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgParticle.lib ^
	-DOSGSIM_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGSIM_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGSIM_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgSim.lib ^
	-DOSGTEXT_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGTEXT_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGTEXT_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgText.lib ^
	-DOSGUTIL_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGUTIL_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGUTIL_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgUtil.lib ^
	-DOSGVIEWER_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGVIEWER_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGVIEWER_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgViewer.lib ^
	-DOSG_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSG_LIBRARY_DEBUG:FILEPATH= ^
	-DOSG_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osg.lib ^
	-DZLIB_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DZLIB_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/zlibd.lib ^
	-DZLIB_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/zlib.lib
cmake --build . --config Release --target INSTALL
cd %ROOT_DIR%

REM -DENABLE_GDAL:BOOL=1 ^
REM	-DENABLE_OPENMP:BOOL=1 ^
REM	-DUSE_AEONWAVE:BOOL=0 ^

echo Compiling FlightGear . . .
cd scratch-build\flightgear
cmake ..\..\scratch-source\flightgear-git -G  %CMAKE_TOOLCHAIN% ^
	-DCMAKE_CONFIGURATION_TYPES:STRING=Debug;Release ^
	-DCMAKE_BUILD_TYPE:STRING=Release ^
	-DMSVC_3RDPARTY_ROOT:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows ^
	-DCMAKE_PREFIX_PATH:STRING=%ROOT_DIR%/scratch-install/lib;%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib;%QT5x64_LIB% ^
	-DCMAKE_INCLUDE_PATH:STRING=%ROOT_DIR%/scratch-install/include;%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%/scratch-install ^
	-DSimGear_DIR:PATH=%ROOT_DIR%/scratch-install/lib/cmake/SimGear ^
	-DOSG_FSTREAM_EXPORT_FIXED:BOOL=1 ^
	-DENABLE_JSBSIM:BOOL=1 ^
	-DENABLE_GPSSMOOTH:BOOL=1 ^
	-DENABLE_FGVIEWER:BOOL=0 ^
	-DENABLE_FGELEV:BOOL=0 ^
	-DENABLE_STGMERGE:BOOL=0 ^
	-DWITH_FGPANEL:BOOL=0 ^
	-DHAVE_CONFIG_H:BOOL=0 ^
	-DBoost_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DBoost_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows ^
	-DFREETYPE_INCLUDE_DIR_ft2build:PATH=%ROOT_DIR%/vcpkg-git/packages/freetype_x64-windows/include ^
	-DFREETYPE_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/freetype.lib ^
	-DFREETYPE_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/freetyped.lib ^
	-DGDAL_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DGDAL_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/gdal.lib ^
	-DOPENAL_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DOPENAL_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/OpenAL32.lib ^
	-DOPENTHREADS_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOPENTHREADS_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/OpenThreads.lib ^
	-DOPENTHREADS_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGDB_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGDB_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGDB_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgDB.lib ^
	-DOSGFX_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGFX_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGFX_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgFX.lib ^
	-DOSGGA_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGGA_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGGA_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgGA.lib ^
	-DOSGPARTICLE_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGPARTICLE_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGPARTICLE_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgParticle.lib ^
	-DOSGSIM_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGSIM_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGSIM_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgSim.lib ^
	-DOSGTEXT_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGTEXT_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGTEXT_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgText.lib ^
	-DOSGUTIL_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGUTIL_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGUTIL_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgUtil.lib ^
	-DOSGVIEWER_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSGVIEWER_LIBRARY_DEBUG:FILEPATH= ^
	-DOSGVIEWER_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osgViewer.lib ^
	-DOSG_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DOSG_LIBRARY_DEBUG:FILEPATH= ^
	-DOSG_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/scratch-install/lib/osg.lib ^
	-DPLIB_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DPLIB_FNT_LIBRARY_DEBUG:FILEPATH= ^
	-DPLIB_FNT_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/plib_fnt.lib ^
	-DPLIB_PUAUX_LIBRARY_DEBUG:FILEPATH= ^
	-DPLIB_PUAUX_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/plib_puAux.lib ^
	-DPLIB_PUI_LIBRARY_DEBUG:FILEPATH= ^
	-DPLIB_PUI_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/plib_pui.lib ^
	-DPLIB_SG_LIBRARY_DEBUG:FILEPATH= ^
	-DPLIB_SG_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/plib_sg.lib ^
	-DPLIB_UL_LIBRARY_DEBUG:FILEPATH= ^
	-DPLIB_UL_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/plib_ul.lib ^
	-DPNG_PNG_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DPNG_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/libpng16.lib ^
	-DZLIB_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DZLIB_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/zlibd.lib ^
	-DZLIB_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/zlib.lib
cmake --build . --config Release --target INSTALL
cd %ROOT_DIR%

echo Compiling TerraGear . . .
cd scratch-build\terragear
cmake ..\..\scratch-source\terragear-git -G  %CMAKE_TOOLCHAIN% ^
	-DCMAKE_CONFIGURATION_TYPES:STRING=Debug;Release ^
	-DCMAKE_BUILD_TYPE:STRING=Release ^
	-DCMAKE_PREFIX_PATH:STRING=%ROOT_DIR%/scratch-install/lib;%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib;%QT5x64_LIB% ^
	-DCMAKE_INCLUDE_PATH:STRING=%ROOT_DIR%/scratch-install/include;%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%/scratch-install ^
	-DMSVC_3RDPARTY_ROOT:PATH= ^
	-DBoost_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DBoost_LIBRARY_DIR_RELEASE:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib ^
	-DCGAL_DIR:PATH=%ROOT_DIR%/vcpkg-git/buildtrees/cgal/x64-windows-rel ^
	-DGDAL_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DGDAL_LIBRARY:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/gdal.lib ^
	-DGMP_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DGMP_LIBRARIES_DIR:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib ^
	-DJPEG_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DJPEG_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/jpeg.lib ^
	-DJPEG_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/jpeg.lib ^
	-DMPFR_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DMPFR_LIBRARIES_DIR:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib ^
	-DTIFF_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DTIFF_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/tiffd.lib ^
	-DTIFF_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/tiff.lib ^
	-DZLIB_INCLUDE_DIR:PATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/include ^
	-DZLIB_LIBRARY_DEBUG:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/debug/lib/zlibd.lib ^
	-DZLIB_LIBRARY_RELEASE:FILEPATH=%ROOT_DIR%/vcpkg-git/installed/x64-windows/lib/zlib.lib ^
	-DSIMGEAR_INCLUDE_DIR:PATH=%ROOT_DIR%/scratch-install/include ^
	-DSIMGEAR_CORE_LIBRARY_RELEASE=%ROOT_DIR%/scratch-install/lib/SimGearCore.lib ^
	-DSIMGEAR_SCENE_LIBRARY_RELEASE=%ROOT_DIR%/scratch-install/lib/SimGearScene.lib
cmake --build . --config Release --target INSTALL
cd %ROOT_DIR%

REM TerraGear is expecting proj.dll instead of proj_4_9.dll, clone it so TG may find it.
for %%i in (vcpkg-git\installed\x64-windows\bin\proj*.dll) do copy /Y %%i scratch-install\bin\proj.dll

echo All done!
