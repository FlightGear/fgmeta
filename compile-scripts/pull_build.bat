
SET PATH=%PATH%;%ProgramFiles%\CMake\bin
SET QT5SDK64=C:\Qt\5.6\msvc2015_64
SET CMAKE_TOOLCHAIN="Visual Studio 14 Win64"
SET ROOT_DIR=%CD%

md osgbuild
md sgbuild
md fgbuild
REM md fgrun-build

cd simgear
git pull --rebase

cd ..\flightgear
git pull --rebase

REM cd ..\fgrun
REM git pull --rebase

cd ..\osgbuild
cmake ..\osg -G %CMAKE_TOOLCHAIN% ^
                 -DACTUAL_3RDPARTY_DIR:PATH=%ROOT_DIR%\windows-3rd-party\msvc140\3rdparty.x64 ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%\dist ^
                 -DOSG_USE_UTF8_FILENAME:BOOL=ON

cmake --build . --config Release --target INSTALL
cmake --build . --config Debug --target INSTALL

cd ..\sgbuild
cmake ..\simgear -G  %CMAKE_TOOLCHAIN% ^
                 -DMSVC_3RDPARTY_ROOT=%ROOT_DIR%\windows-3rd-party\msvc140 ^
                 -DOSG_FSTREAM_EXPORT_FIXED:BOOL=ON ^
                 -DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%\dist
cmake --build . --config Release --target INSTALL
cmake --build . --config Debug --target INSTALL

cd ..\fgbuild
cmake ..\flightgear -G  %CMAKE_TOOLCHAIN% ^
                    -DMSVC_3RDPARTY_ROOT=%ROOT_DIR%\windows-3rd-party\msvc140 ^
                    -DCMAKE_INSTALL_PREFIX:PATH=%ROOT_DIR%\dist ^
                    -DCMAKE_PREFIX_PATH=%QT5SDK64% ^
                    -DOSG_FSTREAM_EXPORT_FIXED:BOOL=ON
cmake --build . --config Release --target INSTALL
cmake --build . --config Debug --target INSTALL

REM cd ..\fgrun-build
REM cmake ..\fgrun -G  %CMAKE_TOOLCHAIN% ^
REM                     -DMSVC_3RDPARTY_ROOT=C:\FGFS\windows-3rd-party\msvc140 ^
REM                     -DCMAKE_INSTALL_PREFIX:PATH=C:\FGFS\dist
REM cmake --build . --config Release --target INSTALL
REM cmake --build . --config Debug --target INSTALL
