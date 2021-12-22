#! /bin/bash

# This script runs the installation process for the appGUI.

source ../scripts/appsAway_setEnvironment.local.sh


# first we check which python is being used in the machine and store that path
PYTHON_VERSION=$(python3 -V) # python 3.6.2
MAJOR_MINOR=${PYTHON_VERSION:7:3}
ORIGIN_PYTHON_PATH=$(which python$MAJOR_MINOR)    # /usr/bin/python3.6

password=$1

echo -ne "[              ] installing GUI...\r"

# now we update which python to use for installing the gui
os=`uname -s`
if [ "$os" = "Darwin" ]
then
  echo ${password} | HOMEBREW_NO_AUTO_UPDATE=1 brew install pyenv pulseaudio sox > /dev/null 
  echo ${password} | env PYTHON_CONFIGURE_OPTS="--enable-framework" pyenv install -f 3.6.1 > /dev/null 
  PYTHON_VERSION=$( pyenv global )
  echo ${password} | pyenv global 3.6.1 > /dev/null 
else
  echo ${password} | sudo -S add-apt-repository ppa:deadsnakes/ppa > /dev/null 2>&1
  echo -ne "[.             ] installing GUI...\r"
  echo ${password} | sudo -S apt-get -y update > /dev/null 2>&1
  echo -ne "[..            ] installing GUI...\r"
  echo ${password} | sudo -S apt-get -y install python3.6 python3.6-dev python3.6-venv > /dev/null 2>&1
  echo -ne "[...           ] installing GUI...\r"
  echo ${password} | sudo -S update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1 > /dev/null 2>&1
  echo -ne "[....          ] installing GUI...\r"
  echo ${password} | sudo -S update-alternatives --set python3 /usr/bin/python3.6 > /dev/null 2>&1
  echo -ne "[.....         ] installing GUI...\r"
  echo ${password} | sudo -S apt -y install python3-pip pulseaudio sox libsox-fmt-mp3 > /dev/null 2>&1
  echo -ne "[......        ] installing GUI...\r"
fi


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
    python3.6 -m venv venv > /dev/null 2>&1
fi
echo -ne "[.......       ] installing GUI...\r"

# initialize our python virtual environment
source venv/bin/activate
echo -ne "[........      ] installing GUI...\r"

# install python dependencies (QT for graphical interface, watchdog for file monitors, fbs to install the GUI)

#pip3 install pyqt5 
#pip install -q fbs  watchdog
pip install fbs pygame PyQt5==5.9.2 watchdog > /dev/null 2>&1
echo -ne "[.........     ] installing GUI...\r"

# start the project. We pipe the name of the app, "appGUI" into the command to avoid user prompts. The output is quite verbose so we make it run silent.
(echo appGUI ; echo '' ; echo '') | fbs startproject > /dev/null 2>&1 #> /dev/null > /dev/null 
echo -ne "[..........    ] installing GUI...\r"

# copy the actual code in main.py into the project
cp main.py ./src/main/python/main.py
echo -ne "[...........   ] installing GUI...\r"

# compile our GUI. The output is quite verbose so we make it run silent.
fbs freeze > /dev/null 2>&1 #> /dev/null
echo -ne "[............  ] installing GUI...\r"


if [ "$os" = "Darwin" ]
then
  echo ${password} | pyenv global $PYTHON_VERSION > /dev/null 2>&1
else
  echo ${password} | sudo -S update-alternatives --remove python3 /usr/bin/python3.6 > /dev/null 2>&1
  echo -ne "[.............  ] installing GUI...\r"
  echo ${password} | sudo -S update-alternatives --install /usr/bin/python3 python3 $ORIGIN_PYTHON_PATH 2 > /dev/null 2>&1
  echo -ne "[.............. ] installing GUI...\r"
  echo ${password} | sudo -S update-alternatives --set python3 $ORIGIN_PYTHON_PATH > /dev/null 2>&1
  echo "[...............] installing GUI......Done!"
fi



