
IF NOT DEFINED WORKSPACE SET WORKSPACE=%~dp0

SET /P SIMGEAR_VERSION=<%WORKSAPCE%\simgear\version
ECHO #define SIMGEAR_VERSION "%SIMGEAR_VERSION%" > %WORKSPACE%\simgear\simgear\version.h

cd %WORKSPACE%\simgear\projects\VC90
msbuild SimGear.vcproj /p:Configuration=Release /m

cd %WORKSPACE%\flightgear
call scripts\tools\version.bat
SET HAVE_VERSION_H=1
cd %WORKSPACE%\flightgear\projects\VC90
msbuild FlightGear.sln /p:Configuration=Release /m
