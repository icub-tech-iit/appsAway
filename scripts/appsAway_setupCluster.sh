#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_setupClustersh
#
# DESCRIPTION: setup the docker cluster
#
# NOTE: the node where this script is executed is elected as swarm master
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
_YARP_BIN=$(which yarp || true)
_DOCKER_PARAMS=""
_HOSTNAME_LIST=""
_CWD=$(pwd)
_OS_HOME_DIR="/home"
_APPSAWAY_APP_PATH_NOT_CONSOLE="iCubApps/${APPSAWAY_APP_NAME}"

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
  _OS_HOME_DIR="/Users"
  _ALL_LOCAL_IP_ADDRESSES=$(arp -a | awk -F'[()]' '{print $2}')
 else
  _ALL_LOCAL_IP_ADDRESSES=$(hostname --all-ip-address)
  _ALL_LOCAL_IP_ADDRESSES+=$(hostname --all-fqdns)
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

# we could/should change this function to first check if a yarp server is running and get its IP if yes
# if yarp server is not running, then we use the console node IP to setup our own config files (as currently)
create_yarp_config_files()
{
  if [ -d "${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}" ]; then
    warn "path ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH} already existing, overwriting files "
  else
    mkdir -p ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}
  fi
  if [ "${_YARP_BIN}" != "" ] 
  then
    log "Checking if YARP server is running..."
    _YARP_IP_FOUND=$( $_YARP_BIN where | echo "$( sed -nr 's/.*is available at ip (.*) port.*/\1/p' )" )
    _YARP_PORT_FOUND=$( $_YARP_BIN where | echo "$( sed -nr 's/.*at ip '"$_YARP_IP_FOUND"' port (.*).*/\1/p' )" )
    _YARP_NAMESPACE_FOUND=$( $_YARP_BIN where | echo "$( sed -nr 's/.*Name server \/(.*) is available.*/\1/p' )" )
    if [ "$_YARP_IP_FOUND" != "" ]
    then
      log "A yarp server was found with ip $_YARP_IP_FOUND port $_YARP_PORT_FOUND with namespace /$_YARP_NAMESPACE_FOUND"
      _YARP_IP_CONF=$_YARP_IP_FOUND
      _YARP_PORT_CONF=$_YARP_PORT_FOUND
      _YARP_NAMESPACE_CONF=$_YARP_NAMESPACE_FOUND
    else
      log "server not found, using default settings for yarp server"
      _YARP_IP_CONF=$APPSAWAY_CONSOLENODE_ADDR
      _YARP_PORT_CONF=10000
      _YARP_NAMESPACE_CONF=yarp
    fi
  else
    log "yarp binary not found, using default settings for yarp server"
    _YARP_IP_CONF=$APPSAWAY_CONSOLENODE_ADDR
    _YARP_PORT_CONF=10000
    _YARP_NAMESPACE_CONF=yarp # I changed this from /root to /yarp, to match the old filename
  fi
  log "creating YARP config files in path ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH} with namespace /$_YARP_NAMESPACE_CONF, ip $_YARP_IP_CONF in port $_YARP_PORT_CONF"
  echo "/$_YARP_NAMESPACE_CONF" > ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}/yarp_namespace.conf
  echo "$_YARP_IP_CONF $_YARP_PORT_CONF yarp" > ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}/_$_YARP_NAMESPACE_CONF.conf
  
  #echo "/$_YARP_NAMESPACE" > ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}/yarp_namespace.conf
  #echo "$APPSAWAY_CONSOLENODE_ADDR 10000 yarp" > ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}/_$_YARP_NAMESPACE_CONF.conf
}

create_env_file()
{
  if [ -f "${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}" ]; then
    warn "YARP docker environment file ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE} already existing, overwriting "
  else
    log "creating YARP docker environment file ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}"
  fi
  echo "USER_NAME=$APPSAWAY_USER_NAME" >> ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}
  echo "USER_PASSWORD=$APPSAWAY_USER_PASSWORD" >> ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}
  echo "MASTER_ADDR=$APPSAWAY_CONSOLENODE_ADDR" >> ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}
  echo "YARP_CONF_PATH=${_APPSAWAY_APP_PATH_NOT_CONSOLE}/${_YARP_CONFIG_FILES_PATH}" >> ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}
  
}

copy_yaml_files()
{
  log "creating path ${APPSAWAY_APP_PATH} on master node (this)"
  mkdir -p ${APPSAWAY_APP_PATH}
  for file in ${APPSAWAY_DEPLOY_YAML_FILE_LIST}
  do
    if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
      log "copying yaml file $file to master node (this)"
      cp ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_APP_PATH}/
    fi
  done
  for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
  do
    if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
      log "copying yaml file $file to master node (this)"
      cp ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_APP_PATH}/
    fi
  done
  APPSAWAY_DATA_FOLDERS=$( ls ../demos/$APPSAWAY_APP_NAME/ )
  echo "the folders are $APPSAWAY_DATA_FOLDERS"
  for folder in ${APPSAWAY_DATA_FOLDERS}
  do
    if [ "$folder" == "gui" ] 
    then
      continue
    fi
    if [ -d "../demos/$APPSAWAY_APP_NAME/$folder" ]
    then
      log "copying data folder $folder to master node (this)"
      cp -R ../demos/${APPSAWAY_APP_NAME}/${folder} ${APPSAWAY_APP_PATH}/
    fi
  done
  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    head_path=${_OS_HOME_DIR}/${APPSAWAY_ICUBHEADNODE_USERNAME}/${_APPSAWAY_APP_PATH_NOT_CONSOLE}
    log "creating path ${head_path} on node with IP ${APPSAWAY_ICUBHEADNODE_ADDR}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_ICUBHEADNODE_USERNAME}@${APPSAWAY_ICUBHEADNODE_ADDR} "mkdir -p ${head_path}"
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP $APPSAWAY_ICUBHEADNODE_ADDR"
        scp_to_node ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_ICUBHEADNODE_USERNAME} ${APPSAWAY_ICUBHEADNODE_ADDR} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  fi

  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    gui_path=${_OS_HOME_DIR}/${APPSAWAY_GUINODE_USERNAME}/${_APPSAWAY_APP_PATH_NOT_CONSOLE}
    log "creating path ${gui_path} on node with IP $APPSAWAY_GUINODE_ADDR"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_GUINODE_USERNAME}@${APPSAWAY_GUINODE_ADDR} "mkdir -p ${gui_path}"
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP $APPSAWAY_GUINODE_ADDR"
        scp_to_node ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_GUINODE_USERNAME} ${APPSAWAY_GUINODE_ADDR} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  elif [ "$APPSAWAY_GUINODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    log "creating path ${APPSAWAY_APP_PATH} on node with IP $APPSAWAY_CONSOLENODE_ADDR"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_CONSOLENODE_USERNAME}@${APPSAWAY_CONSOLENODE_ADDR} "mkdir -p ${APPSAWAY_APP_PATH}"
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP $APPSAWAY_CONSOLENODE_ADDR"
        scp_to_node ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_CONSOLENODE_USERNAME} ${APPSAWAY_CONSOLENODE_ADDR} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  fi
  _CUDA_NODE_LIST=( $APPSAWAY_CUDANODE_ADDR )
  _CUDA_USERNAME_LIST=( $APPSAWAY_CUDANODE_USERNAME )
  iter=0
  for node in ${_CUDA_NODE_LIST}
  do
    log "creating path ${_APPSAWAY_APP_PATH_NOT_CONSOLE} on CUDA node with IP ${_CUDA_NODE_LIST[iter]}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${_CUDA_USERNAME_LIST[iter]}@${_CUDA_NODE_LIST[iter]} "mkdir -p ${_APPSAWAY_APP_PATH_NOT_CONSOLE}"
    iter=$((iter+1))
  done

  _WORKER_NODE_LIST=( $APPSAWAY_WORKERNODE_ADDR )
  _WORKER_USERNAME_LIST=( $APPSAWAY_WORKERNODE_USERNAME )
  iter=0
  for node in ${_WORKER_NODE_LIST}
  do
    log "creating path ${_APPSAWAY_APP_PATH_NOT_CONSOLE} on WORKER node with IP ${_WORKER_NODE_LIST[iter]}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${_WORKER_USERNAME_LIST[iter]}@${_WORKER_NODE_LIST[iter]} "mkdir -p ${_APPSAWAY_APP_PATH_NOT_CONSOLE}"
    iter=$((iter+1))
  done
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

copy_yarp_files()
{
  cd ${APPSAWAY_APP_PATH}
  APPSAWAY_DATA_FOLDERS=$( ls ${APPSAWAY_APP_PATH} )

  iter=1
  List=$APPSAWAY_NODES_USERNAME_LIST
  set -- $List
  for node_ip in ${APPSAWAY_NODES_ADDR_LIST}
  do
    if [ "$node_ip" != "$APPSAWAY_CONSOLENODE_ADDR" ]; then
      username=$( eval echo "\$$iter")
      log "copying folder on node $node_ip.."
      log "command is: scp_to_node ${_DOCKER_ENV_FILE} ${username} ${node_ip} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}"
      scp_to_node ${_DOCKER_ENV_FILE} ${username} ${node_ip} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      log "copying yarp conf files on node $node_ip.."
      scp_to_node ${_YARP_CONFIG_FILES_PATH} ${username} ${node_ip} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      for folder in ${APPSAWAY_DATA_FOLDERS}
      do
        log "copying data folder $folder on node $node_ip.."
        scp_to_node ${APPSAWAY_APP_PATH}/${folder} ${username} ${node_ip} ${_APPSAWAY_APP_PATH_NOT_CONSOLE} 
      done
    fi
    iter=$((iter+1))
  done
}

find_docker_images()
{
  APPSAWAY_IMAGES_LIST=($APPSAWAY_IMAGES)
  APPSAWAY_VERSIONS_LIST=($APPSAWAY_VERSIONS)
  APPSAWAY_TAGS_LIST=($APPSAWAY_TAGS)
  REGISTRY_UP_FLAG=true
  registry_up=$(${_DOCKER_BIN} service ls | grep "*:5000->5000/tcp" | tr -d ' ') 
  if [ "$registry_up" == "" ]
  then     
    REGISTRY_UP_FLAG=false
    echo "Creating the local registry"
    ${_DOCKER_BIN} service create --constraint node.role==manager --name registry \
    --publish published=5000,target=5000 --replicas 1 registry:2 
  else
    return=$(${_DOCKER_BIN} service ls | grep "*:5000->5000/tcp")
    if [[ $return != "" ]]
    then
      return_list=($return)
      ${_DOCKER_BIN} service update ${return_list[0]}
    fi
  fi
  
  echo "Registry_up_flag: $REGISTRY_UP_FLAG"
  echo "export REGISTRY_UP_FLAG=$REGISTRY_UP_FLAG" >> ${HOME}/teamcode/appsAway/scripts/${_APPSAWAY_ENV_FILE}

  for index in "${!APPSAWAY_IMAGES_LIST[@]}"
  do
    if [[ ${APPSAWAY_VERSIONS_LIST[$index]} != "n/a" ]]
    then
      current_image=${APPSAWAY_IMAGES_LIST[$index]}:${APPSAWAY_VERSIONS_LIST[$index]}_${APPSAWAY_TAGS_LIST[$index]}
    else
      current_image=${APPSAWAY_IMAGES_LIST[$index]}:${APPSAWAY_TAGS_LIST[$index]}
    fi
    echo "Pulling image $current_image, this might take a few minutes..."
    result=$(${_DOCKER_BIN} pull --quiet $current_image &> /dev/null || true)
    if [[ $result != "" ]]
    then
      ${_DOCKER_BIN} tag $current_image ${APPSAWAY_CONSOLENODE_ADDR}:5000/$current_image
      log "Pushing $current_image into the local registry"
      ${_DOCKER_BIN} push ${APPSAWAY_CONSOLENODE_ADDR}:5000/$current_image
      APPSAWAY_REGISTRY_IMAGES="$APPSAWAY_REGISTRY_IMAGES ${APPSAWAY_CONSOLENODE_ADDR}:5000/${APPSAWAY_IMAGES_LIST[$index]}"
    else
      IMAGE_FOUND_LOCALLY=$(${_DOCKER_BIN} images --format "{{.Repository}}:{{.Tag}}" | grep $current_image) 
      if [[ $IMAGE_FOUND_LOCALLY != "" ]]  
      then
        ${_DOCKER_BIN} tag $current_image ${APPSAWAY_CONSOLENODE_ADDR}:5000/$current_image
        log "Pushing $current_image into the local registry"
        ${_DOCKER_BIN} push ${APPSAWAY_CONSOLENODE_ADDR}:5000/$current_image
        APPSAWAY_REGISTRY_IMAGES="$APPSAWAY_REGISTRY_IMAGES ${APPSAWAY_CONSOLENODE_ADDR}:5000/${APPSAWAY_IMAGES_LIST[$index]}" 
      else
        exit_err "Image $current_image was not found on DockerHub nor locally. Please be sure that the name is correct."
      fi
    fi
  done
  echo "export APPSAWAY_IMAGES=\"$APPSAWAY_REGISTRY_IMAGES\"" >> ${HOME}/teamcode/appsAway/scripts/appsAway_setEnvironment.local.sh
  source ${HOME}/teamcode/appsAway/scripts/appsAway_setEnvironment.local.sh
}

main()
{ 
  find_docker_images
  copy_yaml_files
  create_yarp_config_files
  create_env_file
  copy_yarp_files
}

parse_opt "$@"
init
main
fini
exit 0
