cmake_minimum_required (VERSION 2.8.0)

include (ExternalProject)

project(FlightGear-Meta)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install)
    message(STATUS "Default install dir set to ${CMAKE_INSTALL_PREFIX}")
endif()

set(SG_DEPS OSG)
set(FG_DEPS SimGear)
set(SG_CMAKE_ARGS "")
set(FG_CMAKE_ARGS "")


set(OSG_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
set(SG_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
set(FG_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
set(PLIB_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
set(RTI_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})


# OpenSceneGraph configuration
#set(OSG_SOURCE http://www.openscenegraph.org/downloads/developer_releases/OpenSceneGraph-3.2.0.zip)
set(OSG_SOURCE https://github.com/openscenegraph/osg.git)
set(OSG_TAG OpenSceneGraph-3.2)

if (APPLE)
    # force disable Qt and Jasper
    set(OSG_CMAKE_ARGS
        -DOSG_USE_QT=0 
        -DJASPER_LIBRARY= 
    )
    # OSG with some patches applied for Mac
    set(OSG_SOURCE https://github.com/zakalawe/osg.git)
    set(OSG_TAG fgfs-osg-32)
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
        set(RDPARTY_DIR 3rdParty.x64)
        list(APPEND FG_CMAKE_ARGS -DWITH_FGPANEL=OFF)
    else ()
        set(RDPARTY_DIR 3rdParty)
    endif (CMAKE_CL_64)
  
    SET(OSG_CMAKE_ARGS
        -DOSG_USE_QT:BOOL=OFF
        -DBUILD_OSG_APPLICATIONS:BOOL=ON
        -DOSG_PLUGIN_SEARCH_INSTALL_DIR_FOR_PLUGINS:BOOL=OFF
        -DACTUAL_3RDPARTY_DIR:PATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}
        -DCMAKE_LIBRARY_PATH:STRING=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/lib
        -DCMAKE_INCLUDE_PATH:STRING=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/include;${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/include/freetype
        -DCURL_INCLUDE_DIR:PATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/include
        -DTIFF_INCLUDE_DIR:PATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/include
        -DGDAL_INCLUDE_DIR:PATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/include
        -DGDAL_LIBRARY:FILEPATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/lib/gdal_i.lib
        -DTIFF_LIBRARY:FILEPATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/lib/libtiff.lib
        -DCURL_LIBRARY:FILEPATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/lib/libcurl_imp.lib
        -DFREETYPE_LIBRARY:FILEPATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/lib/freetype.lib
        -DFREETYPE_INCLUDE_DIR:PATH=${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/include;${CMAKE_BINARY_DIR}/${RDPARTY_DIR}/include/freetype
    )

    # for compatability with MSVC directory layout
    set(OSG_INSTALL_PREFIX ${OSG_INSTALL_PREFIX}/${OSG_MSVC}/OpenSceneGraph)
    set(FGRUN_INSTALL_PREFIX ${FGRUN_INSTALL_PREFIX}/${OSG_MSVC}/FGRun)
    set(FG_INSTALL_PREFIX ${FG_INSTALL_PREFIX}/${OSG_MSVC}/FlightGear)
    set(SG_INSTALL_PREFIX ${SG_INSTALL_PREFIX}/${OSG_MSVC}/SimGear)
    list(APPEND OSG_DEPS WinDeps)
else()
    # normal OSG
endif()


ExternalProject_Add(OSG
    DEPENDS ${OSG_DEPS}
    PREFIX ${CMAKE_BINARY_DIR}
    GIT_REPOSITORY ${OSG_SOURCE}
    GIT_TAG ${OSG_TAG}
    BINARY_DIR osgbuild
    CMAKE_ARGS ${OSG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${OSG_INSTALL_PREFIX}
)

# Because OSG install the libraries in lib64/ instead of lib/

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    ExternalProject_Add_Step(OSG after_install
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${OSG_INSTALL_PREFIX}/lib64 ${OSG_INSTALL_PREFIX}/lib
        DEPENDEES install
    )
endif()

# FIXME install of OpenRTI is failing on Windows, files in PREFIX/share which
# are ending up in C:/Program Files/OpenRTI
if (FALSE)
    ExternalProject_Add(OpenRTI
        PREFIX ${CMAKE_BINARY_DIR}
        DOWNLOAD_COMMAND GIT_REPOSITORY git://gitorious.org/openrti/openrti.git
        BINARY_DIR rtibuild 
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${RTI_INSTALL_PREFIX}
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

# because we download SimGear externally (via Git submodules),
# the change-detection doesn't work. Ensure we always change
# for changes
ExternalProject_Add_Step(SimGear forcebuild
        ALWAYS 1
		COMMAND ${CMAKE_COMMAND} -E echo foo
        DEPENDERS build
    )
	
# on Windows, PLIB is in the 3rd-party dependencies zip
if (NOT WIN32)
    set(PLIB_ARGS --disable-pw --disable-sl --disable-psl --disable-ssg --disable-ssgaux)

    ExternalProject_Add(PLIB 
        PREFIX ${CMAKE_BINARY_DIR}
        URL http://plib.sourceforge.net/dist/plib-1.8.5.tar.gz
        URL_HASH MD5=47a6fbf63668c1eed631024038b2ea90
        CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${PLIB_INSTALL_PREFIX} ${PLIB_ARGS}
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
    CMAKE_ARGS ${FG_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${FG_INSTALL_PREFIX} -DCMAKE_PREFIX_PATH=${OSG_INSTALL_PREFIX} -DADDITIONAL_LIBRARY_PATHS=${SG_INSTALL_PREFIX}
)

# because we download FlightGear externally (via Git submodules),
# the change-detection doesn't work. Ensure we always change
# for changes
ExternalProject_Add_Step(FlightGear forcebuild
        ALWAYS 1
		COMMAND ${CMAKE_COMMAND} -E echo foo
        DEPENDERS build
    )
