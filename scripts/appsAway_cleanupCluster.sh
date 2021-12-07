#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_cleanupCluster.sh
#
# DESCRIPTION: clean up the docker cluster 
#
# NOTE: the node where this script is executed is selected as swarm master
#
# AUTHOR : Valentina Gaggero / Laura Cavaliere / Ilaria Carlini
#
# LATEST MODIFICATION DATE (YYYY-MM-DD) : 2021-11-08
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
_SSH_BIN=$(which ssh || true)
_SSH_PARAMS="-T"
_DOCKER_BIN=$(which docker || true)
_DOCKER_COMPOSE_BIN_CONSOLE=$(which docker-compose || true)
_DOCKER_ENV_FILE=".env"
_APPSAWAY_ENV_FILE="appsAway_setEnvironment.local.sh"
stop_cmd="down"
if [ "$os" = "Darwin" ]
then
  _OS_HOME_DIR=/Users
else
  _OS_HOME_DIR=/home
fi

# ##############################################################################
print_defs ()
{
  echo "Default parameters are"
  echo " _SCRIPT_TEMPLATE_VERSION is $_SCRIPT_TEMPLATE_VERSION"
  echo " _SCRIPT_VERSION is $_SCRIPT_VERSION"
  echo " _APPSAWAY_ENV_FILE is $_APPSAWAY_ENV_FILE"
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
 log "$0 STARTED"
 _SSH_BIN=$(which ssh)
 if [ "${_SSH_BIN}" == "" ]; then
   exit_err "ssh binary not found"
 fi
 _DOCKER_BIN=$(which docker)
 if [ "${_DOCKER_BIN}" == "" ]; then
   exit_err "docker binary not found"
 fi
 if [ "${_DOCKER_COMPOSE_BIN_CONSOLE}" == "" ]; then
   exit_err "docker-compose binary not found in the console node"
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
}

fini()
{
  log "$0 ENDED "
}

check_params()
{
  if [[ -n "$1" ]] ; then
      if [[ "$1" != *"registry"* && "$1" != *"stack"* && "$1" != *"volumes"* && "$1" != *"swarm"* && "$1" != *"all"* ]] ; then
        echo -e "Wrong argument, please select the cleaning mode: registry - stack - volumes - swarm - all"
        echo 'e.g.: ./appsAway_cleanupCluster.sh registry volumes'
        exit
      fi
  else
      echo 'Please select the cleaning mode: registry - stack - volumes - swarm - all'
      echo 'e.g.: ./appsAway_cleanupCluster.sh registry volumes'
      exit
  fi
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

run_via_ssh_no_folder()
{
  if [ "$4" != "" ]; then
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 " $3 > $4 2>&1"
  else
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 " $3"
  fi
}

clean_up_volumes(){
ssh -T $1@$2<<EOF


    dockerVolumes=\$(docker volume ls --format "{{.Name}}")
    if [ "\$dockerVolumes" != "" ]; then
        docker volume rm \$dockerVolumes
        docker volume ls -qf dangling=true | xargs -r docker volume rm #command to make sure the cleanup is complete
    fi

EOF
}

clean_up_registry()
{
    if [[ ${REGISTRY_UP_FLAG} == false ]]
    then
        log "Cleaning up registry created by this deployment..."
        ${_DOCKER_COMPOSE_BIN_CONSOLE} -f appsAway_registryLaunch.yml down
    else 
        log "No registry has been created by this deployment. No need to remove it."
    fi
}

stop_deploy()
{
  log "executing docker stack stop"
  ${_DOCKER_BIN} ${_DOCKER_PARAMS} stack rm ${APPSAWAY_STACK_NAME} || true
}

clean_up_stack() 
{ 
  stop_deploy
  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${file} on host $APPSAWAY_ICUBHEADNODE_ADDR with command ${stop_cmd}"
      run_via_ssh $APPSAWAY_ICUBHEADNODE_USERNAME $APPSAWAY_ICUBHEADNODE_ADDR "if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN_HEAD} -f ${file} ${stop_cmd}; fi" &
    done
  fi
  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${file} on host $APPSAWAY_GUINODE_ADDR with command ${stop_cmd}"
      run_via_ssh $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR "if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN_GUI} -f ${file} ${stop_cmd}; fi" &
    done
  elif [ "$APPSAWAY_GUINODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "stopping docker-compose with file ${file} on host $APPSAWAY_CONSOLENODE_ADDR with command ${stop_cmd}"
      run_via_ssh $APPSAWAY_CONSOLENODE_USERNAME $APPSAWAY_CONSOLENODE_ADDR "if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN_CONSOLE} -f ${file} ${stop_cmd}; fi" &
    done
  fi
  wait
  nodes_addr_list=(${APPSAWAY_NODES_ADDR_LIST})
  nodes_username_list=(${APPSAWAY_NODES_USERNAME_LIST})
  for index in "${!nodes_addr_list[@]}"
  do
    log "Removing hanging containers in node ${nodes_addr_list[$index]}..."
    run_via_ssh_no_folder ${nodes_username_list[$index]} ${nodes_addr_list[$index]} "docker container prune --force" &
  done
  wait
  for index in "${!nodes_addr_list[@]}"
  do
    log "Removing all volumes not referenced by any containers (i.e. dangling volumes) in node ${nodes_addr_list[$index]}..."
    clean_up_volumes ${nodes_username_list[$index]} ${nodes_addr_list[$index]}
  done
}

clean_up_swarm()
{
  nodes_addr_list=(${APPSAWAY_NODES_ADDR_LIST})
  nodes_username_list=(${APPSAWAY_NODES_USERNAME_LIST})
  for index in "${!nodes_addr_list[@]}"
  do
    if [ ${nodes_addr_list[$index]} != "$APPSAWAY_CONSOLENODE_ADDR" ]; then
      log "Leaving the swarm in node ${nodes_addr_list[$index]}..."
      run_via_ssh_no_folder ${nodes_username_list[$index]} ${nodes_addr_list[$index]} "docker swarm leave --force |& grep -v Error" || true
    fi
  done
  log "Killing the swarm..."
  docker swarm leave --force |& grep -v Error || true
}

clean_up_icubapps()
{
  for index in "${!nodes_addr_list[@]}"
  do
    log "Removing ${_OS_HOME_DIR}/${nodes_username_list[$index]}/${APPSAWAY_APP_PATH_NOT_CONSOLE} on node ${nodes_addr_list[$index]}..."
    run_via_ssh_no_folder ${nodes_username_list[$index]} ${nodes_addr_list[$index]} "rm -rf ${_OS_HOME_DIR}/${nodes_username_list[$index]}/${APPSAWAY_APP_PATH_NOT_CONSOLE}"
  done
}

main()
{ 
  nodes_addr_list=(${APPSAWAY_NODES_ADDR_LIST})
  nodes_username_list=(${APPSAWAY_NODES_USERNAME_LIST})
  if [[ "$@" == *"registry"* ]] ; then
    clean_up_registry
  fi
  if [[ "$@" == *"stack"* ]] ; then
    clean_up_stack
  fi
  if [[ "$@" == *"volumes"* ]] ; then
    for index in "${!nodes_addr_list[@]}"
    do
      log "Removing all volumes not referenced by any containers (i.e. dangling volumes) in node ${nodes_addr_list[$index]}..."
      clean_up_volumes ${nodes_username_list[$index]} ${nodes_addr_list[$index]}
    done
  fi
  if [[ "$@" == *"swarm"* ]] ; then
    clean_up_swarm
  fi
  if [[ "$@" == *"icubapps"* ]] ; then
    clean_up_icubapps
  fi
  if [[ "$@" == *"all"* ]] ; then
    log "About to cleanup the cluster..."
    clean_up_registry 
    clean_up_stack 
    clean_up_swarm
    clean_up_icubapps
  fi
}

parse_opt "$@"
check_params "$@"
init
main "$@"
fini
exit 0
