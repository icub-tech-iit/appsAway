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

scp_to_node()
{
  file_to_send=$1
  username_to_receive=$2
  ip_to_receive=$3
  path_to_receive=$4
  full_path_to_receive=${_OS_HOME_DIR}/${username_to_receive}/${path_to_receive}
  ${_SCP_BIN} ${_SCP_PARAMS_DIR} ${file_to_send} ${username_to_receive}@${ip_to_receive}:${full_path_to_receive}/
}

#swarm_start()
#{
#  _SWARM_INIT_COMMAND=$( ${_DOCKER_BIN} ${_DOCKER_PARAMS} swarm init --advertise-addr ${APPSAWAY_CONSOLENODE_ADDR} | egrep -i '^\s{4}')
#  if [ "$_SWARM_INIT_COMMAND" == "" ]; then
#    error "swarm init command string is empty (failed swarm initialization?)"
#  fi
#
#  iter=1
#  List=$APPSAWAY_NODES_USERNAME_LIST
#  set -- $List
#  for node_ip in ${APPSAWAY_NODES_ADDR_LIST}
#  do
#    if [ "$node_ip" != "$APPSAWAY_CONSOLENODE_ADDR" ]; then
#      username=$( eval echo "\$$iter")
#      log "running init on node $node_ip.."
#      run_via_ssh $username $node_ip "$_SWARM_INIT_COMMAND"
#    fi
#    iter=$((iter+1))
#  done
#}

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
	  _hostname=$(ip2hostname $username $_ip_addr)
	  if [ "$_hostname" == "" ]; then
		  exit_err "unable to get hostname from IP $_ip_addr"
	  fi
      _HOSTNAME_LIST="$_hostname $_HOSTNAME_LIST"
    iter=$((iter+1))
  done
}

#set_hardware_labels()
#{
#  log "setting labels on hardware-dependant nodes.."
#  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
#    ${_DOCKER_BIN} ${_DOCKER_PARAMS} node update --label-add type=head $(ip2hostname $APPSAWAY_ICUBHEADNODE_USERNAME $APPSAWAY_ICUBHEADNODE_ADDR)
#  fi

#  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
#    ${_DOCKER_BIN} ${_DOCKER_PARAMS} node update --label-add type=gui $(ip2hostname $APPSAWAY_GUINODE_USERNAME $APPSAWAY_GUINODE_ADDR)
#  fi
#}

#create_yarp_config_files()
#{
#  if [ -d "${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}" ]; then
#    warn "path ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH} already existing, overwriting files "
#  else
#    mkdir -p ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}
#  fi
#  log "creating YARP config files in path ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}"
#  echo "$_YARP_NAMESPACE" > ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}/yarp_namespace.conf
#  echo "$APPSAWAY_CONSOLENODE_ADDR 10000 yarp" > ${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}/yarp.conf
#}

#create_env_file()
#{
#  if [ -f "${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}" ]; then
#    warn "YARP docker environment file ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE} already existing, overwriting "
#  else
#    log "creating YARP docker environment file ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}"
#  fi
#  echo "USER_NAME=$APPSAWAY_USER_NAME" >> ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}
#  echo "USER_PASSWORD=$APPSAWAY_USER_PASSWORD" >> ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}
#  echo "MASTER_ADDR=$APPSAWAY_CONSOLENODE_ADDR" >> ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}
#  echo "YARP_CONF_PATH=${APPSAWAY_APP_PATH}/${_YARP_CONFIG_FILES_PATH}" >> ${APPSAWAY_APP_PATH}/${_DOCKER_ENV_FILE}
  
#}

overwrite_yaml_files()
{
  yml_files_default=("main.yml" "composeGui.yml" "composeHead.yml")
  yml_files_default_len=${#yml_files_default[@]}
  yml_files=()
  
  for (( i=0; i<$yml_files_default_len; i++ ))
  do
      echo "files are: ${APPSAWAY_APP_PATH}/${yml_files_default[$i]}"    
      if [ -f "${APPSAWAY_APP_PATH}/${yml_files_default[$i]}" ]
      then
          yml_files+=("${APPSAWAY_APP_PATH}/${yml_files_default[$i]}")
      fi
  done
  for (( i=0; i<${#yml_files[@]}; i++ ))
  do
      if [[ $APPSAWAY_IMAGES != '' ]] 
      then
          list_images=($APPSAWAY_IMAGES)
          list_versions=($APPSAWAY_VERSIONS)
          list_tags=($APPSAWAY_TAGS)
      
          if [[ $LOCAL_IMAGE_FLAG == true ]]
          then
              echo "overwriting ${APPSAWAY_CONSOLENODE_ADDR}:5000/${LOCAL_IMAGE_NAME} in ${yml_files[$i]}" 
              sed -i 's,image: .*$,image: '"${APPSAWAY_CONSOLENODE_ADDR}:5000/${LOCAL_IMAGE_NAME}"',g' ${yml_files[$i]}
          else
              for (( j=0; j<${#list_images[@]}; j++ ))
              do
                  echo "overwriting ${list_images[$j]} in ${yml_files[$i]}" 
                  sed -i 's,image: '"${list_images[$j]}"'.*$,image: '"${list_images[$j]}"':'"${list_versions[$j]}"'_'"${list_tags[$j]}"',g' ${yml_files[$i]}
              done
          fi    
      fi

      if [[ $APPSAWAY_SENSORS != '' ]] 
      then
          list_sensors=($APPSAWAY_SENSORS)
          echo "${yml_files[$i]}"
          if [ ${yml_files[$i]} == "composeHead.yml" ]
          then
            look_for_devices=false
            append_sensors=false
            list_devices=()
            while read -r line || [ -n "$line" ]
            do
                device_result=$(echo $line | grep "devices")
             
                if [[ $look_for_devices == true ]]
                then
                    if [[ $line == -* || $line == \#* ]]
                    then
                        if [[ $line == -* ]]
                        then
                            device=$(echo $line | awk -F':' '{print $1}' | tr -d '"' | sed 's/-//' | tr -d ' ' )
                            echo "Device: $device"
                            devices_list="$devices_list $device"
                            echo "Device list: $devices_list"
                        fi
                    else
                        echo $line
                        look_for_devices=false
                        append_sensors=true
                    fi
                fi
                if [[ $append_sensors == true ]]
                then
                    devices_list=${devices_list:1}
                    devices_list=($devices_list)
                    echo "Device list: ${devices_list[@]}"
                    for sens in "${list_sensors[@]}"
                    do
                        if [[ ! "${devices_list[@]}" =~ "$sens" ]]
                        then
                            echo "The sensor is NOT in the device list"
                            sensors_to_add="$sensors_to_add $sens"
                        fi
                    done  
                    sensors_to_add=${sensors_to_add:1}
                    sensors_to_add=($sensors_to_add)
                    echo "sensors to add: ${sensors_to_add[@]}"
                    for sens_to_add in "${sensors_to_add[@]}"
                    do
                      sed -i 's,'"${line}"'.*$,'"    - \"${sens_to_add}"':'"${sens_to_add}\"\n  ${line}"',g' ${yml_files[$i]}    
                    done   
                    append_sensors=false
                    sensors_to_add=""
                    devices_list=""
                fi
                if [[ "$device_result" != "" &&  "$line" != \#* ]]
                then                   
                    look_for_devices=true   
                    echo "Device result: $device_result"                
                fi            
            done < ${yml_files[$i]}
          fi
      fi
  done  
}

copy_yaml_files()
{
  log "creating path ${APPSAWAY_APP_PATH} on master node (this)"
  mkdir -p ${APPSAWAY_APP_PATH}
  echo "yml files: ${APPSAWAY_DEPLOY_YAML_FILE_LIST}"
  for file in ${APPSAWAY_DEPLOY_YAML_FILE_LIST}
  do
    if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
      log "copying yaml file $file to master node (this)"
      cp ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_APP_PATH}/
    fi
  done
  log "modifying yaml file $file on master node (this)"
  echo "gui files: ${APPSAWAY_GUI_YAML_FILE_LIST}"
  for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
  do
    if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
      log "copying yaml file $file to master node (this)"
      cp ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_APP_PATH}/
    fi
  done
  log "modifying yaml file $file on master node (this)"
  echo "head files: ${APPSAWAY_HEAD_YAML_FILE_LIST}"
  for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
  do
    if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
      log "copying yaml file $file to master node (this)"
      cp ../demos/${APPSAWAY_APP_NAME}/${file} ${APPSAWAY_APP_PATH}/
    fi
  done
  log "modifying yaml files"
  overwrite_yaml_files
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
      cp -R ${APPSAWAY_APP_PATH}/${folder} ${APPSAWAY_APP_PATH}/
    fi
  done
  if [ "$APPSAWAY_ICUBHEADNODE_ADDR" != "" ]; then
    head_path=${_OS_HOME_DIR}/${APPSAWAY_ICUBHEADNODE_USERNAME}/${_APPSAWAY_APP_PATH_NOT_CONSOLE}
    log "creating path ${head_path} on node with IP ${APPSAWAY_ICUBHEADNODE_ADDR}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_ICUBHEADNODE_USERNAME}@${APPSAWAY_ICUBHEADNODE_ADDR} "mkdir -p ${head_path}"
    for file in ${APPSAWAY_HEAD_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP ${APPSAWAY_ICUBHEADNODE_ADDR}"
        scp_to_node ${APPSAWAY_APP_PATH}/${file} ${APPSAWAY_ICUBHEADNODE_USERNAME} ${APPSAWAY_ICUBHEADNODE_ADDR} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  fi

  if [ "$APPSAWAY_GUINODE_ADDR" != "" ]; then
    gui_path=${_OS_HOME_DIR}/${APPSAWAY_GUINODE_USERNAME}/${_APPSAWAY_APP_PATH_NOT_CONSOLE}
    log "creating path ${gui_path} on node with IP ${APPSAWAY_GUINODE_ADDR}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_GUINODE_USERNAME}@${APPSAWAY_GUINODE_ADDR} "mkdir -p ${gui_path}"
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP ${APPSAWAY_GUINODE_ADDR}"
        scp_to_node ${APPSAWAY_APP_PATH}/${file} ${APPSAWAY_GUINODE_USERNAME} ${APPSAWAY_GUINODE_ADDR} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  elif [ "$APPSAWAY_GUINODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    log "creating path ${APPSAWAY_APP_PATH} on node with IP ${APPSAWAY_CONSOLENODE_ADDR}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_CONSOLENODE_USERNAME}@${APPSAWAY_CONSOLENODE_ADDR} "mkdir -p ${APPSAWAY_APP_PATH}"
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP ${APPSAWAY_CONSOLENODE_ADDR}"
        scp_to_node ${APPSAWAY_APP_PATH}/${file} ${APPSAWAY_CONSOLENODE_USERNAME} ${APPSAWAY_CONSOLENODE_ADDR} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  fi

  if [ "$APPSAWAY_WORKERNODE_ADDR" != "" ]; then
    iter=1
    List=$APPSAWAY_WORKERNODE_USERNAME
    set -- $List
    for worker_ip in ${APPSAWAY_WORKERNODE_ADDR}
    do
      worker_username=$( eval echo "\$$iter")
      worker_path=${_OS_HOME_DIR}/${worker_username}/${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      log "creating path ${worker_path} on node with IP $worker_ip"
      ${_SSH_BIN} ${_SSH_PARAMS} ${worker_username}@${worker_ip} "mkdir -p ${worker_path}"
      for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
      do
        if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
          log "copying yaml file $file to node with IP $worker_ip"
          scp_to_node ${APPSAWAY_APP_PATH}/${file} ${worker_username} ${worker_ip} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
        fi
      done
    done
  elif [ "$APPSAWAY_WORKERNODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    log "creating path ${APPSAWAY_APP_PATH} on node with IP ${APPSAWAY_CONSOLENODE_ADDR}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_CONSOLENODE_USERNAME}@${APPSAWAY_CONSOLENODE_ADDR} "mkdir -p ${APPSAWAY_APP_PATH}"
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP ${APPSAWAY_CONSOLENODE_ADDR}"
        scp_to_node ${APPSAWAY_APP_PATH}/${file} ${APPSAWAY_CONSOLENODE_USERNAME} ${APPSAWAY_CONSOLENODE_ADDR} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  fi

  if [ "$APPSAWAY_CUDANODE_ADDR" != "" ]; then
    iter=1
    List=$APPSAWAY_CUDANODE_USERNAME
    set -- $List
    for cuda_ip in ${APPSAWAY_CUDANODE_ADDR}
    do
      cuda_username=$( eval echo "\$$iter")
      cuda_path=${_OS_HOME_DIR}/${cuda_username}/${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      log "creating path ${cuda_path} on node with IP ${cuda_ip}"
      ${_SSH_BIN} ${_SSH_PARAMS} ${cuda_username}@${cuda_ip} "mkdir -p ${cuda_path}"
      for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
      do
        if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
          log "copying yaml file $file to node with IP ${cuda_ip}"
          scp_to_node ${APPSAWAY_APP_PATH}/${file} ${cuda_username} ${cuda_ip} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
        fi
      done
    done
  elif [ "$APPSAWAY_CUDANODE_ADDR" == "" ] && [ "$APPSAWAY_CONSOLENODE_ADDR" != "" ]; then
    log "creating path ${APPSAWAY_APP_PATH} on node with IP ${APPSAWAY_CONSOLENODE_ADDR}"
    ${_SSH_BIN} ${_SSH_PARAMS} ${APPSAWAY_CONSOLENODE_USERNAME}@${APPSAWAY_CONSOLENODE_ADDR} "mkdir -p ${APPSAWAY_APP_PATH}"
    for file in ${APPSAWAY_GUI_YAML_FILE_LIST}
    do
      if [ -f "../demos/$APPSAWAY_APP_NAME/$file" ]; then
        log "copying yaml file $file to node with IP $APPSAWAY_CONSOLENODE_ADDR"
        scp_to_node ${APPSAWAY_APP_PATH}/${file} ${APPSAWAY_CONSOLENODE_USERNAME} ${APPSAWAY_CONSOLENODE_ADDR} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      fi
    done
  fi
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
      scp_to_node ${_DOCKER_ENV_FILE} ${username} ${node_ip} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      scp_to_node ${_YARP_CONFIG_FILES_PATH} ${username} ${node_ip} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      for folder in ${APPSAWAY_DATA_FOLDERS}
      do
        scp_to_node ${APPSAWAY_APP_PATH}/${folder} ${username} ${node_ip} ${_APPSAWAY_APP_PATH_NOT_CONSOLE}
      done
    fi
    iter=$((iter+1))
  done
}


main()
{
  fill_hostname_list
#  swarm_start
#  set_hardware_labels
  copy_yaml_files
#  create_yarp_config_files
#  create_env_file
  copy_yarp_files
}

parse_opt "$@"
init
main
fini
exit 0
