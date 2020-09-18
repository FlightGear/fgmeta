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
cp -d dist/lib64/* appdir/usr/lib
cp -a dist/lib64/osgPlugins-3.4.2 appdir/usr/lib
cp -r dist/share appdir/usr

# FIXME : only copy the QML plugins we actually need
cp -a /usr/lib64/qt5/qml/QtQuick* appdir/usr/qml

cp /usr/lib64/libsoftokn3.* appdir/usr/lib
cp /usr/lib64/libnsspem.so appdir/usr/lib
cp /etc/pki/tls/certs/ca-bundle.crt appdir/usr/ssl/cacert.pem

#modify the desktop file so that linuxdeployqt doesn't barf (version to 1.0, add semicolon to end of certain line types)
sed -i 's/^Categor.*/&;/ ; s/^Keyword.*/&;/ ; s/1\.1/1\.0/' appdir/usr/share/applications/org.flightgear.FlightGear.desktop

#generate AppRun script

cat << 'EOF' > appdir/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export SIMGEAR_TLS_CERT_PATH=$HERE/usr/ssl/cacert.pem
echo SIMGEAR_TLS_CERT_PATH=$SIMGEAR_TLS_CERT_PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${HERE}/usr/lib
echo LD_LIBRARY_PATH=$LD_LIBRARY_PATH
exec "${HERE}/usr/bin/fgfs" "$@"
EOF


chmod +x appdir/AppRun

#grab continuous linuxdeployqt
wget -c https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage
chmod +x linuxdeployqt-continuous-x86_64.AppImage

#set VERSION for AppImage creation
export VERSION=`cat flightgear/flightgear-version`

./linuxdeployqt-continuous-x86_64.AppImage appdir/usr/share/applications/org.flightgear.FlightGear.desktop -appimage
