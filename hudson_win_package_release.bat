ECHO OFF

IF NOT DEFINED WORKSPACE SET WORKSPACE=%~dp0
ECHO Packaging root is %WORKSPACE%

subst X: /D
subst X: %WORKSPACE%

REM construct information file to be read by Inno-setup


set PATH=%WORKSPACE%\install\msvc90\OpenSceneGraph\bin;%PATH%
REM indirect way to get command output into an environment variable
osgversion --so-number > %TEMP%\osg-so-number.txt
osgversion --version-number > %TEMP%\osg-version.txt

SET /P FLIGHTGEAR_VERSION=<flightgear\version
SET /P OSG_VERSION=<%TEMP%\osg-version.txt
SET /P OSG_SO_NUMBER=<%TEMP%\osg-so-number.txt

ECHO #define FGVersion "%FLIGHTGEAR_VERSION%" > InstallConfig.iss
ECHO #define OSGVersion "%OSG_VERSION%" >> InstallConfig.iss
ECHO #define OSGSoNumber "%OSG_SO_NUMBER%" >> InstallConfig.iss

REM run Inno-setup!

Compil32 /cc FlightGear.iss



