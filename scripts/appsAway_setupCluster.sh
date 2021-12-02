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
_DOCKER_COMPOSE_BIN_CONSOLE=$(which docker-compose || true)

_YARPSERVER_DEFAULT_PORT="10000"
_YARPSERVER_DEFAULT_NAMESPACE="root"
if [ "$os" = "Darwin" ]
then
  _OS_HOME_DIR=/Users
else
  _OS_HOME_DIR=/home
fi

print_defs ()
{
  echo "Default parameters are"
  echo " _SCRIPT_TEMPLATE_VERSION is $_SCRIPT_TEMPLATE_VERSION"
  echo " _SCRIPT_VERSION is $_SCRIPT_VERSION"
  echo " _APPSAWAY_ENV_FILE is $_APPSAWAY_ENV_FILE"
  echo " _DOCKER_ENV_FILE is $_DOCKER_ENV_FILE"
  echo " _YARP_CONFIG_FILES_PATH is $_YARP_CONFIG_FILES_PATH"
  echo " _YARPSERVER_DEFAULT_PORT is $_YARPSERVER_DEFAULT_PORT"
  echo " _YARPSERVER_DEFAULT_NAMESPACE is $_YARPSERVER_DEFAULT_NAMESPACE"
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
 if [ "${_DOCKER_COMPOSE_BIN_CONSOLE}" == "" ]; then
   exit_err "docker-compose binary not found in the console node"
 fi
 if [ ! -f "${_APPSAWAY_ENV_FILE}" ]; then
   exit_err "enviroment file ${_APPSAWAY_ENV_FILE} does not exists"
 fi
 source ${_APPSAWAY_ENV_FILE}
 os=`uname -s`
 if [ "$os" = "Darwin" ]
 then
  _ALL_LOCAL_IP_ADDRESSES=$(arp -a | awk -F'[()]' '{print $2}')
# ' This brings color back to visual code :D
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




  #######################################################START
 # if [ "${_YARP_BIN}" != "" ] 
 # then
 #   log "Checking if YARP server is running..."
 #   _YARP_IP_FOUND=$( $_YARP_BIN where | echo "$( sed -nr 's/.*is available at ip (.*) port.*/\1/p' )" )
 #   _YARP_PORT_FOUND=$( $_YARP_BIN where | echo "$( sed -nr 's/.*at ip '"$_YARP_IP_FOUND"' port (.*).*/\1/p' )" )
 #   _YARP_NAMESPACE_FOUND=$( $_YARP_BIN where | echo "$( sed -nr 's/.*Name server \/(.*) is available.*/\1/p' )" )
 #   if [ "$_YARP_IP_FOUND" != "" ]
 #   then
 #     log "A yarp server was found with ip $_YARP_IP_FOUND port $_YARP_PORT_FOUND with namespace /$_YARP_NAMESPACE_FOUND"
 #     _YARP_IP_CONF=$_YARP_IP_FOUND
 #     _YARP_PORT_CONF=$_YARP_PORT_FOUND
 #     _YARP_NAMESPACE_CONF=$_YARP_NAMESPACE_FOUND
 #   else
 #     _YARP_IP_CONF=$APPSAWAY_CONSOLENODE_ADDR
 #     _YARP_PORT_CONF=$_YARPSERVER_DEFAULT_PORT
 #     _YARP_NAMESPACE_CONF=$( $_YARP_BIN namespace | echo "$( sed -nr 's/.*YARP namespace: \/(.*).*/\1/p' )" )
 #     log "server not found, it will be launched with the following settings: ${APPSAWAY_CONSOLENODE_ADDR} ${_YARPSERVER_DEFAULT_PORT} ${_YARP_NAMESPACE_CONF}"

 #     # _YARP_IP_USER contains the yarp server IP address configured in console machine
 #     _YARP_IP_USER=$( $_YARP_BIN where | echo "$( sed -nr 's/.*Looking for name server on (.*), port.*/\1/p' )" )
 #     _YARP_PORT_USER=$( $_YARP_BIN where | echo "$( sed -nr 's/.*Looking for name server on '"$_YARP_IP_FOUND"', port number (.*).*/\1/p' )" )
 #     if [ "$_YARP_IP_USER" == "" ] 
 #     then
 #       #in this case the user using a custom namespace without setting the _<usernamespace>.conf file.
 #       exit_err "Missing the file _$_YARP_NAMESPACE_FOUND.conf "
 #     else
 #       if [ "$_YARP_IP_USER" != "$APPSAWAY_CONSOLENODE_ADDR" ] || [ "$_YARP_PORT_USER" != "$_YARPSERVER_DEFAULT_PORT" ] 
 #       then
 #          warn "Yarp server IP address/port in configuration file of this machine mismatches with IP Address/port used in the deployment. Yarp server will run on ${_YARP_IP_CONF} $_YARPSERVER_DEFAULT_PORT"
 #       fi
 #     fi
 #   fi
 # else
 #   log "yarp binary not found, using default settings for yarp server"
 #   _YARP_IP_CONF=$APPSAWAY_CONSOLENODE_ADDR
 #   _YARP_PORT_CONF=$_YARPSERVER_DEFAULT_PORT
 #   _YARP_NAMESPACE_CONF="$_YARPSERVER_DEFAULT_NAMESPACE"
 # fi
#################################################### END



  log "Preparing yarp server configuration ..."
  if [ "${_YARP_BIN}" == "" ] 
  then
    #if yarp is not installed we use default configuartion : ip of console, port 10000 and namespace /root
    _YARP_IP_CONF=$APPSAWAY_CONSOLENODE_ADDR
    _YARP_PORT_CONF=$_YARPSERVER_DEFAULT_PORT
    _YARP_NAMESPACE_CONF="$_YARPSERVER_DEFAULT_NAMESPACE"
    log "yarp binary not found, using default settings for yarp server: ${_YARP_IP_CONF} ${_YARP_PORT_CONF} /${_YARP_NAMESPACE_CONF}"
  else
    #if yarp is installed we check if a yarp server is already running. In that case we want to use it and not deploy new one and each container should have the configuration to be able to communicate with the running server
    log "Checking if YARP server is running..."
    _YARP_IP_FOUND=$( $_YARP_BIN where | echo "$( sed -nr 's/.*is available at ip (.*) port.*/\1/p' )" )
    if [ "$_YARP_IP_FOUND" != "" ]
    then 
      # a yarp server is already running 
      _YARP_IP_CONF=$_YARP_IP_FOUND
      _YARP_PORT_CONF=$( $_YARP_BIN where | echo "$( sed -nr 's/.*at ip '"$_YARP_IP_FOUND"' port (.*).*/\1/p' )" )
      _YARP_NAMESPACE_CONF=$( $_YARP_BIN where | echo "$( sed -nr 's/.*Name server \/(.*) is available.*/\1/p' )" )
      log "A yarp server was found with ip $_YARP_IP_CONF port $_YARP_PORT_CONF with namespace /$_YARP_NAMESPACE_CONF"
    else
      # we deploy a yarp server on the same namespace of console, but with console ip address and on port 10000
      _YARP_NAMESPACE_CONF=$( $_YARP_BIN namespace | echo "$( sed -nr 's/.*YARP namespace: \/(.*).*/\1/p' )" )
      _YARP_IP_CONF=$APPSAWAY_CONSOLENODE_ADDR
      _YARP_PORT_CONF=$_YARPSERVER_DEFAULT_PORT

      #check if the the configured yarp server address (_YARP_IP_USER) is the same of console address. If not we advise the user
      _YARP_IP_USER=$( $_YARP_BIN where | echo "$( sed -nr 's/.*Looking for name server on (.*), port.*/\1/p' )" )
      if [ "$_YARP_IP_USER" != "$APPSAWAY_CONSOLENODE_ADDR" ] 
      then
        warn "Yarp server IP address in configuration file of this machine is missing or mismatches with IP Address used in the deployment. Yarp server will run on ${APPSAWAY_CONSOLENODE_ADDR} $_YARPSERVER_DEFAULT_PORT"
      fi
    fi
  fi
      















  log "creating YARP config files in path ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH} with namespace /$_YARP_NAMESPACE_CONF, ip $_YARP_IP_CONF in port $_YARP_PORT_CONF"
  
  if [ "${_YARP_NAMESPACE_CONF}" == "$_YARPSERVER_DEFAULT_NAMESPACE" ]
  then 
    echo "$_YARP_IP_CONF $_YARP_PORT_CONF yarp" > ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}/yarp.conf
  else
    echo "$_YARP_IP_CONF $_YARP_PORT_CONF yarp" > ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}/_${_YARP_NAMESPACE_CONF}.conf
    echo "/$_YARP_NAMESPACE_CONF" > ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}/yarp_namespace.conf
  fi
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
  echo "YARP_CONF_PATH=${APPSAWAY_APP_PATH_NOT_CONSOLE}/${_YARP_CONFIG_FILES_PATH}" >> ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}
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
    head_path=${_OS_HOME_DIR}/${APPSAWAY_ICUBHEADNODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE}
    log "creating path ${head_path} on node with IP ${APPSAWAY_ICUBHEADNODE_ADDR}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_ICUBHEADNODE_USERNAME}@${APPSAWAY_ICUBHEADNODE_ADDR} "mkdir -p ${head_path}"
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP $APPSAWAY_ICUBHEADNODE_ADDR"
        scp_to_node ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_ICUBHEADNODE_USERNAME} ${APPSAWAY_ICUBHEADNODE_ADDR} ${APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  fi

  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    gui_path=${_OS_HOME_DIR}/${APPSAWAY_GUINODE_USERNAME}/${APPSAWAY_APP_PATH_NOT_CONSOLE}
    log "creating path ${gui_path} on node with IP $APPSAWAY_GUINODE_ADDR"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_GUINODE_USERNAME}@${APPSAWAY_GUINODE_ADDR} "mkdir -p ${gui_path}"
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP $APPSAWAY_GUINODE_ADDR"
        scp_to_node ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_GUINODE_USERNAME} ${APPSAWAY_GUINODE_ADDR} ${APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  elif [ "$APPSAWAY_GUINODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    log "creating path ${APPSAWAY_APP_PATH} on node with IP $APPSAWAY_CONSOLENODE_ADDR"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_CONSOLENODE_USERNAME}@${APPSAWAY_CONSOLENODE_ADDR} "mkdir -p ${APPSAWAY_APP_PATH}"
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP $APPSAWAY_CONSOLENODE_ADDR"
        scp_to_node ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_CONSOLENODE_USERNAME} ${APPSAWAY_CONSOLENODE_ADDR} ${APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  fi
  _CUDA_NODE_LIST=( $APPSAWAY_CUDANODE_ADDR )
  _CUDA_USERNAME_LIST=( $APPSAWAY_CUDANODE_USERNAME )
  iter=0
  for node in ${_CUDA_NODE_LIST[@]}
  do
    log "creating path ${APPSAWAY_APP_PATH_NOT_CONSOLE} on CUDA node with IP ${_CUDA_NODE_LIST[iter]}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${_CUDA_USERNAME_LIST[iter]}@${_CUDA_NODE_LIST[iter]} "mkdir -p ${APPSAWAY_APP_PATH_NOT_CONSOLE}"
    iter=$((iter+1))
  done

  _WORKER_NODE_LIST=( $APPSAWAY_WORKERNODE_ADDR )
  _WORKER_USERNAME_LIST=( $APPSAWAY_WORKERNODE_USERNAME )
  iter=0
  for node in ${_WORKER_NODE_LIST[@]}
  do
    log "creating path ${APPSAWAY_APP_PATH_NOT_CONSOLE} on WORKER node with IP ${_WORKER_NODE_LIST[iter]}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${_WORKER_USERNAME_LIST[iter]}@${_WORKER_NODE_LIST[iter]} "mkdir -p ${APPSAWAY_APP_PATH_NOT_CONSOLE}"
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
      log "command is: scp_to_node ${_DOCKER_ENV_FILE} ${username} ${node_ip} ${APPSAWAY_APP_PATH_NOT_CONSOLE}"
      scp_to_node ${_DOCKER_ENV_FILE} ${username} ${node_ip} ${APPSAWAY_APP_PATH_NOT_CONSOLE}
      log "copying yarp conf files on node $node_ip.."
      scp_to_node ${_YARP_CONFIG_FILES_PATH} ${username} ${node_ip} ${APPSAWAY_APP_PATH_NOT_CONSOLE}
      for folder in ${APPSAWAY_DATA_FOLDERS}
      do
        log "copying data folder $folder on node $node_ip.."
        scp_to_node ${APPSAWAY_APP_PATH}/${folder} ${username} ${node_ip} ${APPSAWAY_APP_PATH_NOT_CONSOLE} 
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
  APPSAWAY_MANIFEST_FOUND_LIST=($APPSAWAY_MANIFEST_FOUND)
  APPSAWAY_NODES_NAME=($APPSAWAY_NODES_NAME_LIST)
  
  for index in "${!APPSAWAY_IMAGES_LIST[@]}"
  do
    if [[ ${APPSAWAY_VERSIONS_LIST[$index]} != "n/a" ]]
    then
      current_image=${APPSAWAY_IMAGES_LIST[$index]}:${APPSAWAY_VERSIONS_LIST[$index]}_${APPSAWAY_TAGS_LIST[$index]}
    else
      current_image=${APPSAWAY_IMAGES_LIST[$index]}:${APPSAWAY_TAGS_LIST[$index]}
    fi
#    if (( ${APPSAWAY_MANIFEST_FOUND_LIST[$index]} == 0 && ${#APPSAWAY_NODES_NAME[@]} > 1 )); then
    if (( ${APPSAWAY_MANIFEST_FOUND_LIST[$index]} == 0 )); then
      IMAGE_FOUND_LOCALLY=$(${_DOCKER_BIN} images --format "{{.Repository}}:{{.Tag}}" | grep $current_image || true) 
      if [[ $IMAGE_FOUND_LOCALLY != "" ]]  
      then
        log "Image found locally"
        if [[ ${#APPSAWAY_NODES_NAME[@]} > 1 ]]
        then
          ${_DOCKER_BIN} tag $current_image ${APPSAWAY_CONSOLENODE_ADDR}:5000/$current_image
          log "Pushing $current_image into the local registry, this might take a few minutes..."
          ${_DOCKER_BIN} push ${APPSAWAY_CONSOLENODE_ADDR}:5000/$current_image &> /dev/null &
          APPSAWAY_REGISTRY_IMAGES="$APPSAWAY_REGISTRY_IMAGES ${APPSAWAY_CONSOLENODE_ADDR}:5000/${APPSAWAY_IMAGES_LIST[$index]}" 
        else
          log "Skipping registry push since there is only one node in the cluster"
          APPSAWAY_REGISTRY_IMAGES="$APPSAWAY_REGISTRY_IMAGES ${APPSAWAY_IMAGES_LIST[$index]}" 
        fi
      else
        log "Image not found locally"
        exit_err "Image $current_image was not found on DockerHub nor locally. Please be sure that the name is correct."
      fi
    else
      APPSAWAY_REGISTRY_IMAGES="$APPSAWAY_REGISTRY_IMAGES ${APPSAWAY_IMAGES_LIST[$index]}" 
    fi
  done
  wait
  log "All images loaded successfully!"
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
