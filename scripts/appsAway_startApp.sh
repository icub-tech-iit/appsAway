#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_startApp.sh
#
# DESCRIPTION: start the application by ssh
#
# NOTE: this script must be executed on master node
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
  if [ "$3" != "" ]; then
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_USER_NAME}@$1 "$_SSH_CMD_PREFIX ; $2 > $3 2>&1"
  else
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_USER_NAME}@$1 "$_SSH_CMD_PREFIX ; $2"
  fi
}


run_via_ssh_nowait()
{
  if [ "$3" != "" ]; then
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_USER_NAME}@$1 "$_SSH_CMD_PREFIX ; nohup $2 > $3 2>&1 &"
  else
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_USER_NAME}@$1 "$_SSH_CMD_PREFIX ; nohup $2 >/dev/null 2>&1 &"
  fi
}

is_this_node_swarm_master()
{
  _SWARM_MASTER=$(${_DOCKER_BIN} ${_DOCKER_PARAMS} info 2> /dev/null | grep "Is Manager" || true)
  if [ -z "$_SWARM_MASTER" ]; then
    exit_err "cluster has not been initialized, please run setupCluster script"
  fi
  if [ "$_SWARM_MASTER" != "  Is Manager: true" ]; then
	  exit_err "this node is not the master"
  fi
}

run_deploy()
{

  log "executing docker stack deploy"
  cd $APPSAWAY_APP_PATH
  export $(cat .env)
  for _file2deploy in ${APPSAWAY_DEPLOY_YAML_FILE_LIST}
  do
    ${_DOCKER_BIN} ${_DOCKER_PARAMS} stack deploy -c ${_file2deploy} ${APPSAWAY_STACK_NAME}
  done
}

run_hardware_steps_via_ssh()
{
  log "running hardware-dependant steps to nodes"

  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      log "running docker-compose with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_ICUBHEADNODE_ADDR"
      #run_via_ssh_nowait $APPSAWAY_ICUBHEADNODE_ADDR "docker-compose -f ${file} up" "log.txt"
      run_via_ssh $APPSAWAY_ICUBHEADNODE_ADDR "docker-compose -f ${file} up --detach"
    done
  fi
  #sleep 3
  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "running docker-compose with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_GUINODE_ADDR"
      #run_via_ssh_nowait $APPSAWAY_GUINODE_ADDR "docker-compose -f ${file} up" "log.txt"
      run_via_ssh $APPSAWAY_GUINODE_ADDR "export DISPLAY=:1 ; export XAUTHORITY=/run/user/1000/gdm/Xauthority; docker-compose -f ${file} up --detach"
    done
  fi
}

stop_hardware_steps_via_ssh()
{
  read -n 1 -s -r -p "Press any key to stop the App"
  echo
  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_ICUBHEADNODE_ADDR"
      run_via_ssh $APPSAWAY_ICUBHEADNODE_ADDR "docker-compose -f ${file} down"
    done
  fi
  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_GUINODE_ADDR"
      run_via_ssh $APPSAWAY_GUINODE_ADDR "export DISPLAY=:1 ; export XAUTHORITY=/run/user/1000/gdm/Xauthority; docker-compose -f ${file} down"
    done
 fi
}

main()
{
  is_this_node_swarm_master
  run_deploy
  run_hardware_steps_via_ssh
#  stop_hardware_steps_via_ssh
}

parse_opt "$@"
init
main
fini
exit 0
