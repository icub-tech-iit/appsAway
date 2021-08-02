#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_startApp.sh
#
# DESCRIPTION: start the application by ssh
#
# NOTE: this script must be executed on master node
#
# AUTHOR : valentina Gaggero / Matteo Brunettini
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
_DOCKER_COMPOSE_BIN_CONSOLE=$(which docker-compose || true)
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
_DOCKER_PARAMS=""
_SSH_CMD_PREFIX=""
_OS_HOME_DIR="/home"
_APPSAWAY_APP_PATH_NOT_CONSOLE="iCubApps/${APPSAWAY_APP_NAME}"
_CWD=$(pwd)

val1=$((0))

echo $val1 >| ${HOME}/teamcode/appsAway/scripts/PIPE

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
 #_SCP_BIN=$(which scp)
 if [ "${_SCP_BIN}" == "" ]; then
   exit_err "scp binary not found"
 fi
 #_SSH_BIN=$(which ssh)
 if [ "${_SSH_BIN}" == "" ]; then
   exit_err "ssh binary not found"
 fi
 #_DOCKER_BIN=$(which docker)
 if [ "${_DOCKER_BIN}" == "" ]; then
   exit_err "docker binary not found"
 fi
 if [ "${_DOCKER_COMPOSE_BIN_CONSOLE}" == "" ]; then
   exit_err "docker-compose binary not found in the console node"
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
  _SSH_CMD_PREFIX_FOR_USER="cd ${_OS_HOME_DIR}/$1/${_APPSAWAY_APP_PATH_NOT_CONSOLE}"
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

  if [[ ${LOCAL_IMAGE_FLAG} == true ]]
  then    
    REGISTRY_UP_FLAG=true
    registry_up=$(${_DOCKER_BIN} service ls | grep "*:5000->5000/tcp" | tr -d ' ') 
    if [ "$registry_up" == "" ]
    then     
      REGISTRY_UP_FLAG=false
      echo "Creating the local registry"
      ${_DOCKER_BIN} service create --name registry --publish published=5000,target=5000 registry:2 
    fi
    echo "Registry_up_flag: $REGISTRY_UP_FLAG"
    echo "export REGISTRY_UP_FLAG=$REGISTRY_UP_FLAG" >> ${HOME}/teamcode/appsAway/scripts/${_APPSAWAY_ENVFILE}
    
    ${_DOCKER_BIN} tag ${LOCAL_IMAGE_NAME} ${APPSAWAY_CONSOLENODE_ADDR}:5000/${LOCAL_IMAGE_NAME}
    ${_DOCKER_BIN} push ${APPSAWAY_CONSOLENODE_ADDR}:5000/${LOCAL_IMAGE_NAME}
    # echo "export APPSAWAY_IMAGES=\"localhost:5000/${LOCAL_IMAGE_NAME}\"" >> ${HOME}/teamcode/appsAway/scripts/appsAway_setEnvironment.local.sh
    # source ${HOME}/teamcode/appsAway/scripts/appsAway_setEnvironment.local.sh
    # for i in "${!APPSAWAY_IMAGES[@]}"; 
    # do
    #   ${_DOCKER_BIN} push ${APPSAWAY_IMAGES[$i]}:${APPSAWAY_VERSIONS[$i]}
    # done 
  fi  
  for _file2deploy in ${APPSAWAY_DEPLOY_YAML_FILE_LIST}
  do       
    log "downloading the image: ${_DOCKER_COMPOSE_BIN_CONSOLE} -f ${_file2deploy} up" # pull "
    ${_DOCKER_COMPOSE_BIN_CONSOLE} -f ${_file2deploy} pull
    log "pushing image into service registry for distribution in swarm"
    ${_DOCKER_COMPOSE_BIN_CONSOLE} -f ${_file2deploy} push
    log "Image from ${_file2deploy} successfully pushed"
    val1=$(( $val1 + 10 ))
    echo $val1 >| ${HOME}/teamcode/appsAway/scripts/PIPE
    ${_DOCKER_BIN} ${_DOCKER_PARAMS} stack deploy -c ${_file2deploy} ${APPSAWAY_STACK_NAME}
  done
}

getdisplay()
{  
  os=`uname -s`
  if [ "$os" = "Darwin" ]
  then
     echo ${APPSAWAY_CONSOLENODE_ADDR}:0
  else
    ps -u $(id -u) -o pid= | \
    while read pid; do
        cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep '^DISPLAY=:'
    done | grep -o ':[0-9]*' | sort -u
  fi
  
}

scp_to_node()
{
  file_to_send=$1
  username_to_receive=$2
  ip_to_receive=$3
  path_to_receive=$4
  full_path_to_receive=${_OS_HOME_DIR}/${username_to_receive}/${path_to_receive}
  ${_SCP_BIN} ${_SCP_PARAMS_DIR} ${file_to_send} ${username_to_receive}@${ip_to_receive}:${full_path_to_receive}/
}

run_hardware_steps_via_ssh()
{
  log "running hardware-dependant steps to nodes"

  log "current working dir: $_CWD"

  mydisplay=$(getdisplay)
  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    GUI_DISPLAY=$(ssh $APPSAWAY_GUINODE_USERNAME@$APPSAWAY_GUINODE_ADDR "ps -u $(id -u) -o pid= | xargs -I PID -r cat /proc/PID/environ 2> /dev/null | tr '\0' '\n' | grep ^DISPLAY=: | sort -u")
  fi
  myXauth="" 
  os=`uname -s`
  if [ "$os" = "Darwin" ]
  then
     myXauth=${XAUTHORITY}
  else
    myXauth="/run/user/$UID/gdm/Xauthority"
  fi

 if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      log "running ${_DOCKER_COMPOSE_BIN_HEAD} with file ${_OS_HOME_DIR}/${APPSAWAY_ICUBHEADNODE_USERNAME}/${_APPSAWAY_APP_PATH_NOT_CONSOLE}/${file} on host $APPSAWAY_ICUBHEADNODE_ADDR"
      #run_via_ssh_nowait $APPSAWAY_ICUBHEADNODE_ADDR "${_DOCKER_COMPOSE_BIN} -f ${file} up" "log.txt"
      scp_to_node ${_CWD}/appsAway_containerPermissions.sh $APPSAWAY_ICUBHEADNODE_USERNAME $APPSAWAY_ICUBHEADNODE_ADDR $_APPSAWAY_APP_PATH_NOT_CONSOLE
      scp_to_node ${_CWD}/appsAway_changeNewFilesPermissions.sh $APPSAWAY_ICUBHEADNODE_USERNAME $APPSAWAY_ICUBHEADNODE_ADDR $_APPSAWAY_APP_PATH_NOT_CONSOLE      
      run_via_ssh $APPSAWAY_ICUBHEADNODE_USERNAME $APPSAWAY_ICUBHEADNODE_ADDR "export APPSAWAY_OPTIONS=${APPSAWAY_OPTIONS} ; ${_DOCKER_COMPOSE_BIN_HEAD} -f ${file} up --detach"
    done
    val1=$(( $val1 + 5 ))
    echo $val1 >| ${HOME}/teamcode/appsAway/scripts/PIPE
  fi
  #sleep 3
  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "running ${_DOCKER_COMPOSE_BIN_GUI} with file ${_OS_HOME_DIR}/${APPSAWAY_GUINODE_USERNAME}/${_APPSAWAY_APP_PATH_NOT_CONSOLE}/${file} on host $APPSAWAY_GUINODE_ADDR"
      #run_via_ssh_nowait $APPSAWAY_GUINODE_ADDR "${_DOCKER_COMPOSE_BIN} -f ${file} up" "log.txt"
      scp_to_node ${_CWD}/appsAway_containerPermissions.sh $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR $_APPSAWAY_APP_PATH_NOT_CONSOLE
      scp_to_node ${_CWD}/appsAway_changeNewFilesPermissions.sh $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR $_APPSAWAY_APP_PATH_NOT_CONSOLE
      run_via_ssh $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR "export APPSAWAY_OPTIONS=${APPSAWAY_OPTIONS} ; export ${GUI_DISPLAY} ; export XAUTHORITY=${myXauth}; if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN_GUI} -f ${file} up --detach; fi"
    done
    val1=$(( $val1 + 5 ))
    echo $val1 >| ${HOME}/teamcode/appsAway/scripts/PIPE
  elif [ "$APPSAWAY_GUINODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "running ${_DOCKER_COMPOSE_BIN_CONSOLE} with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_CONSOLENODE_ADDR"
      #run_via_ssh_nowait $APPSAWAY_GUINODE_ADDR "${_DOCKER_COMPOSE_BIN} -f ${file} up" "log.txt"
      scp_to_node ${_CWD}/appsAway_containerPermissions.sh $APPSAWAY_CONSOLENODE_USERNAME $APPSAWAY_CONSOLENODE_ADDR $_APPSAWAY_APP_PATH_NOT_CONSOLE
      scp_to_node ${_CWD}/appsAway_changeNewFilesPermissions.sh $APPSAWAY_CONSOLENODE_USERNAME $APPSAWAY_CONSOLENODE_ADDR $_APPSAWAY_APP_PATH_NOT_CONSOLE
      run_via_ssh $APPSAWAY_CONSOLENODE_USERNAME $APPSAWAY_CONSOLENODE_ADDR "export APPSAWAY_OPTIONS=${APPSAWAY_OPTIONS} ; export DISPLAY=${mydisplay} ; export XAUTHORITY=${myXauth}; if [ -f '$file' ]; then ${_DOCKER_COMPOSE_BIN_CONSOLE} -f ${file} up --detach; fi"
    done
    val1=$(( $val1 + 5 ))
    echo $val1 >| ${HOME}/teamcode/appsAway/scripts/PIPE
  fi
}

stop_hardware_steps_via_ssh()
{
  read -n 1 -s -r -p "Press any key to stop the App"
  echo
  mydisplay=$(getdisplay)

  myXauth="" 
  os=`uname -s`
  if [ "$os" = "Darwin" ]
  then
     myXauth=${XAUTHORITY}
  else
    myXauth="/run/user/$UID/gdm/Xauthority"
  fi

  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      log "stopping ${_DOCKER_COMPOSE_BIN_HEAD} with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_ICUBHEADNODE_ADDR"
      run_via_ssh $APPSAWAY_ICUBHEADNODE_uSERNAME $APPSAWAY_ICUBHEADNODE_ADDR "${_DOCKER_COMPOSE_BIN_HEAD} -f ${file} down"
    done
  fi
  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "stopping ${_DOCKER_COMPOSE_BIN_GUI} with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_GUINODE_ADDR"
      #run_via_ssh $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR "export DISPLAY=${mydisplay} ; export XAUTHORITY=${myXauth}; ${_DOCKER_COMPOSE_BIN_GUI} -f ${file} down"
      run_via_ssh $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR "${_DOCKER_COMPOSE_BIN_GUI} -f ${file} down"
    done
  elif [ "$APPSAWAY_GUINODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      log "stopping ${_DOCKER_COMPOSE_BIN_CONSOLE} with file ${APPSAWAY_APP_PATH}/${file} on host $APPSAWAY_CONSOLENODE_ADDR"
      run_via_ssh $APPSAWAY_CONSOLENODE_USERNAME $APPSAWAY_CONSOLENODE_ADDR "export DISPLAY=${mydisplay} ; export XAUTHORITY=${myXauth}; ${_DOCKER_COMPOSE_BIN_CONSOLE} -f ${file} down"
    done
  fi
}

main()
{
  is_this_node_swarm_master
  val1=$(( 30 ))
  echo $val1 >| ${HOME}/teamcode/appsAway/scripts/PIPE
  run_deploy
  val1=$(( 70 ))
  echo $val1 >| ${HOME}/teamcode/appsAway/scripts/PIPE
  run_hardware_steps_via_ssh
  val1=$(( 90 ))
  echo $val1 >| ${HOME}/teamcode/appsAway/scripts/PIPE
#  stop_hardware_steps_via_ssh
}

parse_opt "$@"
init
main
fini
val1=$(( 100 ))
echo $val1 >| ${HOME}/teamcode/appsAway/scripts/PIPE
exit 0
