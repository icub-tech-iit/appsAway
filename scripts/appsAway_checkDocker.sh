#!/bin/bash -e



_APPSAWAY_ENV_FILE="appsAway_setEnvironment.local.sh"
######################################################

#_SSH_CHECK_UPD="/usr/lib/update-notifier/apt-check -p"

##################### IT PRINTS TO STDERR!!!!!! #############################
#OUTPUT=$($_SSH_CHECK_UPD 2>&1)
#############################################################################

#$_SSH_CHECK_UPD 2>&1 | grep '-'

_DOCKER_COMPOSE_ADDR_LIST=""
_DOCKER_COMPOSE_USERNAMES_LIST=""
_DOCKER_COMPOSE_NAMES_LIST=""
_DOCKER_ADDR_LIST=""
_DOCKER_USERNAMES_LIST=""
_DOCKER_NAMES_LIST=""
_CUDA_ADDR_LIST=""
_CUDA_USERNAMES_LIST=""
_CUDA_NAMES_LIST=""

_SSH_BIN=$(which ssh || true)
_SSH_PARAMS="-T"


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

init()
{
 if [ "${_SSH_BIN}" == "" ]; then
   exit_err "ssh binary not found"
 fi
 if [ ! -f "${_APPSAWAY_ENV_FILE}" ]; then
   exit_err "enviroment file ${_APPSAWAY_ENV_FILE} does not exists"
 fi
 source ${_APPSAWAY_ENV_FILE}
 log "$0 STARTED"
}

fini()
{
  log "$0 ENDED "
}

check_docker_version() {
  nodes_addr_array=($APPSAWAY_NODES_ADDR_LIST)
  nodes_usr_array=($APPSAWAY_NODES_USERNAME_LIST)
  nodes_name_array=($APPSAWAY_NODES_NAME_LIST)
  iter=0
  List=($APPSAWAY_NODES_USERNAME_LIST)
  for node in ${APPSAWAY_NODES_ADDR_LIST}
  do
    if [[ -n "$node" ]] ; then
      username=${List[$iter]}
      _OUTPUT=$(${_SSH_BIN} ${_SSH_PARAMS} $username@$node "docker --version 2>&1" | grep 'Docker version' || true)
      if [[ $_OUTPUT != "" ]] ; then
        _OUTPUT_COMPOSE=$(${_SSH_BIN} ${_SSH_PARAMS} $username@$node "docker-compose --version 2>&1" | grep 'docker-compose version'  || true)
        if [[ $_OUTPUT_COMPOSE == "" ]] ; then
          # ADD THIS NODE TO THE HOSTS_COMPOSE.INI
          _DOCKER_COMPOSE_ADDR_LIST="$_DOCKER_COMPOSE_ADDR_LIST $node"
          _DOCKER_COMPOSE_USERNAMES_LIST="$_DOCKER_COMPOSE_USERNAMES_LIST $username"
          _DOCKER_COMPOSE_NAMES_LIST="$_DOCKER_COMPOSE_NAMES_LIST ${nodes_name_array[$iter]}"
        fi
      else
        # ADD THIS NODE TO THE HOSTS_DOCKER.INI
        _DOCKER_ADDR_LIST="$_DOCKER_ADDR_LIST $node"
        _DOCKER_USERNAMES_LIST="$_DOCKER_USERNAMES_LIST $username"
        _DOCKER_NAMES_LIST="$_DOCKER_NAMES_LIST ${nodes_name_array[$iter]}"
      fi
      _IS_CUDA=$( echo ${nodes_name_array[$iter]} | grep 'icubcuda' || true)
      _HAS_GPU=$( ${_SSH_BIN} ${_SSH_PARAMS} $username@$node "lshw -C display" | grep NVIDIA || true)
      if [[ $_IS_CUDA != "" ]] || [[ $_HAS_GPU != "" ]]; then
        _OUTPUT=$(${_SSH_BIN} ${_SSH_PARAMS} $username@$node "nvidia-docker --version 2>&1" | grep 'Docker version' || true)
        if [[ $_OUTPUT == "" ]] ; then
          # ADD THIS NODE TO THE HOSTS_CUDA.INI
          _CUDA_ADDR_LIST="$_CUDA_ADDR_LIST $node"
          _CUDA_USERNAMES_LIST="$_CUDA_USERNAMES_LIST $username"
          _CUDA_NAMES_LIST="$_DOCKER_NAMES_LIST ${nodes_name_array[$iter]}"
        fi
      fi
    fi
    iter=$((iter+1))
  done
}

populate_hosts() {
  if [[ $1 == "docker" ]] ; then
    file_name="hosts_docker.ini"
    addr_array=($_DOCKER_ADDR_LIST)
    usr_array=($_DOCKER_USERNAMES_LIST)
    name_array=($_DOCKER_NAMES_LIST)
  elif [[ $1 == "docker-compose" ]]; then
    file_name="hosts_compose.ini"
    addr_array=($_DOCKER_COMPOSE_ADDR_LIST)
    usr_array=($_DOCKER_COMPOSE_USERNAMES_LIST)
    name_array=($_DOCKER_COMPOSE_NAMES_LIST)
  elif [[ $1 == "cuda" ]]; then
    file_name="hosts_cuda.ini"
    addr_array=($_CUDA_ADDR_LIST)
    usr_array=($_CUDA_USERNAMES_LIST)
    name_array=($_CUDA_NAMES_LIST)
  fi
  array_len=${#addr_array[@]}

  cd ~/teamcode/appsAway/scripts/ansible_setup/

  if [ -f $file_name ]
  then
      rm $file_name
  fi

  if (( $array_len > 0 )) ; then

    echo "[nodes:children]" >> ./$file_name

    for (( i=0; i<$array_len; i++ )) 
    do  
        echo "${name_array[$i]}" >> ./$file_name
    done 
    echo "" >> ./$file_name
    if [[ $1 == "cuda" ]] ; then
      echo "[cuda:children]" >> ./$file_name
      for (( i=0; i<$array_len; i++ )) 
      do  
        _IS_CUDA=${name_array[$i]}
        if [[ $_IS_CUDA != "" ]] ; then
            echo "${name_array[$i]}" >> ./$file_name
        fi
      done 
      echo "" >> ./$file_name
    fi

    # now we populate each node
    for (( i=0; i<$array_len; i++ ))
    do  
      echo "[${name_array[$i]}]
      ${name_array[$i]}_host ansible_host=${addr_array[$i]}

      [${name_array[$i]}:vars]
      ansible_ssh_user=\"${usr_array[$i]}\"
      ansible_become_pass={{ ${name_array[$i]}_pass }}
      ansible_console_host=${APPSAWAY_CONSOLENODE_ADDR}
      " >> ./$file_name
    done
  fi
  cd ..
}

main() {
  check_docker_version
  populate_hosts docker
  populate_hosts docker-compose
  populate_hosts cuda
}

init
main
fini
exit 0
