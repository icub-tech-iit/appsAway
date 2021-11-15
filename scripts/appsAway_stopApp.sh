#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_stopApp.sh
#
# DESCRIPTION: start the application by ssh
#
# NOTE: this script must be executed on master node
#
# AUTHOR : Valentina Gaggero / Matteo Brunettini
#
# LATEST MODIFICATION DATE (YYYY-MM-DD) : 2019-12-11
#
_SCRIPT_VERSION="1.0"          # Sets version variable
#
_SCRIPT_TEMPLATE_VERSION="1.1.0" #
#
# ##############################################################################
# Defaults
# local variable name starts with "_"
_APPSAWAY_ENV_FILE="appsAway_setEnvironment.local.sh"
_SCRIPT2RUN_FILE_NAME="worker.sh.APPSAWAY"
_EXIT_FILE_NAME="worker.exit.APPSAWAY"
_RUNNER_SCRIPT_FILE_NAME="appsAway_scriptRunner.sh"
_NC='\033[0m' # No Color
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_BLUE='\033[0;34m'
_YELLOW='\033[1;33m'
_PURPLE='\033[1;35m'
_LGRAY='\033[0;37m'
# ##############################################################################
_SCP_BIN=$(which scp || true)
_SCP_PARAMS="-q -B"
_SSH_BIN=$(which ssh || true)
_SSH_PARAMS="-T"
_DOCKER_BIN=$(which docker || true)
_DOCKER_COMPOSE_BIN_CONSOLE=$(which docker-compose || true)
_DOCKER_ENV_FILE=".env"
_YAML_VOLUMES_HOST=""
_YAML_VOLUMES_CONTAINER=""
if [ "$os" = "Darwin" ]
then
  _OS_HOME_DIR=/Users
else
  _OS_HOME_DIR=/home
fi

_DOCKER_PARAMS=""
_SSH_CMD_PREFIX=""

print_defs ()
{
  echo "Default parameters are"
  echo " _SCRIPT_TEMPLATE_VERSION is $_SCRIPT_TEMPLATE_VERSION"
  echo " _SCRIPT_VERSION is $_SCRIPT_VERSION"
  echo " _APPSAWAY_ENV_FILE is $_APPSAWAY_ENV_FILE"
  echo " _SCP_BIN is $_SCP_BIN"
  echo " _SCP_PARAMS is $_SCP_PARAMS"
  echo " _SSH_BIN is $_SSH_BIN"
  echo " _SSH_PARAMS is $_SSH_PARAMS"
  echo " _DOCKER_BIN is $_DOCKER_BIN"
  echo "_DOCKER_COMPOSE_BIN_CONSOLE is $_DOCKER_COMPOSE_BIN_CONSOLE"
  echo "_DOCKER_COMPOSE_BIN_HEAD is $_DOCKER_COMPOSE_BIN_HEAD"
  echo "_DOCKER_COMPOSE_BIN_GUI is $_DOCKER_COMPOSE_BIN_GUI"
  echo " _DOCKER_PARAMS is $_DOCKER_PARAMS"
}

get_shared_volumes()
{
  file=$1
  look_for_volumes=false
  while read -r line || [ -n "$line" ]
  do
      volumes_result=$( echo "$line" | grep "volumes" || true) # Look for yml line that says "volumes"
      if [[ $look_for_volumes == true ]]
      then
          if [[ $line == -* || $line == \#* ]] # If line is a volume or comment
          then
              if [[ $line == -* ]] # If line is a volume (ignore comments)
              then
                if [[ $line == *:rw || $line == *:rw\" ]] # If volume includes the rw flag
                then
                  volume_machine_side=$(echo $line | awk -F':' '{print $1}' | tr -d '"' | tr -d ' ' ) # Get volume 
                  volume_container_side=$(echo $line | sed 's/[^:]*://' | tr -d '"' | tr -d ' ' | sed 's/:.*//' )
                  _YAML_VOLUMES_HOST="$_YAML_VOLUMES_HOST ${volume_machine_side:1}"
                  _YAML_VOLUMES_CONTAINER="$_YAML_VOLUMES_CONTAINER ${volume_container_side:1}"
                fi
              fi
          else # If line is not volume nor comment, it's a continuation of the yml and we are done
              look_for_volumes=false
          fi
      fi

      if [[ "$volumes_result" != "" &&  "$line" != \#* ]] # If line says "volumes" and it's not a comment, we can look for volumes
      then                   
          look_for_volumes=true             
      fi
  done < $file
}

usage ()
{
  echo "SCRIPT DESCRIPTION"

  echo "Usage: $0 [options]"
  echo "options are :"

  echo "  -d : print defaults"
  echo "  -v : print version"
  echo "  -h : print this help"
}

log() {
  echo -e "${_BLUE}$(date +%d-%m-%Y) - $(date +%H:%M:%S) : $1${_NC}"
}

warn() {
  echo -e "${_YELLOW}$(date +%d-%m-%Y) - $(date +%H:%M:%S) WARNING : $1${_NC}"
}

error() {
  echo -e "${_RED}$(date +%d-%m-%Y) - $(date +%H:%M:%S) ERROR : $1${_NC}"
}

exit_err () {
  error "$1"
  exit 1
}

print_version() {
  echo "Script version is $_SCRIPT_VERSION based of Template version $_SCRIPT_TEMPLATE_VERSION"
}

parse_opt() {
  while getopts hdv opt
  do
    case "$opt" in
    h)
      usage
      exit 0
      ;;
    d)
      print_defs
      exit 0
      ;;
    v)
      print_version
      exit 0
      ;;
    \?) # unknown flag
      usage
      exit 1
      ;;
    esac
  done
}

init()
{
 log "$0 STARTED"
 _SCP_BIN=$(which scp)
 if [ "${_SCP_BIN}" == "" ]; then
   exit_err "scp binary not found"
 fi
 _SSH_BIN=$(which ssh)
 if [ "${_SSH_BIN}" == "" ]; then
   exit_err "ssh binary not found"
 fi
 _DOCKER_BIN=$(which docker)
 if [ "${_DOCKER_BIN}" == "" ]; then
   exit_err "docker binary not found"
 fi
 if [ ! -f "${_APPSAWAY_ENV_FILE}" ]; then
   exit_err "enviroment file ${_APPSAWAY_ENV_FILE} does not exist"
 fi
 source ${_APPSAWAY_ENV_FILE}
 source ${HOME}/${APPSAWAY_APP_PATH_NOT_CONSOLE}/${_DOCKER_ENV_FILE}

 if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
  _DOCKER_COMPOSE_BIN_HEAD=$(ssh $APPSAWAY_ICUBHEADNODE_USERNAME@$APPSAWAY_ICUBHEADNODE_ADDR 'which docker-compose;')
  echo "Docker compose head path: $_DOCKER_COMPOSE_BIN_HEAD"
  if [ "${_DOCKER_COMPOSE_BIN_HEAD}" == "" ]; then
   exit_err "docker-compose binary not found in the head node"
  fi
 fi
 if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
  _DOCKER_COMPOSE_BIN_GUI=$(ssh $APPSAWAY_GUINODE_USERNAME@$APPSAWAY_GUINODE_ADDR 'which docker-compose;')
  echo "Docker compose gui path: $_DOCKER_COMPOSE_BIN_GUI" 
  if [ "${_DOCKER_COMPOSE_BIN_GUI}" == "" ]; then
   exit_err "docker-compose binary not found in the gui node" 
  fi
 fi

 for _deploy_file in ${APPSAWAY_DEPLOY_YAML_FILE_LIST}
 do
    if [ ! -f "../demos/${APPSAWAY_APP_NAME}/${_deploy_file}" ]; then
      exit_err "deployments file ${_deploy_file} does not exist"
    else echo "found ../demos/${APPSAWAY_APP_NAME}/${_deploy_file}"
    fi
 done
 _SSH_CMD_PREFIX="cd ${APPSAWAY_APP_PATH} "
}

fini()
{
  log "$0 ENDED "
}

run_via_ssh()
{
  _SSH_CMD_PREFIX_FOR_USER="cd ${_OS_HOME_DIR}/$1/${APPSAWAY_APP_PATH_NOT_CONSOLE}"
  if [ "$4" != "" ]; then
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 "$_SSH_CMD_PREFIX_FOR_USER ; $3 > $4 2>&1"
  else
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 "$_SSH_CMD_PREFIX_FOR_USER ; $3"
  fi
}


run_via_ssh_nowait()
{
  if [ "$4" != "" ]; then
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 "$_SSH_CMD_PREFIX ; nohup $3 > $4 2>&1 &"
  else
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 "$_SSH_CMD_PREFIX ; nohup $3 >/dev/null 2>&1 &"
  fi
}

getdisplay()
{  ps -u $(id -u) -o pid= | \
    while read pid; do
        cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep '^DISPLAY=:'
    done | grep -o ':[0-9]*' | sort -u
}

stop_hardware_steps_via_ssh()
{
  #read -n 1 -s -r -p "Press any key to stop the App"
  log "Stopping hardware steps via ssh"
  mydisplay=$(getdisplay)

  myXauth=""
  os=`uname -s`
  if [ "$os" = "Darwin" ]
  then
     myXauth=${XAUTHORITY}
  else
    myXauth="/run/user/$UID/gdm/Xauthority"
  fi

  stop_cmd=""
  if [ "$APPSAWAY_REPO_TAG" == "sources" ]
  then
     stop_cmd="stop"
  else
    stop_cmd="down"
  fi
  
  for file in ${APPSAWAY_DEPLOY_YAML_FILE_LIST}
  do
    get_shared_volumes ${APPSAWAY_APP_PATH}/${file}
  done
  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
  for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      get_shared_volumes ${APPSAWAY_APP_PATH}/${file}
    done
  fi
  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      get_shared_volumes ${APPSAWAY_APP_PATH}/${file}
    done
  elif [ "$APPSAWAY_GUINODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      get_shared_volumes ${APPSAWAY_APP_PATH}/${file}
    done
  fi

  _YAML_VOLUMES_HOST=$(eval echo -e \"$_YAML_VOLUMES_HOST\")
  
  for file in ${APPSAWAY_DEPLOY_YAML_FILE_LIST}
  do
    log "stopping docker-compose with file ${file} on host $APPSAWAY_CONSOLENODE_ADDR with command ${stop_cmd}"
    run_via_ssh $APPSAWAY_CONSOLENODE_USERNAME $APPSAWAY_CONSOLENODE_ADDR "export APPSAWAY_STACK_NAME=${APPSAWAY_STACK_NAME}; export _YAML_VOLUMES_HOST=\"${_YAML_VOLUMES_HOST}\" ; export _YAML_VOLUMES_CONTAINER=\"${_YAML_VOLUMES_CONTAINER}\" ; export APPSAWAY_APP_PATH_NOT_CONSOLE=${APPSAWAY_APP_PATH_NOT_CONSOLE} ; export APPSAWAY_APP_PATH=${_OS_HOME_DIR}/${APPSAWAY_CONSOLENODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE} ; ${_OS_HOME_DIR}/${APPSAWAY_CONSOLENODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE}/appsAway_changeNewFilesPermissions.sh ; if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN_CONSOLE} -f ${file} ${stop_cmd}; fi"
  done
  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${file} on host $APPSAWAY_ICUBHEADNODE_ADDR with command ${stop_cmd}"
      run_via_ssh $APPSAWAY_ICUBHEADNODE_USERNAME $APPSAWAY_ICUBHEADNODE_ADDR "export APPSAWAY_STACK_NAME=${APPSAWAY_STACK_NAME}; export _YAML_VOLUMES_HOST=\"${_YAML_VOLUMES_HOST}\" ; export _YAML_VOLUMES_CONTAINER=\"${_YAML_VOLUMES_CONTAINER}\" ; export APPSAWAY_APP_PATH_NOT_CONSOLE=${APPSAWAY_APP_PATH_NOT_CONSOLE} ; export APPSAWAY_APP_PATH=${_OS_HOME_DIR}/${APPSAWAY_ICUBHEADNODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE} ; ${_OS_HOME_DIR}/${APPSAWAY_ICUBHEADNODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE}/appsAway_changeNewFilesPermissions.sh ; if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN_HEAD} -f ${file} ${stop_cmd}; fi"
    done
  fi
  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${file} on host $APPSAWAY_GUINODE_ADDR with command ${stop_cmd}"
      run_via_ssh $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR "export APPSAWAY_STACK_NAME=${APPSAWAY_STACK_NAME}; export _YAML_VOLUMES_HOST=\"${_YAML_VOLUMES_HOST}\" ; export _YAML_VOLUMES_CONTAINER=\"${_YAML_VOLUMES_CONTAINER}\" ; export APPSAWAY_APP_PATH_NOT_CONSOLE=${APPSAWAY_APP_PATH_NOT_CONSOLE} ; export APPSAWAY_APP_PATH=${_OS_HOME_DIR}/${APPSAWAY_GUINODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE} ; ${_OS_HOME_DIR}/${APPSAWAY_GUINODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE}/appsAway_changeNewFilesPermissions.sh ; export DISPLAY=${mydisplay} ; export XAUTHORITY=${myXauth}; if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN_GUI} -f ${file} ${stop_cmd}; fi"
    done
  elif [ "$APPSAWAY_GUINODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${file} on host $APPSAWAY_CONSOLENODE_ADDR with command ${stop_cmd}"
      run_via_ssh $APPSAWAY_CONSOLENODE_USERNAME $APPSAWAY_CONSOLENODE_ADDR "export APPSAWAY_STACK_NAME=${APPSAWAY_STACK_NAME}; export _YAML_VOLUMES_HOST=\"${_YAML_VOLUMES_HOST}\" ; export _YAML_VOLUMES_CONTAINER=\"${_YAML_VOLUMES_CONTAINER}\" ; export APPSAWAY_APP_PATH_NOT_CONSOLE=${APPSAWAY_APP_PATH_NOT_CONSOLE} ; export APPSAWAY_APP_PATH=${_OS_HOME_DIR}/${APPSAWAY_CONSOLENODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE} ; ${_OS_HOME_DIR}/${APPSAWAY_CONSOLENODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE}/appsAway_changeNewFilesPermissions.sh ; export DISPLAY=${mydisplay} ; export XAUTHORITY=${myXauth}; if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN_CONSOLE} -f ${file} ${stop_cmd}; fi"
    done
  fi
}

stop_deploy()
{

  log "executing docker stack deploy"
  export $(cat .env)
  #cd $APPSAWAY_APP_PATH
  #for _file2deploy in ${APPSAWAY_DEPLOY_YAML_FILE_LIST}
  #do
    ${_DOCKER_BIN} ${_DOCKER_PARAMS} stack rm ${APPSAWAY_STACK_NAME}
  #done
}


main()
{
  stop_hardware_steps_via_ssh
  stop_deploy
}

parse_opt "$@"
init
main
fini
exit 0
