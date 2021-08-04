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
 if [ "${_SSH_BIN}" == "" ]; then
   exit_err "ssh binary not found"
 fi
 if [ "${_DOCKER_BIN}" == "" ]; then
   exit_err "docker binary not found"
 fi
 if [ ! -f "${_APPSAWAY_ENV_FILE}" ]; then
   exit_err "enviroment file ${_APPSAWAY_ENV_FILE} does not exists"
 fi
 source ${_APPSAWAY_ENV_FILE}
 os=`uname -s`
 if [ "$os" = "Darwin" ]
 then
  _ALL_LOCAL_IP_ADDRESSES=$(arp -a | awk -F'[()]' '{print $2}')
 else
  _ALL_LOCAL_IP_ADDRESSES=$(hostname --all-ip-address)
  _ALL_LOCAL_IP_ADDRESSES+=$(hostname --all-fqdns)
  _ALL_LOCAL_IP_ADDRESSES+=localhost
 fi
 if [ "$_ALL_LOCAL_IP_ADDRESSES" == "" ]; then
   exit_err "unable to read local IP addresses"
 fi
 for ipaddr in ${_ALL_LOCAL_IP_ADDRESSES}
 do
   if [ "$ipaddr" == "$APPSAWAY_CONSOLENODE_ADDR" ]; then
     _MAIN_LOCAL_IP_ADDRESS="$ipaddr"
   fi
 done
 if [ -z "$_MAIN_LOCAL_IP_ADDRESS" ]; then
   exit_err "Please run this script in CONSOLE NODE with IP address $APPSAWAY_CONSOLENODE_ADDR"
 fi
 log "$0 STARTED"
}

fini()
{
  log "$0 ENDED "
}

run_via_ssh()
{
  if [ "$4" != "" ]; then
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 "$3 > $4 2>&1"
  else
    ${_SSH_BIN} ${_SSH_PARAMS} $1@$2 "$3"
  fi
}

swarm_start()
{
  _SWARM_INIT_COMMAND=$( ${_DOCKER_BIN} ${_DOCKER_PARAMS} swarm init --advertise-addr ${APPSAWAY_CONSOLENODE_ADDR} | egrep -i '^\s{4}')
  if [ "$_SWARM_INIT_COMMAND" == "" ]; then
    error "swarm init command string is empty (failed swarm initialization?)"
  fi

  iter=1
  List=$APPSAWAY_NODES_USERNAME_LIST
  set -- $List
  for node_ip in ${APPSAWAY_NODES_ADDR_LIST}
  do
    if [ "$node_ip" != "$APPSAWAY_CONSOLENODE_ADDR" ]; then
      username=$( eval echo "\$$iter")
      log "running init on node $node_ip.."
      run_via_ssh $username $node_ip "$_SWARM_INIT_COMMAND"
    fi
    iter=$((iter+1))
  done
}

ip2hostname()
{
  run_via_ssh ${1} ${2} "hostname"
}

fill_hostname_list()
{
  iter=1
  List=$APPSAWAY_NODES_USERNAME_LIST
  set -- $List
  for _ip_addr in ${APPSAWAY_NODES_ADDR_LIST}
  do
    username=$( eval echo "\$$iter")
    log "Checking username ${username} with IP ${_ip_addr}"
	  _hostname=$(ip2hostname $username $_ip_addr)
	  if [ "$_hostname" == "" ]; then
		  exit_err "unable to get hostname from IP $_ip_addr"
	  fi
      _HOSTNAME_LIST="$_hostname $_HOSTNAME_LIST"
    iter=$((iter+1))
  done
}

set_hardware_labels()
{
  log "setting labels on hardware-dependant nodes.."
  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    ${_DOCKER_BIN} ${_DOCKER_PARAMS} node update --label-add type=head $(ip2hostname $APPSAWAY_ICUBHEADNODE_USERNAME $APPSAWAY_ICUBHEADNODE_ADDR)
  fi

  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    ${_DOCKER_BIN} ${_DOCKER_PARAMS} node update --label-add type=gui $(ip2hostname $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR)
  fi

  if [ "$APPSAWAY_CUDANODE_ADDR" != "" ]; then
    APPSAWAY_CUDANODE_ADDR_LIST=($APPSAWAY_CUDANODE_ADDR)
    APPSAWAY_CUDANODE_USERNAME_LIST=($APPSAWAY_CUDANODE_USERNAME)
    for index in "${!APPSAWAY_CUDANODE_ADDR_LIST[@]}"
    do
      ${_DOCKER_BIN} ${_DOCKER_PARAMS} node update --label-add type=cuda $(ip2hostname ${APPSAWAY_CUDANODE_USERNAME[$index]} ${APPSAWAY_CUDANODE_ADDR_LIST[$index]})
    done
  fi

  if [ "$APPSAWAY_WORKERNODE_ADDR" != "" ]; then
    APPSAWAY_WORKERNODE_ADDR_LIST=($APPSAWAY_WORKERNODE_ADDR)
    APPSAWAY_WORKERNODE_USERNAME_LIST=($APPSAWAY_WORKERNODE_USERNAME)
    for index in "${!APPSAWAY_WORKERNODE_ADDR_LIST[@]}"
    do
      ${_DOCKER_BIN} ${_DOCKER_PARAMS} node update --label-add type=worker $(ip2hostname ${APPSAWAY_WORKERNODE_USERNAME[$index]} ${APPSAWAY_WORKERNODE_ADDR_LIST[$index]})
    done
  fi
}

main()
{
  fill_hostname_list
  swarm_start
  set_hardware_labels
}

parse_opt "$@"
init
main
fini
exit 0
