
IF NOT DEFINED WORKSPACE SET WORKSPACE=%~dp0

REM 32bits
md build-sg32
md build-fg32
md build-fgrun32
cd build-sg32
cmake ..\simgear -G "Visual Studio 10" ^
                 -DMSVC_3RDPARTY_ROOT=%WORKSPACE% ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/SimGear ^
                 -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..\build-fg32
cmake ..\flightgear -G "Visual Studio 10" ^
                    -DMSVC_3RDPARTY_ROOT=%WORKSPACE% ^
                    -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/FlightGear ^
                    -DCMAKE_PREFIX_PATH=%QT5SDK32% ^
                    -DPNG_LIBRARY=%WORKSPACE%/3rdParty/lib/libpng16.lib ^
                    -DFLTK_FLUID_EXECUTABLE=%WORKSPACE%/3rdParty/bin/fluid.exe ^
                    -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..\build-fgrun32
cmake ..\fgrun -G "Visual Studio 10" ^
               -DMSVC_3RDPARTY_ROOT:PATH=%WORKSPACE% ^
               -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/FGRun ^
               -DFLTK_FLUID_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/fluid.exe ^
               -DGETTEXT_MSGFMT_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgfmt.exe ^
               -DGETTEXT_MSGMERGE_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgmerge.exe ^
               -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..

REM 64 bits
md build-sg64
md build-fg64
md build-fgrun64
cd build-sg64
cmake ..\SimGear -G "Visual Studio 10 Win64" ^
                 -DMSVC_3RDPARTY_ROOT=%WORKSPACE% ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/SimGear ^
                 -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..\build-fg64
cmake ..\flightgear -G "Visual Studio 10 Win64" ^
                    -DMSVC_3RDPARTY_ROOT=%WORKSPACE% ^
                    -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/FlightGear ^
                    -DCMAKE_PREFIX_PATH=%QT5SDK64% ^
                    -DFLTK_FLUID_EXECUTABLE=%WORKSPACE%/3rdParty/bin/fluid.exe ^
                    -DBOOST_ROOT=%WORKSPACE%/Boost ^
                    -DWITH_FGPANEL=OFF ^
                    -DENABLE_PROFILE=OFF
cmake --build . --config Release --target INSTALL

cd ..\build-fgrun64
cmake ..\fgrun -G "Visual Studio 10 Win64" ^
               -DMSVC_3RDPARTY_ROOT:PATH=%WORKSPACE% ^
               -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/FGRun ^
               -DFLTK_FLUID_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/fluid.exe ^
               -DGETTEXT_MSGFMT_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgfmt.exe ^
               -DGETTEXT_MSGMERGE_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgmerge.exe ^
               -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..

REM Qt5 deployment
%QT5SDK32%\bin\windeployqt --release --list target %WORKSPACE%/install/msvc100/FlightGear/bin/fgfs.exe
%QT5SDK64%\bin\windeployqt --release --list target %WORKSPACE%/install/msvc100-64/FlightGear/bin/fgfs.exe

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

IF %IS_NIGHTLY_BUILD% EQU 1 (
  REM FlightGear nightly: with fgdata, output filename would be "FlightGear-x.x.x-nightly-full.exe"
  CALL :writeBaseConfig
  CALL :writeNightlyFullConfig
  iscc FlightGear.iss

  REM FlightGear nightly: without fgdata, output filename would be "FlightGear-x.x.x-nightly.exe"
  CALL :writeBaseConfig
  CALL :writeNightlyDietConfig
  iscc FlightGear.iss
) ELSE (
  REM FlightGear release: with fgdata, output filename would be "FlightGear-x.x.x.exe"
  CALL :writeBaseConfig
  CALL :writeReleaseConfig
  iscc FlightGear.iss
)
GOTO End

:writeBaseConfig
ECHO #define FGVersion "%FLIGHTGEAR_VERSION%" > InstallConfig.iss
ECHO #define OSGVersion "%OSG_VERSION%" >> InstallConfig.iss
ECHO #define OSGSoNumber "%OSG_SO_NUMBER%" >> InstallConfig.iss
ECHO #define OTSoNumber "%OT_SO_NUMBER%" >> InstallConfig.iss
GOTO End

:writeReleaseConfig
CALL :writeBaseConfig
ECHO #define FGDetails "" >> InstallConfig.iss
ECHO #define IncludeData "TRUE" >> InstallConfig.iss
GOTO End

:writeNightlyFullConfig
CALL :writeBaseConfig
ECHO #define FGDetails "-nightly-full" >> InstallConfig.iss
ECHO #define IncludeData "TRUE" >> InstallConfig.iss
GOTO End

:writeNightlyDietConfig
CALL :writeBaseConfig
ECHO #define FGDetails "-nightly" >> InstallConfig.iss
ECHO #define IncludeData "FALSE" >> InstallConfig.iss
GOTO End

:End
