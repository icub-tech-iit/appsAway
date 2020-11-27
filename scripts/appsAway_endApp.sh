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
# LATEST MODIFICATION DATE (YYYY-MM-DD) : 2019-11-12
#
_SCRIPT_VERSION="0.9"          # Sets version variable
#
_SCRIPT_TEMPLATE_VERSION="1.1.0" #
#
# ##############################################################################
# Defaults
# local variable name starts with "_"
_ICUBAPPS_ENVFILE="appsAway_setEnvironment.local.sh"
# ##############################################################################
_SCP_BIN=$(which scp || true)
_SCP_PARAMS=""
_SSH_BIN=$(which ssh || true)
_SSH_PARAMS="-T"
_DOCKER_BIN=$(which docker || true)
_DOCKER_PARAMS=""

print_defs ()
{
  echo "Default parameters are"
  echo " _SCRIPT_TEMPLATE_VERSION is $_SCRIPT_TEMPLATE_VERSION"
  echo " _SCRIPT_VERSION is $_SCRIPT_VERSION"
  echo " _ICUBAPPS_ENVFILE is $_ICUBAPPS_ENVFILE"
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
  echo "$(date +%d-%m-%Y) - $(date +%H:%M:%S) : $1"
}

warn() {
  echo "$(date +%d-%m-%Y) - $(date +%H:%M:%S) WARNING : $1"
}

error() {
  echo "$(date +%d-%m-%Y) - $(date +%H:%M:%S) ERROR : $1"
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
 if [ ! -f "${_ICUBAPPS_ENVFILE}" ]; then
   exit_err "enviroment file ${_ICUBAPPS_ENVFILE} does not exists"
 fi
 source ${_ICUBAPPS_ENVFILE}
 for _deploy_file in ${ICUBAPPS_DEPLOY_YAML_FILE_LIST}
 do
    if [ ! -f "${_deploy_file}" ]; then
      exit_err "deployments file ${_deploy_file} does not exists"
    fi
 done
}

fini()
{
  log "$0 ENDED "
}

run_via_ssh_wait()
{
  ${_SSH_BIN} ${_SSH_PARAMS} ${ICUBAPPS_USER_NAME}@$1 "cd ${ICUBAPPS_APP_PATH} && $2"
}

run_via_ssh_nowait()
{
  _TEMP_FILE="_tmp_command.sh"
  echo "nohup $2 >/dev/null 2>&1 &" > $_TEMP_FILE
  ${_SSH_BIN} ${_SSH_PARAMS} ${ICUBAPPS_USER_NAME}@$1 "mkdir -p ${ICUBAPPS_APP_PATH}"
  ${_SCP_BIN} ${_SCP_PARAMS} $_TEMP_FILE ${ICUBAPPS_USER_NAME}@$1:${ICUBAPPS_APP_PATH}/
  rm ${_TEMP_FILE}
  ${_SSH_BIN} ${_SSH_PARAMS} ${ICUBAPPS_USER_NAME}@$1 "export DISPLAY=:0 ; bash ${ICUBAPPS_APP_PATH}/${_TEMP_FILE}"
  ${_SSH_BIN} ${_SSH_PARAMS} ${ICUBAPPS_USER_NAME}@$1 "rm ${ICUBAPPS_APP_PATH}/${_TEMP_FILE}"
}

is_this_node_swarm_master()
{
  _SWARM_MASTER=$(${_DOCKER_BIN} ${_DOCKER_PARAMS} info 2> /dev/null | grep "Is Manager: true" )
  if [ "$_SWARM_MASTER" == "" ]; then
	  exit_err "this node is not the master"
  fi
}

run_undeploy()
{
  log "executing docker stack undeploy"
  ${_DOCKER_BIN} ${_DOCKER_PARAMS} stack rm ${ICUBAPPS_STACK_NAME}
}

run_hardware_steps()
{
  log "executing hardware-dependant steps to nodes ${ICUBAPPS_HEAD_YAML_FILE} ${ICUBAPPS_GUI_YAML_FILE}"
  run_via_ssh_wait $ICUBAPPS_ICUBHEADNODE_ADDR "docker-compose down --remove-orphans"
  run_via_ssh_wait $ICUBAPPS_ICUBHEADNODE_ADDR "docker-compose rm -s -f"
  run_via_ssh_wait $ICUBAPPS_GUINODE_ADDR "docker-compose down --remove-orphans"
  run_via_ssh_wait $ICUBAPPS_GUINODE_ADDR "docker-compose rm -s -f"
}

main()
{
  is_this_node_swarm_master
  run_undeploy
  run_hardware_steps
}

parse_opt "$@"
init
main
fini
exit 0
