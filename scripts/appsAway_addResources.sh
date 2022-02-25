#!/bin/bash -e

# we first load the temporary environment file
source ./appsAway_setEnvironment.temp.sh > /dev/null 2>&1

_APPSAWAY_ENV_FILE="appsAway_setEnvironment.local.sh"
_YARP_CONFIG_FILES_PATH="config_yarp"
_YARP_NAMESPACE="/root"
_YARP_BIN=$(which yarp || true)
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

add_resources()
{
  # moving the temp.sh to local.sh
  mv appsAway_setEnvironment.temp.sh appsAway_setEnvironment.local.sh

  log "replacing localhost with its ip..."
  sed -i 's/export APPSAWAY_CONSOLENODE_ADDR=localhost/export APPSAWAY_CONSOLENODE_ADDR='$(hostname -I | awk '{print $1}')'/g' appsAway_setEnvironment.local.sh

  # handling yarp resources
  if [ "${_YARP_BIN}" != "" ] 
  then
    resourcePath=$(echo "$(yarp resource --context cameraCalibration --from icubEyes.ini 2> /dev/null)" | awk -F'"' '{print $2}' | awk -F'icubEyes.ini' '{print $1}')
    resourcePathClean="$(echo -e "${resourcePath}" | tr -d '[:space:]')"
    echo "export APPSAWAY_CALIB_CONTEXT=$resourcePathClean" >>appsAway_setEnvironment.local.sh

    resourcePath=$(echo "$(yarp resource --context demoRedBall --from config.ini 2> /dev/null)" | awk -F'"' '{print $2}' | awk -F'config.ini' '{print $1}')
    resourcePathClean="$(echo -e "${resourcePath}" | tr -d '[:space:]')"
    echo "export APPSAWAY_DEMOREDBALL_CONTEXT=$resourcePathClean" >>appsAway_setEnvironment.local.sh
  else
    log "yarp binary not found, cameraCalibration and demoRedBall contexts will not be set"
  fi
}

main()
{
  add_resources
}

parse_opt "$@"
init
main
fini
exit 0

