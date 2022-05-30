/******************************************************************************
 *                                                                                                                    *
 * Copyright (C) 2019 Fondazione Istituto Italiano di Tecnologia (IIT)          *
 * All Rights Reserved.                                                                                   *
 *                                                                                                                    *
 ******************************************************************************/

 

/**
 * @file main.cpp
 * @authors: Valentina Gaggero <valentina.gaggero@iit.it>
 * 
 * \brief This application checks if yarprobotinterface is running and if it has created all 
 * configured devices successfully.
 * 
 * checkRobotInterface has two parameters:
 *   @robot: used to connect to the port /@robot/yarprobotinterface. the default value is icub
 *   @timeout: [expressed in seconds] If yarprobotinterface is not ready before timeout expires, this application returns error.
 *             The default value is 180 seconds 
 *
 * example of usage: checkRobotInterface --robot icub --timeout 120 
 */




#include <yarp/os/ResourceFinder.h>
#include <yarp/os/Network.h>
#include <yarp/os/SystemClock.h>
#include <yarp/os/Log.h>
#include <yarp/os/LogStream.h>
#include <yarp/os/Port.h>


using namespace yarp::os;

int main(int argc, char *argv[])
{
    const std::string request="is_ready";
    const std::string reply="[ok]";
    const std::string logName = "checkRobotInterface:";
    const double default_conn_timeout = 180.0; //seconds 
    const std::string default_robotName = "icub";
    Network yarpNetworkInitializer; //thi object is necessary to init all default sevices of yarp framework
    
    // 1. read input parameters
    ResourceFinder rf;
    rf.configure(argc, argv);
    std::string robotName=rf.find("robot").asString();
    double conn_timeout=rf.find("timeout").asFloat64();
    
    if(robotName=="")
        robotName=default_robotName;
    
    if(conn_timeout==0.0)
        conn_timeout=default_conn_timeout;
    
    std::string port_robotIntarface="/" + robotName+ "/yarprobotinterface";

    // 2. open the port
    Port port;
    double startTime = SystemClock::nowSystem();
    while(!port.open("...") && (SystemClock::nowSystem() <= startTime+conn_timeout))
    {
        yError() << logName << "Error opening temp port";
        SystemClock::delaySystem(1.0);
    }

    ContactStyle style;
    style.quiet = true;
    style.timeout = 60.0;
    bool ret;
    bool isConnected=false;
    bool responseIsOk=false;

    yInfo() << logName << "starts checking port" << port_robotIntarface << "using timeout of" << conn_timeout << "seconds";
    
    // 3. loop to check if yarprobotinterface is running
    startTime = SystemClock::nowSystem();
    while(SystemClock::nowSystem() <= startTime+conn_timeout)
    {
        if(!isConnected)
        {
            yInfo() << logName << " I'm trying to connect to" << port_robotIntarface;
            ret = NetworkBase::connect(port.getName(), port_robotIntarface, style);
            if(ret)
            {
                isConnected = true;
                yInfo() << logName << "I'm connected to" << port_robotIntarface;
            }
        }
        else //already connected
        {
            Bottle msg, response;
            msg.fromString(request);
            ret = port.write(msg, response);
            if(ret && response.size()>0)
            {
                if(response.toString() == reply)
                {
                    responseIsOk = true;
                    yInfo() << logName << "Get response OK! yarprobotInteface has started all configured devices correctly";
                    break;
                }
                else
                {
                    yInfo() << logName << "Get response: " << response.toString()<< ". yarprobotinterface is not ready...";
                    responseIsOk=false;
                }
            }
            else
            {
                responseIsOk=false;
            }
        }
        SystemClock::delaySystem(1.0);
    }//end while
    

//    NetworkBase::disconnect(port.getName(), port_robotIntarface);
    if(responseIsOk)
        return 0;
    else
        return -1;

}
