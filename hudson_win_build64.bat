
IF NOT DEFINED WORKSPACE SET WORKSPACE=%~dp0

ECHO #define SIMGEAR_VERSION "2.6.0" > %WORKSPACE%\simgear\simgear\version.h
rem set PATH=%PATH%;D:\Program Files (x86)\CMake 2.8\bin
rem call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" amd64
md build-sg64
rem md build-fg64
cd build-sg64
cmake ..\SimGear -G "Visual Studio 10 Win64" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100-64/SimGear
cmake --build . --config Release --target INSTALL

rem cd ..\build-fg64
rem cmake ..\flightgear -G "Visual Studio 10" -DMSVC_3RDPARTY_ROOT=%WORKSPACE% -DCMAKE_INSTALL_PREFIX:PATH=%WORKSPACE%/install/msvc100/FlightGear -DFLTK_FLUID_EXECUTABLE=%WORKSPACE%/3rdParty/bin/fluid.exe
rem cmake --build . --config Release --target INSTALL
