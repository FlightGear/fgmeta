IF NOT DEFINED WORKSPACE SET WORKSPACE=%~dp0


SET /P SIMGEAR_VERSION=<%WORKSPACE%\simgear\version
ECHO #define SIMGEAR_VERSION "%SIMGEAR_VERSION%" > %WORKSPACE%\simgear\simgear\version.h

rem ECHO #define SIMGEAR_VERSION "2.9.0" > %WORKSPACE%\simgear\simgear\version.h
rem set PATH=%PATH%;D:\Program Files (x86)\CMake 2.8\bin
rem call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" amd64

md build-sg64
md build-fg64
md build-fgrun64
cd build-sg64
cmake ..\SimGear -G "Visual Studio 10 Win64" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/SimGear -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config RelWithDebInfo --target INSTALL

cd ..\build-fg64
cmake ..\flightgear -G "Visual Studio 10 Win64" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/FlightGear -DFLTK_FLUID_EXECUTABLE=%WORKSPACE%/3rdParty/bin/fluid.exe -DBOOST_ROOT=%WORKSPACE%/Boost -DWITH_FGPANEL=OFF -DENABLE_PROFILE=OFF
cmake --build . --config RelWithDebInfo --target INSTALL

cd ..\build-fgrun64
cmake ..\fgrun -G "Visual Studio 10 Win64" -DMSVC_3RDPARTY_ROOT:PATH=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/FGRun -DFLTK_FLUID_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/fluid.exe -DGETTEXT_MSGFMT_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgfmt.exe -DGETTEXT_MSGMERGE_EXECUTABLE:FILEPATH=%WORKSPACE%/3rdParty/bin/msgmerge.exe -DBOOST_ROOT=%WORKSPACE%/Boost
cmake --build . --config Release --target INSTALL
