# Copyright (C) 2019 Fondazione Istituto Italiano di Tecnologia (IIT)  
# All Rights Reserved.
# Authors: Vadim Tikhanoff <vadim.tikhanoff@iit.it>


project(CameraPanCalibration)
cmake_minimum_required(VERSION 3.5)

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED 11)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

find_package(ICUBcontrib REQUIRED)
find_package(OpenCV REQUIRED)
find_package(YARP 3.2.1 REQUIRED COMPONENTS OS sig dev math)

yarp_add_idl(IDL_GEN_FILES ${PROJECT_NAME}.thrift)

set(idl ${PROJECT_NAME}.thrift)
set(doc_files ${PROJECT_NAME}.xml)

source_group("Source Files" FILES ${source})
source_group("Header Files" FILES ${header})
source_group("IDL Files" FILES ${idl})
source_group("DOC Files" FILES ${doc})

add_executable(${PROJECT_NAME} main.cpp ${idl} ${IDL_GEN_FILES} ${doc} ${GRPC_SRCS} ${GRPC_HDRS} )

target_include_directories(${PROJECT_NAME} PRIVATE ${PROJECT_SOURCE_DIR}/include)
target_link_libraries(${PROJECT_NAME} ${YARP_LIBRARIES} ${OpenCV_LIBRARIES} )
install(TARGETS ${PROJECT_NAME} DESTINATION bin)
yarp_install(FILES  DESTINATION ${ICUBCONTRIB_MODULES_INSTALL_DIR})

add_subdirectory(app)

include(GNUInstallDirs)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")


list(APPEND CMAKE_MODULE_PATH ${ICUBCONTRIB_MODULE_PATH})

include(ICUBcontribOptions)
include(ICUBcontribHelpers)

if(NOT CMAKE_CONFIGURATION_TYPES)
  if(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Setting build type to 'Release' as none was specified.")
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY VALUE "Release")
  endif()
endif()

icubcontrib_set_default_prefix()

include_directories(${OpenCV_INCLUDE_DIRS})

