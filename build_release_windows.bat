
IF NOT DEFINED WORKSPACE SET WORKSPACE=%~dp0
IF NOT DEFINED IS_NIGHTLY_BUILD SET IS_NIGHTLY_BUILD=1

IF %IS_NIGHTLY_BUILD% EQU 1 (
  SET FGBUILDTYPE=Nightly
) ELSE (
  SET FGBUILDTYPE=Release
)

REM following are for testing the script locally
REM SET PATH=%PATH%;%ProgramFiles%\CMake\bin;%ProgramFiles(x86)%\"Inno Setup 5"\
REM SET QT5SDK32=C:\Qt\5.6\msvc2015
REM SET QT5SDK64=C:\Qt\5.6\msvc2015_64
REM SET IS_NIGHTLY_BUILD=1

SET OSG32=%WORKSPACE%\install\msvc140\OpenSceneGraph
SET OSG64=%WORKSPACE%\install\msvc140-64\OpenSceneGraph

REM 32bits
md build-sg32
md build-fg32
cd build-sg32
cmake ..\simgear -G "Visual Studio 14" ^
                 -DMSVC_3RDPARTY_ROOT=%WORKSPACE%/windows-3rd-party/msvc140 ^
                 -DBOOST_ROOT=%WORKSPACE%/windows-3rd-party ^
                 -DOSG_FSTREAM_EXPORT_FIXED=1 ^
                 -DCMAKE_PREFIX_PATH:PATH=%OSG32% ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc140
cmake --build . --config RelWithDebInfo --target INSTALL

cd ..\build-fg32
cmake ..\flightgear -G "Visual Studio 14" ^
                    -DMSVC_3RDPARTY_ROOT=%WORKSPACE%/windows-3rd-party/msvc140 ^
                    -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc140 ^
                    -DCMAKE_PREFIX_PATH:PATH=%WORKSPACE%/install/msvc140/OpenSceneGraph ^
                    -DBOOST_ROOT=%WORKSPACE%/windows-3rd-party ^
                    -DOSG_FSTREAM_EXPORT_FIXED=1 ^
                    -DCMAKE_PREFIX_PATH=%QT5SDK32%;%OSG32% ^
                    -DFG_BUILD_TYPE=%FGBUILDTYPE% ^
                    -DENABLE_SWIFT:BOOL=ON
cmake --build . --config RelWithDebInfo --target INSTALL

cd ..

REM 64 bits
md build-sg64
md build-fg64

cd build-sg64
cmake ..\SimGear -G "Visual Studio 14 Win64" ^
                 -DMSVC_3RDPARTY_ROOT=%WORKSPACE%/windows-3rd-party/msvc140 ^
                 -DBOOST_ROOT=%WORKSPACE%/windows-3rd-party ^
                 -DOSG_FSTREAM_EXPORT_FIXED=1 ^
                 -DCMAKE_PREFIX_PATH:PATH=%OSG64% ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc140-64
cmake --build . --config RelWithDebInfo --target INSTALL

cd ..\build-fg64
cmake ..\flightgear -G "Visual Studio 14 Win64" ^
                    -DMSVC_3RDPARTY_ROOT=%WORKSPACE%/windows-3rd-party/msvc140 ^
                    -DBOOST_ROOT=%WORKSPACE%/windows-3rd-party ^
                    -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc140-64 ^
                    -DCMAKE_PREFIX_PATH=%QT5SDK64%;%OSG64% ^
                    -DOSG_FSTREAM_EXPORT_FIXED=1 ^
                    -DFG_BUILD_TYPE=%FGBUILDTYPE% ^
                    -DENABLE_SWIFT:BOOL=ON
cmake --build . --config RelWithDebInfo --target INSTALL

cd ..

REM Qt5 deployment
SET QMLDIR=%WORKSPACE%/flightgear/src/GUI/qml
%QT5SDK32%\bin\windeployqt --release --list target --qmldir %QMLDIR% %WORKSPACE%/install/msvc140/bin/fgfs.exe
%QT5SDK64%\bin\windeployqt --release --list target --qmldir %QMLDIR% %WORKSPACE%/install/msvc140-64/bin/fgfs.exe

REM build setup
ECHO Packaging root is %WORKSPACE%

subst X: /D
subst X: %WORKSPACE%.

REM ensure output dir is clean since we upload the entirety of it
rmdir /S /Q output

SET FGFS_PDB=src\Main\RelWithDebInfo\fgfs.pdb
SET SENTRY_ORG=flightgear
SET SENTRY_PROJECT=flightgear
REM ensure SENTRY_AUTH_TOKEN is set in the environment

sentry-cli upload-dif %WORKSPACE%\build-fg32\%FGFS_PDB%
sentry-cli upload-dif %WORKSPACE%\build-fg64\%FGFS_PDB%

REM indirect way to get command output into an environment variable
set PATH=%OSG32%\bin;%PATH%
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
  iscc /Q FlightGear.iss

  REM FlightGear nightly: without fgdata, output filename would be "FlightGear-x.x.x-nightly.exe"
  CALL :writeBaseConfig
  CALL :writeNightlyDietConfig
  iscc /Q FlightGear.iss
) ELSE (
  REM FlightGear release: with fgdata, output filename would be "FlightGear-x.x.x.exe"
  CALL :writeBaseConfig
  CALL :writeReleaseConfig
  iscc /Q FlightGear.iss
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
