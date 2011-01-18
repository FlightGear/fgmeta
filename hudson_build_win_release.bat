call "D:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\Tools\vsvars32.bat"

ECHO #define SIMGEAR_VERSION "2.2.0" > %WORKSPACE%\simgear\version.h
cd %WORKSPACE%\simgear\projects\VC90
msbuild SimGear.vcproj /p:Configuration=Release /m

REM FlightGear

cd %WORKSPACE%\flightgear
call scripts\tools\version.bat
SET HAVE_VERSION_H=1
cd %WORKSPACE%\flightgear\projects\VC90
msbuild FlightGear.sln /p:Configuration=Release /m


REM FGRun

cd %WORKSPACE%
svn co https://fgrun.svn.sourceforge.net/svnroot/fgrun/trunk/fgrun fgrun

cd %WORKSPACE%\fgrun\msvc\9.0
msbuild fgrun.sln /p:Configuration=Release /m


REM Installer

cd %WORKSPACE%
ECHo "Should build installer here"
