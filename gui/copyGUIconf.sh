#! /bin/bash


source ../scripts/appsAway_setEnvironment.local.sh


# copy application images and configuration files (e.g. buttons) to the GUI folder
cp ../demos/$APPSAWAY_APP_NAME/gui/gui_conf.ini ./target/appGUI/
cp -R ../demos/$APPSAWAY_APP_NAME/gui/images ./target/appGUI/
if [ -d "../demos/$APPSAWAY_APP_NAME/Archive" ]
then
  cp -R ../demos/$APPSAWAY_APP_NAME/Archive ./target/appGUI/
fi

