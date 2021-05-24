#!/bin/bash
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# builds Appimage on Centos 7 using linuxdeployqt from continuous build
# expects to work in $WORKSPACE, uses the contents of dist/{bin,share,lib64} copied into an appdir
# missing qt plugins are copied in manually, as are osgPlugins
# libcurl in SIMGEAR needs a setting to find the tls certificate, and OSG needs LD_LIBRARY_PATH so it can find osgPlugins
# currently not including FGDATA, but this could be done easily once FG is updated to change Nav database checks from path to some kind of checksum
# 
# issues/errors:
# can't find qt translations - missing something in my build?
# 
# errors/comments to enrogue@gmail.com

#clean up any previous build

rm -rf appdir

#create basic structure

mkdir -p appdir/usr/bin
mkdir -p appdir/usr/lib
mkdir -p appdir/usr/share
mkdir -p appdir/usr/qml
mkdir -p appdir/usr/ssl

#copy everything we need in

cp dist/bin/* appdir/usr/bin

cp -a dist/lib64/* appdir/usr/lib

# remove SimGearCore,Scene and any other static libs which leaked
rm appdir/usr/lib/lib*.a 

cp -a dist/lib64/osgPlugins-3.4.2 appdir/usr/lib

# adjust the rpath on the copied plugins, so they don't
# require LD_LIBRARY_PATH to be set to load their dependencies
# correctly
patchelf --set-rpath \$ORIGIN/../ appdir/usr/lib/osgPlugins-3.4.2/*.so

cp -r dist/share appdir/usr

cp -a /usr/lib64/qt5/qml/QtQuick.2 appdir/usr/qml

cp /usr/lib64/libsoftokn3.* appdir/usr/lib
cp /usr/lib64/libnsspem.so appdir/usr/lib
cp /usr/lib64/libfreebl* appdir/usr/lib
cp -a /usr/lib64/liblzma* appdir/usr/lib
cp /etc/pki/tls/certs/ca-bundle.crt appdir/usr/ssl/cacert.pem

#modify the desktop file so that linuxdeployqt doesn't barf (version to 1.0, add semicolon to end of certain line types)
sed -i 's/^Categor.*/&;/ ; s/^Keyword.*/&;/ ; s/1\.1/1\.0/' appdir/usr/share/applications/org.flightgear.FlightGear.desktop

#generate AppRun script

# Note: don't set LD_LIBRARY_PATH here.
# if you do, you need to add code to unset it *sinde* FlightGear (eg, bootstrap.cxx), 
# so that fork-ed processes don't inherit the value. For an example see:
# https://github.com/KDAB/hotspot/blob/master/src/main.cpp#L87

cat << 'EOF' > appdir/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export SIMGEAR_TLS_CERT_PATH=$HERE/usr/ssl/cacert.pem
export OSG_LIBRARY_PATH=${HERE}/usr/lib

if [[ $# -eq 0 ]]; then
 echo "Started with no arguments; assuming --launcher"
 exec "${HERE}/usr/bin/fgfs" --launcher
else
 exec "${HERE}/usr/bin/fgfs" "$@"
fi
EOF


chmod +x appdir/AppRun

#grab continuous linuxdeployqt
wget -c https://github.com/probonopd/linuxdeployqt/releases/download/7/linuxdeployqt-7-x86_64.AppImage
#wget -c https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage
chmod +x linuxdeployqt-7-x86_64.AppImage

#set VERSION for AppImage creation
export VERSION=`cat flightgear/flightgear-version`

./linuxdeployqt-7-x86_64.AppImage appdir/usr/share/applications/org.flightgear.FlightGear.desktop -appimage
