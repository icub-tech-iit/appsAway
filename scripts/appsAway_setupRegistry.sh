#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_setupRegistry.sh
#
# DESCRIPTION: set up the local registry 
#
# NOTE: the node where this script is executed is selected as swarm master
#
# AUTHOR : Valentina Gaggero / Laura Cavaliere / Ilaria Carlini
#
# LATEST MODIFICATION DATE (YYYY-MM-DD) : 2021-11-11
#
_SCRIPT_VERSION="1.0"          # Sets version variable
#
_SCRIPT_TEMPLATE_VERSION="1.1.0" #
#
# ##############################################################################
# Defaults
# local variable name starts with "_"
_NC='\033[0m' # No Color
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_BLUE='\033[0;34m'
_YELLOW='\033[1;33m'
_PURPLE='\033[1;35m'
_LGRAY='\033[0;37m'
_DOCKER_BIN=$(which docker || true)
_DOCKER_COMPOSE_BIN_CONSOLE=$(which docker-compose || true)
_APPSAWAY_ENVFILE="appsAway_setEnvironment.local.sh"
# ##############################################################################
print_defs ()
{
  echo "Default parameters are"
  echo " _SCRIPT_TEMPLATE_VERSION is $_SCRIPT_TEMPLATE_VERSION"
  echo " _SCRIPT_VERSION is $_SCRIPT_VERSION"
  echo " _APPSAWAY_ENVFILE is $_APPSAWAY_ENVFILE"
  echo " _DOCKER_ENV_FILE is $_DOCKER_ENV_FILE"
  echo " _YARP_CONFIG_FILES_PATH is $_YARP_CONFIG_FILES_PATH"
  echo " _YARP_NAMESPACE is $_YARP_NAMESPACE"
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
 if [ "${_DOCKER_COMPOSE_BIN_CONSOLE}" == "" ]; then
   exit_err "docker-compose binary not found in the console node"
 fi
 if [ ! -f "${_APPSAWAY_ENVFILE}" ]; then
   exit_err "enviroment file ${_APPSAWAY_ENVFILE} does not exist"
 fi
 source ${_APPSAWAY_ENVFILE}
 echo "INIT: Registry_up_flag: $REGISTRY_UP_FLAG" 
 log "$0 STARTED"
}

fini()
{
  log "$0 ENDED "
}


check_registry() 
{
  REGISTRY_UP_FLAG=true
  container_id_list=($(${_DOCKER_BIN} container ls --format "table {{.ID}}"))
  container_id_list=(${container_id_list[@]:2})
  port_content=""
  if [ ${#container_id_list[@]} == 0 ]
  then
    REGISTRY_UP_FLAG=false
  else
    for id in ${container_id_list[@]}
    do
      port_content="$(${_DOCKER_BIN} inspect $id | grep "5000")"
      if [ "$port_content" == "" ]
      then
        REGISTRY_UP_FLAG=false
      else
        exit_err "A container is already running on port 5000"
      fi
    done
  fi 

  if [[ ${REGISTRY_UP_FLAG} == false ]]
  then
    log "No registry running on port 5000"
    create_registry
  fi
  
  echo "Registry_up_flag: $REGISTRY_UP_FLAG"
  echo "export REGISTRY_UP_FLAG="$REGISTRY_UP_FLAG >> ${HOME}/teamcode/appsAway/scripts/${_APPSAWAY_ENVFILE}
}

create_registry()
{ 
  cd ~/teamcode/appsAway/scripts/ansible_setup/
  ./setup_hosts_ini.sh
  echo "Preparing the system for local registry..."
  script -efq ansible_output.txt -c "make prepare_local_registry"
  rm ansible_output.txt
  cd ~/teamcode/appsAway/scripts/
  log "Creating the local registry"
  ${_DOCKER_COMPOSE_BIN_CONSOLE} -f appsAway_registryLaunch.yml pull
  ${_DOCKER_COMPOSE_BIN_CONSOLE} -f appsAway_registryLaunch.yml up --detach
}

main()
{ 
  check_registry
}

parse_opt "$@"
init
main
fini
exit 0
