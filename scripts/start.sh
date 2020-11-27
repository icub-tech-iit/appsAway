#!/bin/bash

#1. copy the deploy file to the master pc 
scp someFolder/file2Deploy icub@IP_SWARM_MASTER:/someOtherFolder/file2Deploy.yml 

#2. run the deploy on matser pc
ssh icub@IP_SWARM_MASTER "docker stack deploy -c file2Deploy.yml mystack"

#3.run yarprobotinterface
scp someFolder/compose4Head icub@IP_icub-head:/someOtherFolder/compose4Head
ssh icub@icub-head "cd /someOtherFolder &&  docker-compose -f compose4Head.yml up"

#3.run gui applications
scp someFolder/compose4GuiApp.yml icub@PC_WITH_MONITOR:/someOtherFolder/compose4GuiApp.yml
ssh icub@PC_WITH_MONITOR "cd /someOtherFolder &&  docker-compose -f compose4GuiApp.yml up"
