cmake_minimum_required(VERSION 3.5)
# find YARP
find_package(YARP REQUIRED)
# set up our program
add_executable(checkRobotInterface ./src/main.cpp )
# link with YARP libraries
target_link_libraries(checkRobotInterface ${YARP_LIBRARIES})
