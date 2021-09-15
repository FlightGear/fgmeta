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

# OSG 3.6 uses lib, not lib64
cp -d dist/lib/* appdir/usr/lib
cp -a dist/lib/osgPlugins-3.6.5 appdir/usr/lib

# adjust the rpath on the copied plugins, so they don't
# require LD_LIBRARY_PATH to be set to load their dependencies
# correctly
patchelf --set-rpath \$ORIGIN/../ appdir/usr/lib/osgPlugins-3.6.5/*.so

cp -r dist/share appdir/usr

# FIXME : only copy the QML plugins we actually need
#cp -a /usr/lib64/qt5/qml/QtQuick* appdir/usr/qml
#cp -a /usr/lib64/qt5/qml/QtQml* appdir/usr/qml

cp /usr/lib64/libsoftokn3.* appdir/usr/lib
cp /usr/lib64/libnsspem.so appdir/usr/lib
cp /usr/lib64/libfreebl* appdir/usr/lib
cp -a /usr/lib64/liblzma* appdir/usr/lib
cp /etc/pki/tls/certs/ca-bundle.crt appdir/usr/ssl/cacert.pem

# HarfBuzz is in /lib64 on CentOS, but still copy it: see
# https://sourceforge.net/p/flightgear/codetickets/2590/
cp -a /lib64/libharfbuzz.so* appdir/usr/lib

# as we are copying over libharfbuzz we need the older libfontconfig,
# libfreetype & libpng15 as 2.11 breaks compatibility: see 
# https://sourceforge.net/p/flightgear/codetickets/2651/
cp -a /usr/lib64/libfontconfig.so* appdir/usr/lib
cp -a /usr/lib64/libfreetype.so* appdir/usr/lib
cp -a /usr/lib64/libpng15.so* appdir/usr/lib
patchelf --set-rpath \$ORIGIN appdir/usr/lib/libfontconfig.so
patchelf --set-rpath \$ORIGIN appdir/usr/lib/libfreetype.so
patchelf --set-rpath \$ORIGIN appdir/usr/lib/libharfbuzz.so

#modify the desktop file so that linuxdeployqt doesn't barf (version to 1.0, add semicolon to end of certain line types)
sed -i 's/^Categor.*/&;/ ; s/^Keyword.*/&;/ ; s/1\.1/1\.0/' appdir/usr/share/applications/org.flightgear.FlightGear.desktop

#generate AppRun script

cat << 'EOF' > appdir/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
BIN_DIR="${HERE}/usr/bin"
EXEC_OPT="--exec-app"

export SIMGEAR_TLS_CERT_PATH=$HERE/usr/ssl/cacert.pem
export OSG_LIBRARY_PATH=${HERE}/usr/lib

# Run launcher directly if no parameters are passed
if [[ "$#" -eq "0" ]]; then
 echo "Started with no arguments; assuming --launcher"
 exec "${HERE}/usr/bin/fgfs" --launcher
 exit "$?"
fi

# Check for special argument "--exec-app=" and execute selected application
if [[ "$1" == ${EXEC_OPT}=* ]] || [[ "$1" == "${EXEC_OPT}" ]]; then
 OPT_VAL="${1#*=}"
 APP_PATH="${BIN_DIR}/${OPT_VAL}"

 # Call without arguments
 if [[ "$1" == "${EXEC_OPT}" ]] || [[ -z "${OPT_VAL}" ]]; then
  ERROR="1"
 # Make sure executable name does not contain any "/"
 elif [[ "${OPT_VAL}" == */* ]]; then
  echo "Error: path separator \"/\" was used in application name!"
  ERROR="1"
 # Check if resulting file exists and is executable
 elif [[ -z "$(find "${APP_PATH}" -type f \( \( -perm -00005 -a ! -user "$(id -u)" -a ! -group "$(id -g)" \) -o \( -perm -00500 -a -user "$(id -u)" \) -o \( -perm -00050 -a -group "$(id -g)" \) \) 2>/dev/null)" ]]; then 
  echo "Error: \"${OPT_VAL}\" is not a valid application name or cannot be executed by current user!"
  ERROR="1"
 fi

 # In case of error or no arguments show help
 if [[ ! -z "${ERROR}" ]]; then
 
  # Determine AppImage's filename
  IMAGE_FILE_NAME="$(basename "${APPIMAGE}" 2>/dev/null)"
  if [[ -z "${IMAGE_FILE_NAME}" ]]; then
   IMAGE_FILE_NAME="FlightGear.AppImage"
  fi
 
  # Print help
  echo "Usage: ./${IMAGE_FILE_NAME} ${EXEC_OPT}=<application>"
  echo "Pass ${EXEC_OPT} as first positional argument."
  echo "Additional arguments are passed to the called application."
  echo "Valid values for <application> are:"
  while IFS= read -r -d $'\0' bin_exe; do
   echo "  $(basename "${bin_exe}")"
  done < <( find "${BIN_DIR}/" -maxdepth 1 -type f \( \( -perm -00005 -a ! -user "$(id -u)" -a ! -group "$(id -g)" \) -o \( -perm -00500 -a -user "$(id -u)" \) -o \( -perm -00050 -a -group "$(id -g)" \) \) -exec printf "%s\0" "{}" \; )
  # We have to use these odd find conditions since "find -executable" also lists non-executables when AppImage is executed. The reason is most likely the way it is mounted.
  exit 1
 fi

 # Execute selected application and pass remaining parameters
 # "pop" the first argument
 shift
 exec "${APP_PATH}" "$@"
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

# Add all executable binaries as additional binaries to AppImage and use special quoted array expansion
ADDITIONAL_EXES=()
while IFS= read -r -d $'\0' bin_exe; do
 ADDITIONAL_EXES+=("-executable=${bin_exe}")
done < <( find "appdir/usr/bin/" -maxdepth 1 -type f \( \( -perm -00500 -o -perm -00050 -o -perm -00005 \) -a ! -name "fgfs" \) -exec printf "%s\0" "{}" \; )
# This find statement filters for all files with at least one executability bit set

./linuxdeployqt-7-x86_64.AppImage appdir/usr/share/applications/org.flightgear.FlightGear.desktop -appimage -qmldir=flightgear/src/GUI/qml/ "${ADDITIONAL_EXES[@]}"
