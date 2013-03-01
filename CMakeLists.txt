cmake_minimum_required (VERSION 2.6.4)

include (ExternalProject)

project(FlightGear-Meta)

if (UNIX)
    set(BOOST_BOOTSTRAP "./bootstrap.sh" --prefix=${CMAKE_INSTALL_PREFIX})
else()
    set(BOOST_BOOTSTRAP "bootstrap.bat")
endif()

if(APPLE)

    set(BOOST_ARGS link=static stage --with-system)
    ExternalProject_Add(Boost
           PREFIX ${CMAKE_BINARY_DIR}
           SVN_REPOSITORY http://svn.boost.org/svn/boost/tags/release/Boost_1_52_0
           UPDATE_COMMAND ${BOOST_BOOTSTRAP}
           CONFIGURE_COMMAND ""
           BUILD_COMMAND ./bjam ${BOOST_ARGS}
           BUILD_IN_SOURCE 1
           INSTALL_COMMAND ./b2 install ${BOOST_ARGS})
endif()  # of Apple

set (OSG_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})

if (APPLE)
    SET(SDKROOT /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk)
    # force disable Qt and Jasper, and ensure an SDKROOT is set, or
    # osgViewer system detection goes wrongh
    SET(OSG_CMAKE_ARGS -DCMAKE_OSX_SYSROOT=${SDKROOT} 
        -DOSG_USE_QT=0 
        -DJASPER_LIBRARY= 
        -DCMAKE_OSX_ARCHITECTURES=x86_64
        -DCMAKE_OSX_DEPLOYMENT_TARGET=10.7
    )
    # OSG with some patches applied for Mac
#    SET(OSG_SOURCE GIT_REPOSITORY git://gitorious.org/+flightgear-developers/openscenegraph/mac-release-osg.git)
    SET(OSG_SOURCE URL http://www.openscenegraph.org/downloads/developer_releases/OpenSceneGraph-3.1.4.zip)

elseif(MSVC)
	set( OSG_MSVC "msvc" )
  if (${MSVC_VERSION} EQUAL 1700)
      set( OSG_MSVC ${OSG_MSVC}110 )
  elseif (${MSVC_VERSION} EQUAL 1600)
      set( OSG_MSVC ${OSG_MSVC}100 )
  else (${MSVC_VERSION} EQUAL 1700)
      set( OSG_MSVC ${OSG_MSVC}90 )
  endif (${MSVC_VERSION} EQUAL 1700)
  
	SET(OSG_CMAKE_ARGS
		-DACTUAL_3RDPARTY_DIR:PATH=${CMAKE_BINARY_DIR}/3rdParty
		-DBUILD_OSG_APPLICATIONS:BOOL=ON
		-DCMAKE_INSTALL_PREFIX:PATH=
		-DOSG_PLUGIN_SEARCH_INSTALL_DIR_FOR_PLUGINS:BOOL=OFF
		-DFREETYPE_LIBRARY:FILEPATH=${CMAKE_BINARY_DIR}/3rdParty/lib/freetype243.lib
		-DGDAL_INCLUDE_DIR:PATH=
		-DGDAL_LIBRARY:FILEPATH=
    )
	
	# for compatability with MSVC directory layout
	set(OSG_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install/${OSG_MSVC}/OpenSceneGraph)
	SET(OSG_SOURCE URL http://www.openscenegraph.org/downloads/developer_releases/OpenSceneGraph-3.1.4.zip)
else()
    # normal OSG
    SET(OSG_SOURCE URL http://www.openscenegraph.org/downloads/developer_releases/OpenSceneGraph-3.1.4.zip)
endif()

if (MSVC)
# download 3rdpart dependeancies zip, including boost
	ExternalProject_Add(WinDeps
		DOWNLOAD_COMMAND URL http://files.goneabitbursar.com/fg/fgfs-win32-VS100-3rdParty+OSG-20120411.zip
# extract to current root
		SOURCE_DIR ${CMAKE_BINARY_DIR}/winDeps 
		BINARY_DIR ${CMAKE_BINARY_DIR} 
		CONFIGURE_COMMAND ""
		BUILD_COMMAND ${CMAKE_SOURCE_DIR}/installWinDeps.bat
		INSTALL_COMMAND ""
	)
endif() # of Windows

ExternalProject_Add(OSG
	DEPENDS WinDeps
    PREFIX ${CMAKE_BINARY_DIR}
    ${OSG_SOURCE}
    BINARY_DIR osgbuild
    CMAKE_ARGS ${OSG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${OSG_INSTALL_PREFIX}
# force Release build of OpenSceneGraph
#	BUILD_COMMAND "cmake --build . --config Release"
    )

set(SG_CMAKE_ARGS -DENABLE_PACKAGE=1)
set(FG_CMAKE_ARGS "")

if (FALSE)
ExternalProject_Add(OpenRTI
    PREFIX ${CMAKE_BINARY_DIR}
    DOWNLOAD_COMMAND GIT_REPOSITORY git://gitorious.org/openrti/openrti.git
    BINARY_DIR rtibuild 
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    )
	
	list(APPEND SG_CMAKE_ARGS -DENABLE_RTI=1)
	list(APPEND FG_CMAKE_ARGS -DENABLE_RTI=1)
endif()



if (WIN32)
	list(APPEND SG_CMAKE_ARGS -DBOOST_ROOT=${CMAKE_BINARY_DIR})
	list(APPEND FG_CMAKE_ARGS -DBOOST_ROOT=${CMAKE_BINARY_DIR})
endif()

ExternalProject_Add(SimGear 
    PREFIX ${CMAKE_BINARY_DIR}
    DEPENDS OSG
    DOWNLOAD_COMMAND ""     # no need to download
    UPDATE_COMMAND       ""    # or update.
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/simgear
    BINARY_DIR sgbuild 
    CMAKE_ARGS ${SG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX})

# on Windows, PLIB is in the 3rd-party dependancies zip
if (NOT WIN32)
	SET(PLIB_ARGS --disable-pw --disable-sl --disable-psl --disable-ssg --disable-ssgaux)

	ExternalProject_Add(PLIB 
		PREFIX ${CMAKE_BINARY_DIR}
		URL http://plib.sourceforge.net/dist/plib-1.8.5.tar.gz
		CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX} ${PLIB_ARGS}
		BUILD_IN_SOURCE 1
	)
endif()

ExternalProject_Add(FlightGear
    PREFIX ${CMAKE_BINARY_DIR}
    DEPENDS SimGear OSG
    DOWNLOAD_COMMAND ""     # no need to download
    UPDATE_COMMAND       ""    # or update.
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/flightgear
    BINARY_DIR fgbuild 
    CMAKE_ARGS ${FG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} )
