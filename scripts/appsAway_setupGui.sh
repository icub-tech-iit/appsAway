#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_setupRegistry.sh
#
# DESCRIPTION: set up the local registry 
#
# NOTE: the node where this script is executed is selected as swarm master
#
# AUTHOR : Alexandre Antunes / Vadim Tikhanoff
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
_DOCKER_COMPOSE_BIN_CONSOLE=$(which docker-compose || true)
_APPSAWAY_ENV_FILE="appsAway_setEnvironment.local.sh"
# ##############################################################################
print_defs ()
{
  echo "Default parameters are"
  echo " _SCRIPT_TEMPLATE_VERSION is $_SCRIPT_TEMPLATE_VERSION"
  echo " _SCRIPT_VERSION is $_SCRIPT_VERSION"
  echo " _APPSAWAY_ENV_FILE is $_APPSAWAY_ENV_FILE"
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
 if [ ! -f "${_APPSAWAY_ENV_FILE}" ]; then
   exit_err "enviroment file ${_APPSAWAY_ENV_FILE} does not exist"
 fi
 source ${_APPSAWAY_ENV_FILE}
 log "$0 STARTED"
}

fini()
{
  log "$0 ENDED "
}

check_gui()
{
  if [[ -p "mypipe" ]]; then
    rm mypipe
  fi
  if [[ -p "mypipe_to_gui" ]]; then
    rm mypipe_to_gui
  fi
  mkfifo mypipe
  mkfifo mypipe_to_gui
  # HERE THERE BE DOCKER-COMPOSE UP
  ${_DOCKER_COMPOSE_BIN_CONSOLE} -f appsAway_guiLaunch.yml pull
  ${_DOCKER_COMPOSE_BIN_CONSOLE} -f appsAway_guiLaunch.yml up --detach
  while true
  do
    eval "$(cat mypipe)"
  done
  rm mypipe
  rm mypipe_to_gui
}

main()
{ 
  check_gui
}

parse_opt "$@"
init
main
fini
exit 0
