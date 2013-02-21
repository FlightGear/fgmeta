cmake_minimum_required (VERSION 2.6.4)

include (ExternalProject)

project(FlightGear-Meta)

if (UNIX)
    set(BOOST_BOOTSTRAP "./bootstrap.sh" --prefix=${CMAKE_INSTALL_PREFIX})
else()
    set(BOOST_BOOTSTRAP "bootstrap.bat")
endif()

if(NOT CMAKE_SYSTEM_NAME MATCHES "Linux")
    ExternalProject_Add(Archive
        PREFIX ${CMAKE_BINARY_DIR}
        URL http://www.libarchive.org/downloads/libarchive-3.1.2.tar.gz
        BINARY_DIR archivebuild
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX})

    set(BOOST_ARGS link=static stage --with-system)
    ExternalProject_Add(Boost
           PREFIX ${CMAKE_BINARY_DIR}
           SVN_REPOSITORY http://svn.boost.org/svn/boost/tags/release/Boost_1_52_0
           UPDATE_COMMAND ${BOOST_BOOTSTRAP}
           CONFIGURE_COMMAND ""
           BUILD_COMMAND ./bjam ${BOOST_ARGS}
           BUILD_IN_SOURCE 1
           INSTALL_COMMAND ./b2 install ${BOOST_ARGS})
endif()  # of Linux

if (APPLE)
    SET(SDKROOT /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk)
    SET(OSG_CMAKE_ARGS -DCMAKE_OSX_SYSROOT=${SDKROOT} -DOSG_USE_QT=0)
    # OSG with some patches applied for Mac
    SET(OSG_SOURCE GIT_REPOSITORY git://gitorious.org/+flightgear-developers/openscenegraph/mac-release-osg.git)
else()
    # normal OSG
    SET(OSG_SOURCE SVN_REPOSITORY http://www.openscenegraph.org/svn/osg/OpenSceneGraph/tags/OpenSceneGraph-3.1.2)
endif()

if (WIN32)
#    ExternalProject_Add(OpenAL )
endif() # of Windows

ExternalProject_Add(OSG
    PREFIX ${CMAKE_BINARY_DIR}
    ${OSG_SOURCE}
    BINARY_DIR osgbuild
    CMAKE_ARGS ${OSG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    )

ExternalProject_Add(SimGear 
    PREFIX ${CMAKE_BINARY_DIR}
    DEPENDS OSG Boost Archive
    DOWNLOAD_COMMAND ""     # no need to download
    UPDATE_COMMAND       ""    # or update.
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/simgear
    BINARY_DIR sgbuild 
    CMAKE_ARGS ${SG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX})

SET(PLIB_ARGS --disable-pw --disable-sl --disable-psl --disable-ssg --disable-ssgaux)

ExternalProject_Add(PLIB 
    PREFIX ${CMAKE_BINARY_DIR}
    URL http://plib.sourceforge.net/dist/plib-1.8.5.tar.gz
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX} ${PLIB_ARGS}
    BUILD_IN_SOURCE 1
)

ExternalProject_Add(FlightGear
    PREFIX ${CMAKE_BINARY_DIR}
    DEPENDS SimGear PLIB
    DOWNLOAD_COMMAND ""     # no need to download
    UPDATE_COMMAND       ""    # or update.
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/flightgear
    BINARY_DIR fgbuild 
    CMAKE_ARGS ${FG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} )

