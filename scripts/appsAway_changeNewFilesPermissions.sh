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

get_container_id_list()
{
  CONTAINER_LS_OUTPUT=$(docker ps --format "table {{.ID}}")

  IFS=$'\n' 
  CONTAINER_ID_LIST_all=($CONTAINER_LS_OUTPUT)
  CONTAINER_TO_EXCLUDE=($(docker ps --filter "name=${APPSAWAY_STACK_NAME}_visualizer" --format "table {{.ID}}"))
  IFS=$SAVEIFS
  CONTAINER_ID_LIST=("${CONTAINER_ID_LIST_all[@]:1}")
  CONTAINER_TO_EXCLUDE=${CONTAINER_TO_EXCLUDE[1]} 
}

copy_script_into_containers()
{
    source_path=$1
    for container in ${CONTAINER_ID_LIST[@]}
    do
        if [[ ${container} != ${CONTAINER_TO_EXCLUDE} ]]
        then
          container_work_dir=$(docker exec $container pwd)
          if [[ $container_work_dir != "/" ]]
          then
              container_file=\/$2
          else
              container_file=$2
          fi
          path_to_paste=${container_work_dir}${container_file}
          docker cp ${source_path} $container:${path_to_paste}
        fi
    done
}

execute_script_inside_containers()
{
    CURR_UID=$(id -u)
    CURR_GID=$(id -g)
    for container in ${CONTAINER_ID_LIST[@]}
    do  
        if [[ ${container} != ${CONTAINER_TO_EXCLUDE} ]]
        then
          docker exec -e _YAML_VOLUMES_LIST=${_YAML_VOLUMES_LIST} -e CURR_UID=${CURR_UID} -e CURR_GID=${CURR_GID} $container ./$1
        fi
    done
}

main()
{
  permission_file_path="permissions.sh"
  if [ -z "$_YAML_VOLUMES_LIST" ]
  then
    warn "No Volumes List variable found in environment"
    return
  fi
  if [ "$APPSAWAY_APP_PATH" == "" ]
  then
    warn "No app path variable found in environment"
    return
  fi
  if [ "$APPSAWAY_STACK_NAME" == "" ]
  then
    warn "No stack name variable found in environment"
    return
  fi
  get_container_id_list
  copy_script_into_containers $APPSAWAY_APP_PATH/appsAway_containerPermissions.sh $permission_file_path
  execute_script_inside_containers $permission_file_path
}

main $1
exit 0