cmake_minimum_required (VERSION 2.6.4)

include (ExternalProject)

project(FlightGear-Meta)

if(NOT CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install)
    message(STATUS "Default install dir to ${CMAKE_INSTALL_PREFIX}")
endif()

if (UNIX)
    set(BOOST_BOOTSTRAP "./bootstrap.sh" --prefix=${CMAKE_INSTALL_PREFIX})
else()
    set(BOOST_BOOTSTRAP "bootstrap.bat")
endif()

set(SG_DEPS OSG)
set(FG_DEPS SimGear)
set(SG_CMAKE_ARGS "")
set(FG_CMAKE_ARGS "")

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
              
    list(APPEND SG_DEPS Boost)
endif()  # of Apple

set(OSG_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
set(SG_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
set(FG_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})

# OpenSceneGraph configuration
set(OSG_SOURCE URL http://www.openscenegraph.org/downloads/developer_releases/OpenSceneGraph-3.2.0.zip)

if (APPLE)
    set(SDKROOT /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk)
    # force disable Qt and Jasper, and ensure an SDKROOT is set, or
    # osgViewer system detection goes wrongh
    set(OSG_CMAKE_ARGS -DCMAKE_OSX_SYSROOT=${SDKROOT} 
        -DOSG_USE_QT=0 
        -DJASPER_LIBRARY= 
        -DSDL_LIBRARY:FILEPATH=
        -DCMAKE_OSX_ARCHITECTURES=x86_64
        -DCMAKE_OSX_DEPLOYMENT_TARGET=10.7
    )
    # OSG with some patches applied for Mac
    # set(OSG_SOURCE GIT_REPOSITORY git://gitorious.org/+flightgear-developers/openscenegraph/mac-release-osg.git)
    # set(OSG_SOURCE URL http://www.openscenegraph.org/downloads/developer_releases/OpenSceneGraph-3.2.0.zip)

elseif(MSVC)
    set(OSG_MSVC "msvc")
    if (${MSVC_VERSION} EQUAL 1700)
        set(OSG_MSVC ${OSG_MSVC}110)
    elseif (${MSVC_VERSION} EQUAL 1600)
        set(OSG_MSVC ${OSG_MSVC}100)
    else (${MSVC_VERSION} EQUAL 1700)
        set(OSG_MSVC ${OSG_MSVC}90)
    endif (${MSVC_VERSION} EQUAL 1700)
    if (CMAKE_CL_64)
        set(OSG_MSVC ${OSG_MSVC}-64)
        set(WIN_TAG x64)
        set(RDPARTY_DIR 3rdParty.x64)
    else ()
        set(WIN_TAG win32)
        set(RDPARTY_DIR 3rdParty)
    endif (CMAKE_CL_64)
  
    SET(OSG_CMAKE_ARGS
        -DACTUAL_3RDPARTY_DIR:PATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}
        -DBUILD_OSG_APPLICATIONS:BOOL=ON
        -DCMAKE_INSTALL_PREFIX:PATH=
        -DOSG_PLUGIN_SEARCH_INSTALL_DIR_FOR_PLUGINS:BOOL=OFF
        -DFREETYPE_LIBRARY:FILEPATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/lib/freetype243.lib
        -DGDAL_INCLUDE_DIR:PATH=
        -DGDAL_LIBRARY:FILEPATH=
    )

    # for compatability with MSVC directory layout
    set(OSG_INSTALL_PREFIX ${OSG_INSTALL_PREFIX}/${OSG_MSVC}/OpenSceneGraph)
    set(FG_INSTALL_PREFIX ${FG_INSTALL_PREFIX}/${OSG_MSVC}/FlightGear)
    set(SG_INSTALL_PREFIX ${SG_INSTALL_PREFIX}/${OSG_MSVC}/SimGear)
    list(APPEND OSG_DEPS WinDeps)
else()
    # normal OSG
    set(OSG_INSTALL_PREFIX ${OSG_INSTALL_PREFIX}/OpenSceneGraph)
    set(FG_INSTALL_PREFIX ${FG_INSTALL_PREFIX}/FlightGear)
    set(SG_INSTALL_PREFIX ${SG_INSTALL_PREFIX}/SimGear)
endif()

if (MSVC)
    # download 3rdparty dependencies zip, including boost
    ExternalProject_Add(WinDeps
        DOWNLOAD_COMMAND URL http://files.goneabitbursar.com/fg/fgfs-${WIN_TAG}-VS100-3rdParty+OSG-20120411.zip
        # extract to current root
        SOURCE_DIR ${CMAKE_BINARY_DIR}/winDeps 
        BINARY_DIR ${CMAKE_BINARY_DIR} 
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${CMAKE_SOURCE_DIR}/installWinDeps.bat
        INSTALL_COMMAND ""
    )
	
    set(BOOST_ARGS link=static stage --with-system)
    set( Boost_Version 1.54.0 )
    string( REPLACE "." "_" Boost_Version_Underscore ${Boost_Version} )

    ExternalProject_Add(Boost
        PREFIX ${CMAKE_BINARY_DIR}
        URL http://downloads.sourceforge.net/project/boost/boost/${Boost_Version}/boost_${Boost_Version_Underscore}.zip
        URL_MD5 78a35834c45220a6164310e280abe675
        UPDATE_COMMAND "bootstrap.bat"
        CONFIGURE_COMMAND ""
        BUILD_COMMAND bjam --with-program_options ${BOOST_ARGS}
        BUILD_IN_SOURCE 1
        INSTALL_COMMAND ""
    )
				
    list(APPEND SG_DEPS Boost)
	
    list(APPEND SG_CMAKE_ARGS -DBOOST_ROOT=${CMAKE_BINARY_DIR}/src/Boost)
    list(APPEND FG_CMAKE_ARGS -DBOOST_ROOT=${CMAKE_BINARY_DIR}/src/Boost)
endif(MSVC) # of Windows

message(STATUS "OSG install prefix is ${OSG_INSTALL_PREFIX}")
ExternalProject_Add(OSG
    DEPENDS ${OSG_DEPS}
    PREFIX ${CMAKE_BINARY_DIR}
    ${OSG_SOURCE}
    URL_HASH MD5=4980f8692712a24d4c99f363f80c6814
    BINARY_DIR osgbuild
    CMAKE_ARGS ${OSG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${OSG_INSTALL_PREFIX}
    # force Release build of OpenSceneGraph
    # BUILD_COMMAND "cmake --build . --config Release"
)

# FIXME install of OpenRTI is failing on Windows, files in PREFIX/share which
# are ending up in C:/Program Files/OpenRTI
if (NOT MSVC)
    ExternalProject_Add(OpenRTI
        PREFIX ${CMAKE_BINARY_DIR}
        DOWNLOAD_COMMAND GIT_REPOSITORY git://gitorious.org/openrti/openrti.git
        BINARY_DIR rtibuild 
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    )
	
    list(APPEND SG_DEPS OpenRTI)
    list(APPEND SG_CMAKE_ARGS -DENABLE_RTI=1)
    list(APPEND FG_CMAKE_ARGS -DENABLE_RTI=1)
endif()

ExternalProject_Add(SimGear 
    PREFIX ${CMAKE_BINARY_DIR}
    DEPENDS ${SG_DEPS}
    DOWNLOAD_COMMAND ""    # no need to download
    UPDATE_COMMAND ""      # or update.
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/simgear
    BINARY_DIR sgbuild 
    CMAKE_ARGS ${SG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${SG_INSTALL_PREFIX} -DCMAKE_PREFIX_PATH=${OSG_INSTALL_PREFIX}
)

# on Windows, PLIB is in the 3rd-party dependencies zip
if (NOT WIN32)
    SET(PLIB_ARGS --disable-pw --disable-sl --disable-psl --disable-ssg --disable-ssgaux)

    ExternalProject_Add(PLIB 
        PREFIX ${CMAKE_BINARY_DIR}
        URL http://plib.sourceforge.net/dist/plib-1.8.5.tar.gz
        URL_HASH MD5=47a6fbf63668c1eed631024038b2ea90
        CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX} ${PLIB_ARGS}
        BUILD_IN_SOURCE 1
    )
    
    list(APPEND FG_DEPS PLIB)
endif()

ExternalProject_Add(FlightGear
    PREFIX ${CMAKE_BINARY_DIR}
    DEPENDS ${FG_DEPS}
    DOWNLOAD_COMMAND ""    # no need to download
    UPDATE_COMMAND ""      # or update.
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/flightgear
    BINARY_DIR fgbuild 
    CMAKE_ARGS ${FG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${FG_INSTALL_PREFIX} -DCMAKE_PREFIX_PATH="${OSG_INSTALL_PREFIX};${SG_INSTALL_PREFIX}"
)
