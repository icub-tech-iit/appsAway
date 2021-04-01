#!/bin/bash -e

# we first load the temporary environment file
source ./appsAway_setEnvironment.temp.sh

_APPSAWAY_ENV_FILE="appsAway_setEnvironment.local.sh"
_YARP_CONFIG_FILES_PATH="config_yarp"
_YARP_NAMESPACE="/root"
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
_HOSTNAME_LIST=""
_CWD=$(pwd)

print_defs ()
{
  echo "Default parameters are"
  echo " _SCRIPT_TEMPLATE_VERSION is $_SCRIPT_TEMPLATE_VERSION"
  echo " _SCRIPT_VERSION is $_SCRIPT_VERSION"
  echo " _APPSAWAY_ENV_FILE is $_APPSAWAY_ENV_FILE"
  echo " _YARP_CONFIG_FILES_PATH is $_YARP_CONFIG_FILES_PATH"
  echo " _YARP_NAMESPACE is $_YARP_NAMESPACE"
  echo " _SSH_BIN is $_SSH_BIN"
  echo " _SSH_PARAMS is $_SSH_PARAMS"
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
 log "$0 STARTED"
}

fini()
{
  log "$0 ENDED "
}

# This checks if it is the first run, in which case the setEnvironment script did not run yet
# if [ ! -f "${_APPSAWAY_ENV_FILE}" ]; then
#   exit_err "enviroment file ${_APPSAWAY_ENV_FILE} does not exists"
# fi
merge_environment()
{

  # first we create a temporary copy of the local environment
  if [ -f "appsAway_setEnvironment.local.sh" ]; then
    cat appsAway_setEnvironment.local.sh > temp_local_env.sh
  else
    cat appsAway_setEnvironment.temp.sh > temp_local_env.sh
  fi  

  _NUM_APPS=$( ps aux | grep -c ./appGUI )
  if (( $_NUM_APPS > 1 ))
  then
    log "an app was detected running in this setup, merging cluster definitions..."
    #an app is already running, so we need to merge the environment
    echo '#! /bin/bash' >appsAway_setEnvironment.local.sh
    cat appsAway_setEnvironment.temp.sh | grep "ROBOT_NAME=" >>appsAway_setEnvironment.local.sh
    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_APP_NAME=" >>appsAway_setEnvironment.local.sh
    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_USER_NAME=" >>appsAway_setEnvironment.local.sh
    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_APP_PATH=" >>appsAway_setEnvironment.local.sh
    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_CONSOLENODE_ADDR=" >>appsAway_setEnvironment.local.sh
    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_CONSOLENODE_USERNAME=" >>appsAway_setEnvironment.local.sh
    #################################################################################
    # first we check if the GUI machine is already defined in the local environment #
    #################################################################################
    echo "checking for GUI"
    _GUI_EXISTS=$( echo "$( cat temp_local_env.sh | grep -c "APPSAWAY_GUINODE_ADDR=" )" )
    echo $_GUI_EXISTS
    if (( $_GUI_EXISTS > 0 ))
    then
      # if it was already defined, we keep this and discard the new
      cat temp_local_env.sh | grep "APPSAWAY_GUINODE_ADDR=" >>appsAway_setEnvironment.local.sh
      cat temp_local_env.sh | grep "APPSAWAY_GUINODE_USERNAME=" >>appsAway_setEnvironment.local.sh
    else
      # if it was not defined, we check if it is defined in the new environment (temp)
      _GUI_EXISTS=$( echo "$( cat appsAway_setEnvironment.temp.sh | grep -c "APPSAWAY_GUINODE_ADDR=" )" )
      if (( $_GUI_EXISTS > 0 ))
      then
        # if it is defined in the new environment, and not in the old, we use the new definition
        cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_GUINODE_ADDR=" >>appsAway_setEnvironment.local.sh
        cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_GUINODE_USERNAME=" >>appsAway_setEnvironment.local.sh
      fi
    fi
    #################################################################################
    # then we check if the HEAD machine is already defined in the local environment #
    #################################################################################
    _HEAD_EXISTS=$( echo "$( cat temp_local_env.sh | grep -c "APPSAWAY_ICUBHEADNODE_ADDR=" )" )
    if (( $_HEAD_EXISTS > 0 ))
    then
      # if it was already defined, we keep this and discard the new
      cat temp_local_env.sh | grep "APPSAWAY_ICUBHEADNODE_ADDR=" >>appsAway_setEnvironment.local.sh
      cat temp_local_env.sh | grep "APPSAWAY_ICUBHEADNODE_USERNAME=" >>appsAway_setEnvironment.local.sh
    else
      # if it was not defined, we check if it is defined in the new environment (temp)
      _HEAD_EXISTS=$( echo "$( cat appsAway_setEnvironment.temp.sh | grep -c "APPSAWAY_ICUBHEADNODE_ADDR=" )" )
      if (( $_HEAD_EXISTS > 0 ))
      then
        # if it is defined in the new environment, and not in the old, we use the new definition
        cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_ICUBHEADNODE_ADDR=" >>appsAway_setEnvironment.local.sh
        cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_ICUBHEADNODE_USERNAME=" >>appsAway_setEnvironment.local.sh
      fi
    fi
    ###############################################################################
    # here we edit the lists of everything, using the same iterator (single loop) #
    ###############################################################################
    _IMAGE_LIST_LOCAL=( $( cat temp_local_env.sh | sed -nr 's/.* APPSAWAY_IMAGES="(.*)".*/\1/p' ) )
    _IMAGE_LIST_NEW=( $( cat appsAway_setEnvironment.temp.sh | sed -nr 's/.* APPSAWAY_IMAGES="(.*)".*/\1/p' ) )
    _VERSIONS_LIST_LOCAL=( $( cat temp_local_env.sh | sed -nr 's/.* APPSAWAY_VERSIONS="(.*)".*/\1/p' ) )
    _VERSIONS_LIST_NEW=( $( cat appsAway_setEnvironment.temp.sh | sed -nr 's/.* APPSAWAY_VERSIONS="(.*)".*/\1/p' ) )
    _YARP_VERSIONS_LIST_LOCAL=( $( cat temp_local_env.sh | sed -nr 's/.* APPSAWAY_YARP_VERSIONS="(.*)".*/\1/p' ) )
    _YARP_VERSIONS_LIST_NEW=( $( cat appsAway_setEnvironment.temp.sh | sed -nr 's/.* APPSAWAY_YARP_VERSIONS="(.*)".*/\1/p' ) )
    _ICUB_FIRMWARE_LIST_LOCAL=( $( cat temp_local_env.sh | sed -nr 's/.* APPSAWAY_ICUB_FIRMWARE_SHARED_VERSION="(.*)".*/\1/p' ) )
    _ICUB_FIRMWARE_LIST_NEW=( $( cat appsAway_setEnvironment.temp.sh | sed -nr 's/.* APPSAWAY_ICUB_FIRMWARE_SHARED_VERSION="(.*)".*/\1/p' ) )
    _TAGS_LIST_LOCAL=( $( cat temp_local_env.sh | sed -nr 's/.* APPSAWAY_TAGS="(.*)".*/\1/p' ) )
    _TAGS_LIST_NEW=( $( cat appsAway_setEnvironment.temp.sh | sed -nr 's/.* APPSAWAY_TAGS="(.*)".*/\1/p' ) )
    # IT IS CRASHING HERE, NEED TO FIX TODO TODO TODO
    for image_index in "${!_IMAGE_LIST_NEW[@]}"
    do
      _IMAGE_PRESENT=false
      echo "new image: ${_IMAGE_LIST_NEW[$image_index]}"
      # we do chained loops because we want to test the exact image names
      for image_local in ${!_IMAGE_LIST_LOCAL[@]}
      do
        echo "local image: ${_IMAGE_LIST_LOCAL[$image_local]}"
        if [[ "${_IMAGE_LIST_LOCAL[$image_local]}" == "${_IMAGE_LIST_NEW[$image_index]}" ]]
        then
          # if it is present, we set the flag to true
          echo "checking image ${_IMAGE_LIST_NEW[$image_index]}"
          _IMAGE_PRESENT=true
        fi
      done
      echo "status: $_IMAGE_PRESENT"
      if [[ $_IMAGE_PRESENT == "false" ]]
      then
        echo "was not present"
        _IMAGE_LIST_LOCAL+=(${_IMAGE_LIST_NEW[$image_index]})
        _VERSIONS_LIST_LOCAL+=(${_VERSIONS_LIST_NEW[$image_index]})
        _YARP_VERSIONS_LIST_LOCAL+=(${_YARP_VERSIONS_LIST_NEW[$image_index]})
        _ICUB_FIRMWARE_LIST_LOCAL+=(${_ICUB_FIRMWARE_LIST_NEW[$image_index]})
        _TAGS_LIST_LOCAL+=(${_TAGS_LIST_NEW[$image_index]})
      fi    
      iter=$((iter+1))
    done
    echo "export APPSAWAY_IMAGES=\"${_IMAGE_LIST_LOCAL[@]}\"" >>appsAway_setEnvironment.local.sh
    echo "export APPSAWAY_VERSIONS=\"${_VERSIONS_LIST_LOCAL[@]}\"" >>appsAway_setEnvironment.local.sh
    echo "export APPSAWAY_YARP_VERSIONS=\"${_YARP_VERSIONS_LIST_LOCAL[@]}\"" >>appsAway_setEnvironment.local.sh
    echo "export APPSAWAY_ICUB_FIRMWARE=\"${_ICUB_FIRMWARE_LIST_LOCAL[@]}\"" >>appsAway_setEnvironment.local.sh
    echo "export APPSAWAY_TAGS=\"${_TAGS_LIST_LOCAL[@]}\"" >>appsAway_setEnvironment.local.sh

    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_DEPLOY_YAML_FILE_LIST=" >>appsAway_setEnvironment.local.sh
    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_GUI_YAML_FILE_LIST=" >>appsAway_setEnvironment.local.sh
    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_HEAD_YAML_FILE_LIST=" >>appsAway_setEnvironment.local.sh

    # if a stack is already created, we want to add to the old stack, not create a new
    cat temp_local_env.sh | grep "APPSAWAY_STACK_NAME=" >>appsAway_setEnvironment.local.sh

    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_NODES_ADDR_LIST=" >>appsAway_setEnvironment.local.sh
    cat appsAway_setEnvironment.temp.sh | grep "APPSAWAY_NODES_USERNAME_LIST=" >>appsAway_setEnvironment.local.sh
  else
    log "no app detected running on the system, initializing..."
    # if there is no app running, we just overwrite the local environment file
    mv appsAway_setEnvironment.temp.sh appsAway_setEnvironment.local.sh
  fi

  yarpResource=$(yarp resource --context cameraCalibration --from icubEyes.ini)
  resourcePath=$(echo "$yarpResource" | awk -F'"' '{print $2}' | awk -F'icubEyes.ini' '{print $1}')
  echo "export APPSAWAY_CALIB_CONTEXT=$resourcePath" >>appsAway_setEnvironment.local.sh
  
  yarpResource=$(yarp resource --context demoRedBall --from config.ini)
  resourcePath=$(echo "$yarpResource" | awk -F'"' '{print $2}' | awk -F'config.ini' '{print $1}')
  echo "export APPSAWAY_DEMOREDBALL_CONTEXT=$resourcePath" >>appsAway_setEnvironment.local.sh
}


main()
{
  merge_environment
}

parse_opt "$@"
init
main
fini
exit 0

