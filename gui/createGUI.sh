#! /bin/bash

# This script runs the installation process for the appGUI.

source ../scripts/appsAway_setEnvironment.local.sh

# checks if there is a previous installation - if yes, it deletes it
if [ -d "src" ]
then
    rm -rf src
fi

# checks if there is a previous installation - if yes, it deletes it
if [ -d "target" ]
then
    rm -rf target
fi

# if we already have venv, we don't need to rerun it
if [ ! -d "venv" ]
then
    python3.6 -m venv venv
fi

# initialize our python virtual environment
source venv/bin/activate

# install python dependencies (QT for graphical interface, watchdog for file monitors, fbs to install the GUI)

#pip3 install pyqt5 
#pip install -q fbs  watchdog
pip install fbs PyQt5==5.9.2 watchdog

# start the project. We pipe the name of the app, "appGUI" into the command to avoid user prompts. The output is quite verbose so we make it run silent.
(echo appGUI ; echo '' ; echo '') | fbs startproject #> /dev/null

# copy the actual code in main.py into the project
cp main.py ./src/main/python/main.py

# compile our GUI. The output is quite verbose so we make it run silent.
fbs freeze #> /dev/null
