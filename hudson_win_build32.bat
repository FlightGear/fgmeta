IF NOT DEFINED WORKSPACE SET WORKSPACE=%~dp0

SET /P SIMGEAR_VERSION=<%WORKSPACE%\simgear\version
ECHO #define SIMGEAR_VERSION "%SIMGEAR_VERSION%" > %WORKSPACE%\simgear\simgear\version.h

rem set PATH=%PATH%;D:\Program Files (x86)\CMake 2.8\bin
rem call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\Tools\vsvars32.bat"

md build-sg
md build-fg
md build-fgrun
cd build-sg
cmake ..\simgear -G "Visual Studio 10" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/SimGear -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..\build-fg
cmake ..\flightgear -G "Visual Studio 10" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/FlightGear -DFLTK_FLUID_EXECUTABLE=%WORKSPACE%/3rdParty/bin/fluid.exe -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL

cd ..\build-fgrun
cmake ..\fgrun -G "Visual Studio 10" -DMSVC_3RDPARTY_ROOT:PATH=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/FGRun -DFLTK_FLUID_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/fluid.exe -DGETTEXT_MSGFMT_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgfmt.exe -DGETTEXT_MSGMERGE_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgmerge.exe -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL
