#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_setupClustersh
#
# DESCRIPTION: setup the docker cluster
#
# NOTE: the node where this script is executed is elected as smarm master
#
# AUTHOR : Valentina Gaggero / Matteo Brunettini
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

get_files_list()
{
  filename=$1
  for volume in "${VOLUMES_LIST[@]}"
  do
    cd $volume
    find >> $filename
    cat $filename
  done
}

main()
{
  get_files_list $1
}

main
exit 0
