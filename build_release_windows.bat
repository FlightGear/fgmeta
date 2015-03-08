

IF NOT DEFINED WORKSPACE SET WORKSPACE=%~dp0

REM SET /P SIMGEAR_VERSION=<%WORKSPACE%\simgear\version
REM ECHO #define SIMGEAR_VERSION "%SIMGEAR_VERSION%" > %WORKSPACE%\simgear\simgear\version.h



REM 32bits
md build-sg32
md build-fg32
md build-fgrun32
cd build-sg32
cmake ..\simgear -G "Visual Studio 10" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/SimGear -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..\build-fg32
cmake ..\flightgear -G "Visual Studio 10" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/FlightGear -DPNG_LIBRARY=%WORKSPACE%/3rdParty/lib/libpng16.lib -DFLTK_FLUID_EXECUTABLE=%WORKSPACE%/3rdParty/bin/fluid.exe -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..\build-fgrun32
cmake ..\fgrun -G "Visual Studio 10" -DMSVC_3RDPARTY_ROOT:PATH=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/FGRun -DFLTK_FLUID_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/fluid.exe -DGETTEXT_MSGFMT_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgfmt.exe -DGETTEXT_MSGMERGE_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgmerge.exe -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL



REM 64 bits
md build-sg64
md build-fg64
md build-fgrun64
cd build-sg64
cmake ..\SimGear -G "Visual Studio 10 Win64" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/SimGear -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..\build-fg64
cmake ..\flightgear -G "Visual Studio 10 Win64" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/FlightGear -DFLTK_FLUID_EXECUTABLE=%WORKSPACE%/3rdParty/bin/fluid.exe -DBOOST_ROOT=%WORKSPACE%/Boost -DWITH_FGPANEL=OFF -DENABLE_PROFILE=OFF
cmake --build . --config Release --target INSTALL

cd ..\build-fgrun64
cmake ..\fgrun -G "Visual Studio 10 Win64" -DMSVC_3RDPARTY_ROOT:PATH=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/FGRun -DFLTK_FLUID_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/fluid.exe -DGETTEXT_MSGFMT_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgfmt.exe -DGETTEXT_MSGMERGE_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgmerge.exe -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..

REM build setup
ECHO Packaging root is %WORKSPACE%

subst X: /D
subst X: %WORKSPACE%.

REM indirect way to get command output into an environment variable
set PATH=%WORKSPACE%\install\msvc100\OpenSceneGraph\bin;%PATH%
osgversion --so-number > %TEMP%\osg-so-number.txt
osgversion --version-number > %TEMP%\osg-version.txt
osgversion --openthreads-soversion-number > %TEMP%\openthreads-so-number.txt

SET /P FLIGHTGEAR_VERSION=<flightgear\version
SET /P OSG_VERSION=<%TEMP%\osg-version.txt
SET /P OSG_SO_NUMBER=<%TEMP%\osg-so-number.txt
SET /P OT_SO_NUMBER=<%TEMP%\openthreads-so-number.txt

ECHO #define FGVersion "%FLIGHTGEAR_VERSION%" > InstallConfig.iss
ECHO #define OSGVersion "%OSG_VERSION%" >> InstallConfig.iss
ECHO #define OSGSoNumber "%OSG_SO_NUMBER%" >> InstallConfig.iss
ECHO #define OTSoNumber "%OT_SO_NUMBER%" >> InstallConfig.iss

REM run Inno-setup!
REM use iscc instead of compil32 for better error reporting
iscc FlightGear.iss
