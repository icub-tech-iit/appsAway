#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_getVolumesFileList.sh
#
# DESCRIPTION: setup the docker cluster
#
# NOTE: the node where this script is executed is elected as smarm master
#
# AUTHOR : Valentina Gaggero / Matteo Brunettini / me
#
# LATEST MODIFICATION DATE (YYYY-MM-DD) : 2019-12-06
#
_SCRIPT_VERSION="1.0"          # Sets version variable
#
_SCRIPT_TEMPLATE_VERSION="1.1.0" #
#
# ##############################################################################
# Defaults
# local variable name starts with "_"
_YARP_CONFIG_FILES_PATH="config_yarp"
_YARP_NAMESPACE="/root"
_DOCKER_ENV_FILE=".env"
_NC='\033[0m' # No Color
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_BLUE='\033[0;34m'
_YELLOW='\033[1;33m'
_PURPLE='\033[1;35m'
_LGRAY='\033[0;37m'
# ##############################################################################
_SSH_BIN=$(which ssh || true)
_SSH_PARAMS="-T"
_SCP_BIN=$(which scp || true)
_SCP_PARAMS="-q -B"
_SCP_PARAMS_DIR="-q -B -r"
_DOCKER_BIN=$(which docker || true)
_DOCKER_PARAMS=""
_HOSTNAME_LIST=""
_CWD=$(pwd)
_FILE_LIST_BEFORE_DEPLOYMENT=""

get_volumes_file_list()
{
  for volume in "${_YAML_VOLUMES_HOST[@]}"
  do   
    if [ -d "${volume}" ]
    then
      cd $volume
      FILES_IN_VOLUME=$(find | tr '\n' '*' | sed 's/.\///g') # * works as a separator for each filename (newlines and spaces are not valid when exporting)
      if [[ $FILES_IN_VOLUME != ".*" ]]
      then
        FILES_IN_VOLUME=${FILES_IN_VOLUME:2:-1} # Remove extra characters coming from find command
        _FILE_LIST_BEFORE_DEPLOYMENT="$_FILE_LIST_BEFORE_DEPLOYMENT ${FILES_IN_VOLUME}" 
      fi   
    fi
  done
  _FILE_LIST_BEFORE_DEPLOYMENT=${_FILE_LIST_BEFORE_DEPLOYMENT:1}
}

save_list_to_env_file()
{
  echo "_FILE_LIST_BEFORE_DEPLOYMENT=\"${_FILE_LIST_BEFORE_DEPLOYMENT}\"" >> ${HOME}/${APPSAWAY_APP_PATH_NOT_CONSOLE}/${_DOCKER_ENV_FILE}
}

main()
{
  _YAML_VOLUMES_HOST=($(echo "${_YAML_VOLUMES_HOST}"))  
  get_volumes_file_list
  save_list_to_env_file
}

main
