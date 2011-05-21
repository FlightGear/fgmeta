
IF NOT DEFINED WORKSPACE SET WORKSPACE=%~dp0

ECHO #define SIMGEAR_VERSION "2.2.0" > %WORKSPACE%\simgear\simgear\version.h
cd %WORKSPACE%\simgear\projects\VC90
msbuild SimGear.vcproj /p:Configuration=Release /p:Platform=x64

cd %WORKSPACE%\flightgear
call scripts\tools\version.bat
SET HAVE_VERSION_H=1
cd %WORKSPACE%\flightgear\projects\VC90
msbuild FlightGear.sln /p:Configuration=Release /p:Platform=x64

