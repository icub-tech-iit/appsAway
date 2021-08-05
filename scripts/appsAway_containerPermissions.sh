#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_setupClustersh
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
_APPSAWAY_ENV_FILE="appsAway_setEnvironment.local.sh"
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

warn() 
{
  echo -e "${_YELLOW}$(date +%d-%m-%Y) - $(date +%H:%M:%S) WARNING : $1${_NC}"
}

get_files_list()
{ 
  FILES_TO_CHANGE=$()
  cd /
  for volume in "${_YAML_VOLUMES_LIST[@]}"
  do 
    if [ -d $volume ]
    then
      FILES_IN_VOLUME=$(find $volume)
      IFS=$'\n' 
      FILES_IN_VOLUME=($FILES_IN_VOLUME)
      IFS=$SAVEIFS
      FILES_TO_CHANGE=("${FILES_TO_CHANGE[@]}" "${FILES_IN_VOLUME[@]}")
    fi
  done
  
}

change_permissions()
{
  for file in ${FILES_TO_CHANGE[@]}
  do
    chown ${CURR_UID}:${CURR_GID} $file
  done
}

main()
{
  if [ -z "$_YAML_VOLUMES_LIST" ]
  then
    warn "No Volumes List variable found in environment"
    return
  fi
  if [ -z "$CURR_UID" ] || [ -z "$CURR_GID" ]
  then
    warn "No user ID variable found in environment"
    return
  fi
  _YAML_VOLUMES_LIST=($(echo "${_YAML_VOLUMES_LIST}")) 
  get_files_list
  echo "The following files will have the permissions changed: ${FILES_TO_CHANGE[@]}"
  change_permissions
}

main
exit 0
