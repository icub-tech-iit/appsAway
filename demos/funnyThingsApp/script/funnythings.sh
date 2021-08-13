#!/bin/bash
#######################################################################################
# Copyright: (C) 2021 Istituto Italiano di Tecnologia
# Author:  Vadim Tikhanoff
# email:   vadim.tikhanoff@iit.it
# Permission is granted to copy, distribute, and/or modify this program
# under the terms of the GNU General Public License, version 2 or any
# later version published by the Free Software Foundation.
#  *
# A copy of the license can be found at
# http://www.robotcub.org/icub/license/gpl.txt
#  *
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details
#######################################################################################


#######################################################################################
# HELP
#######################################################################################
usage() {
cat << EOF
***************************************************************************************
DEA SCRIPTING
Author:  Vadim Tikhanoff   <vadim.tikhanoff@iit.it>

This script contains all the available commands for the funnythings app.

USAGE:
        $0 options

***************************************************************************************
OPTIONS:

***************************************************************************************
EXAMPLE USAGE:

***************************************************************************************
EOF
}

#######################################################################################
# HELPER FUNCTIONS
#######################################################################################
write() {
    echo "$1" | yarp write ... /read
}

gaze() {
    echo "$1" | yarp write ... /gaze
}

speak() {
    echo "\"$1\"" | yarp write ... /iSpeak && echo "\"$1\"" | yarp write ... /read
}

wait() {
    wait_till_quiet
}

blink() {
    echo "blink" | yarp rpc /iCubBlinker/rpc
    sleep 0.5
}

go_home_helperL() {
    # This is with the arms over the table
    echo "ctpq time $1 off 0 pos (-12.0 24.0 23.0 64.0 -7.0 -5.0 10.0    12.0 -6.0 37.0 2.0 0.0 3.0 2.0 1.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
}

go_home_helperR() {
    echo "ctpq time $1 off 0 pos (-15.0 23.0 22.0 48.0 13.0 -10.0 8.0    0.0 9.0 42.0 2.0 0.0 1.0 0.0 8.0 4.0)" | yarp rpc /ctpservice/right_arm/rpc
}

go_home_helper() {
    go_home_helperR $1
    go_home_helperL $1
}

go_home() {
    gaze "look-around 0.0 0.0 5.0"
    sleep 1.0
    go_home_helper 2.0
    sleep 3.0
    #breathers "start"
}

greet_with_right_thumb_up() {
    breathers "stop"
    echo "ctpq time 1.5 off 0 pos (-44.0 36.0 54.0 91.0 -45.0 0.0 12.0      21.0 0.0 0.0 0.0 59.0 140.0 80.0 125.0 210.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 1.5 && smile && sleep 1.5
    go_home
    breathers "start"
}

greet_with_left_thumb_up() {
    breathers "stop"
    echo "ctpq time 1.5 off 0 pos (-44.0 36.0 54.0 91.0 -45.0 0.0 12.0      21.0 0.0 0.0 0.0 59.0 140.0 80.0 125.0 210.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 1.5 && smile && sleep 1.5
    go_home
    breathers "start"
}

smile() {
    echo "set all hap" | yarp rpc /icub/face/emotions/in
}

surprised() {
    echo "set mou sur" | yarp rpc /icub/face/emotions/in
    echo "set leb sur" | yarp rpc /icub/face/emotions/in
    echo "set reb sur" | yarp rpc /icub/face/emotions/in
}

sad() {
    echo "set mou sad" | yarp rpc /icub/face/emotions/in
    echo "set leb sad" | yarp rpc /icub/face/emotions/in
    echo "set reb sad" | yarp rpc /icub/face/emotions/in
}

suspicious() {
    echo "set reb cun" | yarp rpc /icub/face/emotions/in
    echo "set leb cun" | yarp rpc /icub/face/emotions/in
}

angry() {
    echo "set all ang" | yarp rpc /icub/face/emotions/in
}

evil() {
    echo "set all evi" | yarp rpc /icub/face/emotions/in
}

wait_till_quiet() {
    sleep 0.3
    isSpeaking=$(echo "stat" | yarp rpc /iSpeak/rpc)
    while [ "$isSpeaking" == "Response: speaking" ]; do
        isSpeaking=$(echo "stat" | yarp rpc /iSpeak/rpc)
        sleep 0.1
        # echo $isSpeaking
    done
    echo "I'm not speaking any more :)"
    echo $isSpeaking
}

victory() {
    echo "ctpq time 1.0 off 7 pos                                       (18.0 40.0 50.0 167.0 0.0 0.0 0.0 0.0 222.0)" | yarp rpc /ctpservice/$1/rpc
    echo "ctpq time 2.0 off 0 pos (-57.0 32.0 -1.0 88.0 56.0 -30.0 -11.0 18.0 40.0 50.0 167.0 0.0 0.0 0.0 0.0 222.0)" | yarp rpc /ctpservice/$1/rpc
}

victory_both() {

    echo "ctpq time 1.0 off 7 pos                                       (18.0 40.0 50.0 167.0 0.0 0.0 0.0 0.0 222.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 2.0 off 0 pos (-57.0 32.0 -1.0 88.0 56.0 -30.0 -11.0 18.0 40.0 50.0 167.0 0.0 0.0 0.0 0.0 222.0)" | yarp rpc /ctpservice/left_arm/rpc

    echo "ctpq time 1.0 off 7 pos                                       (18.0 40.0 50.0 167.0 0.0 0.0 0.0 0.0 222.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 2.0 off 0 pos (-57.0 32.0 -1.0 88.0 56.0 -30.0 -11.0 18.0 40.0 50.0 167.0 0.0 0.0 0.0 0.0 222.0)" | yarp rpc /ctpservice/right_arm/rpc

    sleep 3.0
    go_home
}

point_eye() {
    echo "ctpq time 2 off 0 pos (-50.0 33.0 45.0 95.0 -58.0 24.0 -11.0 10.0 28.0 11.0 78.0 32.0 15.0 60.0 130.0 170.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 3.0 && blink && blink
    go_home
}

point_ear_right() {
    echo "ctpq time 2 off 0 pos (-18.0 59.0 -30.0 105.0 -22.0 28.0 -6.0 6.0 55.0 30.0 33.0 4.0 9.0 58.0 113.0 192.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 3.0
    go_home_helperR 2.0
}

point_ears() {
    breathers "stop"

    echo "ctpq time 1 off 0 pos (-10.0 8.0 -37.0 7.0 -21.0 1.0)" | yarp rpc /ctpservice/head/rpc
    echo "ctpq time 2 off 0 pos (-18.0 59.0 -30.0 105.0 -22.0 28.0 -6.0 6.0 55.0 30.0 33.0 4.0 9.0 58.0 113.0 192.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 2.0

    echo "ctpq time 2 off 0 pos (-10.0 -8.0 37.0 7.0 -21.0 1.0)" | yarp rpc /ctpservice/head/rpc
    echo "ctpq time 2 off 0 pos (-18.0 59.0 -30.0 105.0 -22.0 28.0 -6.0 6.0 55.0 30.0 33.0 4.0 9.0 58.0 113.0 192.0)" | yarp rpc /ctpservice/right_arm/rpc

    echo "ctpq time 2 off 0 pos (-0.0 0.0 -0.0 0.0 -0.0 0.0)" | yarp rpc /ctpservice/head/rpc
    go_home_helperL 2.0
    go_home_helperR 2.0

    breathers "start"
}

point_arms() {
    breathers "stop"

    echo "ctpq time 2 off 0 pos (-60.0 32.0 80.0 85.0 -13.0 -3.0 -8.0 15.0 37.0 47.0 52.0 9.0 1.0 42.0 106.0 250.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 2 off 0 pos (-64.0 43.0 6.0 52.0 -28.0 -0.0 -7.0 15.0 30.0 7.0 0.0 4.0 0.0 2.0 8.0 43.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 3.0
    go_home_helperL 2.0
    go_home_helperR 2.0

    breathers "start"
}

fonzie() {
    echo "ctpq time 2.0 off 0 pos ( -3.0 57.0   3.0 106.0 -9.0 -8.0 -10.0 22.0 0.0 0.0 20.0 62.0 146.0 90.0 130.0 250.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 2.0 off 0 pos ( -3.0 57.0   3.0 106.0 -9.0 -8.0 -10.0 22.0 0.0 0.0 20.0 62.0 146.0 90.0 130.0 250.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 1.0
    smile
    go_home_helper 2.0
}

hello_left() {
    echo "ctpq time 1.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 2.0
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0  25.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0  25.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    smile
    go_home 2.0
    smile
}

hello_left_simple() {
    echo "ctpq time 1.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    smile
    sleep 2.0
    go_home_helperL 2.0
    smile
}

hello_right_simple() {
    echo "ctpq time 1.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    smile
    sleep 2.0
    go_home_helperR 2.0
    smile
}

interaction_right() {
    echo "ctpq time 1.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 55.0 30.0 33.0 4.0 9.0 58.0 113.0 192.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 2.0
    go_home_helperR 2.0
}

hello_right() {
    #breathers "stop"
    echo "ctpq time 1.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 2.0
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0  25.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0  25.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    smile
    go_home
    smile
    #breathers "start"
}

hello_both() {
    #breathers "stop"
    echo "ctpq time 1.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 1.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 2.0

    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0  25.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0  25.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0  25.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0  25.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 0.5 off 0 pos (-60.0 44.0 -2.0 96.0 53.0 -17.0 -11.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)" | yarp rpc /ctpservice/right_arm/rpc

    smile
    go_home_helper 2.0
    smile
    #breathers "start"
}

show_muscles() {
    #breathers "stop"
    echo "ctpq time 1.5 off 0 pos (-27.0 78.0 -37.0 33.0 -79.0 0.0 -4.0 26.0 27.0 0.0 29.0 59.0 117.0 87.0 176.0 250.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 1.5 off 0 pos (-27.0 78.0 -37.0 33.0 -79.0 0.0 -4.0 26.0 27.0 0.0 29.0 59.0 117.0 87.0 176.0 250.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 1.0 off 0 pos (-27.0 78.0 -37.0 93.0 -79.0 0.0 -4.0 26.0 67.0 0.0 99.0 59.0 117.0 87.0 176.0 250.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 1.0 off 0 pos (-27.0 78.0 -37.0 93.0 -79.0 0.0 -4.0 26.0 67.0 0.0 99.0 59.0 117.0 87.0 176.0 250.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 3.0
    smile
    go_home_helper 2.0
    breathers "start"
}

show_muscles_left() {
    echo "ctpq time 1.5 off 0 pos (-27.0 78.0 -37.0 33.0 -79.0 0.0 -4.0 26.0 27.0 0.0 29.0 59.0 117.0 87.0 176.0 250.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 1.0 off 0 pos (-27.0 78.0 -37.0 93.0 -79.0 0.0 -4.0 26.0 67.0 0.0 99.0 59.0 117.0 87.0 176.0 250.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 3.0
    smile
    go_home_helperL 2.0
}

show_iit() {
    breathers "stop"
    echo "ctpq time 1.5 off 0 pos (-27.0 64.0 -30.0 62.0 -58.0 -32.0 4.0 17.0 11.0 21.0 29.0 8.0 9.0 5.0 11.0 1.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 1.5 off 0 pos (-27.0 64.0 -30.0 62.0 -58.0 -32.0 4.0 17.0 11.0 21.0 29.0 8.0 9.0 5.0 11.0 1.0)" | yarp rpc /ctpservice/left_arm/rpc

    sleep 3.0
    smile

    go_home
    breathers "start"
}

show_agitation() {

    echo "ctpq time 1.0 off 0 pos (0.0 0.0 -12.0)" | yarp rpc /ctpservice/torso/rpc

    echo "bind pitch -10.0 0.0" | yarp rpc /iKinGazeCtrl/rpc
    sleep 0.2
    echo "bind roll 0.0 0.0" | yarp rpc /iKinGazeCtrl/rpc
    sleep 0.2
    echo "bind yaw 0.0 0.0" | yarp rpc /iKinGazeCtrl/rpc
    sleep 0.2    
    
    gaze "look -30.0 0.0 5.0"
    sleep 1.5
    gaze "look 30.0 0.0 5.0"
    sleep 1.5
    #gaze "look -30.0 0.0 5.0"
    #sleep 1.5
    #gaze "look 30.0 0.0 5.0"
    #sleep 1.5

    echo "clear pitch" | yarp rpc /iKinGazeCtrl/rpc
    sleep 0.2
    echo "clear roll" | yarp rpc /iKinGazeCtrl/rpc
    sleep 0.2
    echo "clear yaw" | yarp rpc /iKinGazeCtrl/rpc
    sleep 0.2
    
    echo "ctpq time 1.0 off 0 pos (0.0 0.0 0.0)" | yarp rpc /ctpservice/torso/rpc
}

question() {
    echo "ctpq time 1.5 off 0 pos (-39.0 37.0 -17.0 53.0 -47.0 14.0 -2.0 -1.0 8.0 45 3.4 2.4 2.2 0.0 6.8 17)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 1.5 off 0 pos (-39.0 37.0 -17.0 53.0 -47.0 14.0 -2.0 -1.0 8.0 45 3.4 2.4 2.2 0.0 6.8 17)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 3.0
    go_home
}

question_left() {
    echo "ctpq time 1.5 off 0 pos (-39.0 37.0 -17.0 53.0 -47.0 14.0 -2.0 -1.0 8.0 45 3.4 2.4 2.2 0.0 6.8 17)" | yarp rpc /ctpservice/left_arm/rpc
    gaze "look -30.0 0.0 5.0"
    go_home_helperL 1.5
}

question_right() {
    echo "ctpq time 1.5 off 0 pos (-39.0 37.0 -17.0 53.0 -47.0 14.0 -2.0 -1.0 8.0 45 3.4 2.4 2.2 0.0 6.8 17)" | yarp rpc /ctpservice/right_arm/rpc
    gaze "look 30.0 0.0 5.0"
    go_home_helperR 1.5
}

talk_mic() {
    #breathers "stop"
    sleep 1.0
    echo "ctpq time $1 off 0 pos (-47.582418 37.967033 62.062198 107.868132 -32.921661 -12.791209 -0.571429 0.696953 44.352648 14.550271 86.091537 52.4 64.79118 65.749353 62.754529 130.184865)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 1.0
    #breathers "start"
}

#######################################################################################
# SEQUENCE FUNCTIONS
#######################################################################################
sequence_01() {
    gaze "look 0.0 0.0 5.0"
    sleep 1.0
    speak "Stasera infatti ci sono anch'io!!"
    hello_right
    sleep 2.0 && blink
    wait_till_quiet
    smile && blink
    gaze "look-around 0.0 0.0 5.0"
}

sequence_02() {
    speak "Ho solo 10 anni, e per me e' tardi, dovrei andare a dormire, tra poco. ma stasera staro' sveglio. Questa occasione non posso perderla!"
    sleep 1.0
    greet_with_right_thumb_up    
    wait_till_quiet
    smile && blink
}

sequence_03_() {
    surprised
    show_agitation
    gaze "look-around 0.0 0.0 5.0"
    smile
    sleep 1.0
    sequence_04
}

sequence_04() {    
    speak "Si, sono creature bellissime, e ci sono tanti cuccioli come me! Ma, morderanno??"
    sleep 1.5
    #greet_with_right_thumb_up
}

sequence_05() {  
    surprised  
    sleep 1.0
    speak "Questi sono davvero tanti!...Vai avanti tu, ACP, che devi presentarli. io ti seguo...da qua."
    smile
}

sequence_06() {   
    victory right_arm 
    speak "Sono decisamente piu' carino, e molto piu' giovane!."
    go_home
}

sequence_07() {   
    speak "Belli i felini! Saranno bravi genitori? Guardiamo, io vi aspetto dopo."
    sleep 1.0
    question
}

sequence_08() {
    speak "L'intelligenza artificiale viene studiata proprio per aiutare l'uomo."
    point_ear_right
    smile && blink
}

sequence_09() {
    speak "Era ora!!"
    greet_with_right_thumb_up
    smile && blink
}

sequence_10() {
    speak "Oltre 30, nati dopo di me, e sparsi per il mondo, dagli stati uniti al giappone."
    sleep 3.5    
    question_right
    sleep 1.5
    question_left
    sleep 1.0
    gaze "look-around 0.0 0.0 5.0"
    smile && blink
}

sequence_11() {
    speak "Ho tante mamme e papa'; all'Istituto Italiano di Tecnologia di Genova. Oggi mi ha accompagnato qui Vadiim "
    sleep 2.0    
    hello_left_simple
    go_home_helper 2.0
}

sequence_12() {
    speak "Ma certo, sono un intelligenza artificiale!!"
    victory_both
    wait_till_quiet
}

# Red ball DEMO.
# IOL DEMO.

#yarp rpc /iolStateMachineHandler/human:rpc
#where Octopus
#ack
#hold Octopus
#drop

sequence_13() {
    # Back from IOL to here
    #gaze "look-around 0.0 0.0 5.0"
    speak "Sono contento di esserti di aiuto!"
    #go_home
}

sequence_14() { 
    speak "Io restero' con i ricercatori, e continuero' a imparare e crescere. sara' R1 ad entrare nelle vostre case per aiutarvi"
}

# Skin DEMO.

sequence_15() { 
    speak "16961, ti dice niente questo numero?"
    interaction_right
}

sequence_16() { 
    speak "Grazie Alessandro, e' ora che io vada a dormire. Mi e' piaciuta la TV."
    echo "ctpq time 1.0 off 0 pos (-12.0 37.0 6.0 67.0 -52.0 -14.0 9.0    12.0 -6.0 37.0 2.0 0.0 3.0 2.0 1.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 2.0
    echo "ctpq time 1.0 off 0 pos (-13.0 29.0 18.0 59.0 -59.0 -12.0 -6.0    0.0 9.0 42.0 2.0 0.0 1.0 0.0 8.0 4.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 2.0
    go_home
}

sequence_17() {
    speak "Ciao sono aicab, e vi aspetto Mercoledi' a La Settima Porta su Rete 4!"
    hello_both
}

sequence_14_() {
    gaze "look-around 15.0 0.0 5.0"
    speak "Sono fatto di cinquemilla pezzi, posso riconoscere gli oggetti intorno a me, ed afferrarli. e posso usarli per svolgere alcuni semplici compiti."
    sleep 1.5
    echo "ctpq time 1.0 off 0 pos (-12.0 37.0 6.0 67.0 -52.0 -14.0 9.0    12.0 -6.0 37.0 2.0 0.0 3.0 2.0 1.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    echo "ctpq time 1.0 off 0 pos (-13.0 29.0 18.0 59.0 -59.0 -12.0 -6.0    0.0 9.0 42.0 2.0 0.0 1.0 0.0 8.0 4.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 2.0
    go_home_helper 1.2
    wait_till_quiet

    speak "Da poco, ho imparato a stare in equilibrio senza cadere, e presto imparero' a camminare, proprio come voi."
    sleep 1.0
    echo "ctpq time 1.0 off 0 pos (-15.0 36.0 8.0 77.0 45.0 3.0 3.0    0.0 9.0 42.0 2.0 0.0 1.0 0.0 8.0 4.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 1.0 off 0 pos (-6.0 30.0 13.0 67.0 49.0 -13.0 5.0    12.0 -6.0 37.0 2.0 0.0 3.0 2.0 1.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 0.5

    echo "ctpq time 0.7 off 0 pos (-15.0 32.0 11.0 61.0 51.0 -2.0 -2.0    0.0 9.0 42.0 2.0 0.0 1.0 0.0 8.0 4.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 0.7 off 0 pos (-3.0 50.0 15.0 97.0 33.0 -2.0 21.0    12.0 -6.0 37.0 2.0 0.0 3.0 2.0 1.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 0.3

    echo "ctpq time 0.7 off 0 pos (-15.0 36.0 8.0 77.0 45.0 3.0 3.0    0.0 9.0 42.0 2.0 0.0 1.0 0.0 8.0 4.0)" | yarp rpc /ctpservice/right_arm/rpc
    echo "ctpq time 0.7 off 0 pos (-6.0 30.0 13.0 67.0 49.0 -13.0 5.0    12.0 -6.0 37.0 2.0 0.0 3.0 2.0 1.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 2.0
    go_home_helper 2.0

    wait_till_quiet
    speak "E poi sono l'unico robot al mondo dotato di una pelle sensibile, che mi permette di sentire quando vengo toccato, spinto, o se mi fanno il solletico."
    sleep 3.5
    gaze "look -20.0 -30.0 0.0"
    echo "ctpq time 1.3 off 0 pos (-46.0 48.0 74.0 106.0 13.0 0.0 9.0    0.0 12.0 34.0 1.0 0.0 1.0 50.0 82.0 116.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 0.7
    echo "ctpq time 1.0 off 0 pos (-22.0 34.0 48.0 73.0 37.0 3.0 -7.0    12.0 -6.0 37.0 2.0 0.0 3.0 2.0 1.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 3.0
    gaze "look-around 0.0 0.0 5.0"

    go_home_helper 2.0

    wait_till_quiet
}

sequence_16_() {
    gaze "look-around 15.0 0.0 5.0"
    speak "In futuro potro' aiutarvi nei lavori domestici, o in altre attivita' delicate per cui avrete bisogno di supporto."
    echo "ctpq time 1.0 off 0 pos (-12.0 37.0 6.0 67.0 -52.0 -14.0 9.0    12.0 -6.0 37.0 2.0 0.0 3.0 2.0 1.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 2.0
    go_home_helperL 2.0
    wait_till_quiet
    speak "Come per esempio, l'assistenza degli anziani, o a persone disabili."
    echo "ctpq time 1.0 off 0 pos (-13.0 29.0 18.0 59.0 -59.0 -12.0 -6.0    0.0 9.0 42.0 2.0 0.0 1.0 0.0 8.0 4.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 2.0
    go_home_helperR 2.0
    wait_till_quiet
}

sequence_17_() {
    gaze "look-around 15.0 0.0 5.0"
    speak "In questo momento, costo 250 mila euro, ma il mio progetto e' disponibile per tutti."
    wait_till_quiet
    speak "Su internet si trovano i disegni per costruire il mio corpo, e il softuer per la base della mia intelligenza."
    sleep 1
    fonzie
    gaze "idle"
    echo "ctpq time 1.5 off 0 pos (-15.0 81.0 -29.0 104.0 -56.0 25.0 -1.0 0.0 9.0 30.0 57.0 0.0 0.0 90.0 130.0 250.0)" | yarp rpc /ctpservice/right_arm/rpc
    sleep 2.0
    gaze "look-around 15.0 0.0 5.0"
    go_home_helperR 2.0
    wait_till_quiet
    speak "Anche se non e' facile costruirmi in casa."
    wait_till_quiet
    blink
    sleep 0.8
    smile
    speak "In futuro costero' meno, come una piccola automobile, e potro' davvero aiutare le persone a casa e sul lavoro."
    echo "ctpq time 1.0 off 0 pos (-12.0 37.0 6.0 67.0 -52.0 -14.0 9.0    12.0 -6.0 37.0 2.0 0.0 3.0 2.0 1.0 0.0)" | yarp rpc /ctpservice/left_arm/rpc
    sleep 2.0
    go_home_helperL 2.0
    wait_till_quiet
    speak "So gia' fare tantissime cose, persino tai-ci, Ora vi faccio vedere!"
    wait_till_quiet
}

are_home() {
    echo "home all" | yarp rpc /actionsRenderingEngine/cmd:io
}

are_point() {
    speak "Penso che sia questo il piccolo polpo"
    echo "point (-0.3 -0.2 -0.03) left" | yarp rpc /actionsRenderingEngine/cmd:io
}

are_take() {
    speak "Ok, ora lo prendo!"
    echo "take (-0.3 -0.17 -0.05) left" | yarp rpc /actionsRenderingEngine/cmd:io
    speak "Ecco il piccolo polpo, Vadiim"
    echo "drop away" | yarp rpc /actionsRenderingEngine/cmd:io
}

#######################################################################################
# "MAIN" FUNCTION:                                                                    #
#######################################################################################
echo "********************************************************************************"
echo ""

$1 "$2"

if [[ $# -eq 0 ]] ; then
    echo "No options were passed!"
    echo ""
    usage
    exit 1
fi
