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
_APPSAWAY_ENVFILE="appsAway_setEnvironment.local.sh"
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
_DOCKER_COMPOSE_BIN=$(which docker-compose || true)
_DOCKER_PARAMS=""
_SSH_CMD_PREFIX=""

print_defs ()
{
  echo "Default parameters are"
  echo " _SCRIPT_TEMPLATE_VERSION is $_SCRIPT_TEMPLATE_VERSION"
  echo " _SCRIPT_VERSION is $_SCRIPT_VERSION"
  echo " _APPSAWAY_ENVFILE is $_APPSAWAY_ENVFILE"
  echo " _SCP_BIN is $_SCP_BIN"
  echo " _SCP_PARAMS is $_SCP_PARAMS"
  echo " _SSH_BIN is $_SSH_BIN"
  echo " _SSH_PARAMS is $_SSH_PARAMS"
  echo " _DOCKER_BIN is $_DOCKER_BIN"
  echo "_DOCKER_COMPOSE_BIN is $_DOCKER_COMPOSE_BIN"
  echo " _DOCKER_PARAMS is $_DOCKER_PARAMS"
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
 if [ ! -f "${_APPSAWAY_ENVFILE}" ]; then
   exit_err "enviroment file ${_APPSAWAY_ENVFILE} does not exists"
 fi
 source ${_APPSAWAY_ENVFILE}
 for _deploy_file in ${APPSAWAY_DEPLOY_YAML_FILE_LIST}
 do
    if [ ! -f "../demos/${APPSAWAY_APP_NAME}/${_deploy_file}" ]; then
      exit_err "deployments file ${_deploy_file} does not exists"
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
  if [ "$4" != "" ]; then
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 "$_SSH_CMD_PREFIX ; $3 > $4 2>&1"
  else
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 "$_SSH_CMD_PREFIX ; $3"
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

  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_ICUBHEADNODE_ADDR with command ${stop_cmd}"
      run_via_ssh $APPSAWAY_ICUBHEADNODE_USERNAME $APPSAWAY_ICUBHEADNODE_ADDR " if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN} -f ${file} ${stop_cmd}; fi"
    done
  fi
  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_GUINODE_ADDR with command ${stop_cmd}"
      run_via_ssh $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR "export DISPLAY=${mydisplay} ; export XAUTHORITY=${myXauth}; if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN} -f ${file} ${stop_cmd}; fi"
    done
  elif [ "$APPSAWAY_GUINODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_CONSOLENODE_ADDR with command ${stop_cmd}"
      run_via_ssh $APPSAWAY_CONSOLENODE_USERNAME $APPSAWAY_CONSOLENODE_ADDR "export DISPLAY=${mydisplay} ; export XAUTHORITY=${myXauth}; if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN} -f ${file} ${stop_cmd}; fi"
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
  echo "registry flag: ${REGISTRY_UP_FLAG}"
  if [[ ${LOCAL_IMAGE_FLAG} == true && ${REGISTRY_UP_FLAG} == false ]]
  then
    ${_DOCKER_BIN} service rm registry
  fi
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
