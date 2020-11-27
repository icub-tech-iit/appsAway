#!/bin/bash -e
#set -x
# ##############################################################################
# SCRIPT NAME: appsAway_scriptRuner.sh
#
# DESCRIPTION: setup the docker cluster
#
# AUTHOR : Matteo Brunettini
#
# LATEST MODIFICATION DATE (YYYY-MM-DD) : 2019-11-20
#
_SCRIPT_VERSION="0.9"          # Sets version variable
#
_SCRIPT_TEMPLATE_VERSION="1.1.0" #
#
# ##############################################################################
# Defaults
# local variable name starts with "_"
_SCRIPT2RUN_FILE_NAME="worker.sh.iCubApps"
_EXIT_FILE_NAME="worker.exit.iCubApps"
_SLEEPTIME_SECONDS="3"
# ##############################################################################

print_defs ()
{
  echo "Default parameters are"
  echo " _SCRIPT_TEMPLATE_VERSION is $_SCRIPT_TEMPLATE_VERSION"
  echo " _SCRIPT_VERSION is $_SCRIPT_VERSION"
  echo " _SCRIPT2RUN_FILE_NAME is $_SCRIPT2RUN_FILE_NAME"
  echo " _SLEEPTIME_SECONDS is $_SLEEPTIME_SECONDS"
  echo " _EXIT_FILE_NAME is $_EXIT_FILE_NAME"
}

usage ()
{
  echo "SCRIPT DESCRIPTION"

  echo "Usage: $0 [options]"
  echo "options are :"

  echo "  -f FILENAME : watch for file FILENAME and execute it"
  echo "  -d : print defaults"
  echo "  -v : print version"
  echo "  -h : print this help"
}

log() {
  echo "$(date +%d-%m-%Y) - $(date +%H:%M:%S) : $1"
}

warn() {
  echo "$(date +%d-%m-%Y) - $(date +%H:%M:%S) WARNING : $1"
}

error() {
  echo "$(date +%d-%m-%Y) - $(date +%H:%M:%S) ERROR : $1"
}

exit_err () {
	error "$1"
	exit 1
}

print_version() {
  echo "Script version is $_SCRIPT_VERSION based of Template version $_SCRIPT_TEMPLATE_VERSION"
}

parse_opt() {
  while getopts hdvf: opt
  do
    case "$opt" in
    f)
      _SCRIPT2RUN_FILE_NAME="$OPTARG"
      ;;
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
}

fini()
{
  if [ -f "$_EXIT_FILE_NAME" ]; then
    rm "$_EXIT_FILE_NAME"
    if [ "$?" != "0" ]; then
      warn "unable to remove scritp file $_EXIT_FILE_NAME"
    fi
  fi
  if [ -f "$_SCRIPT2RUN_FILE_NAME" ]; then
    rm "$_SCRIPT2RUN_FILE_NAME"
    if [ "$?" != "0" ]; then
      warn "unable to remove scritp file $_SCRIPT2RUN_FILE_NAME"
    fi
  fi
  log "$0 ENDED "
}

main()
{
  _runloop="true"
  while [ "$_runloop" == "true" ]
  do
    if [ -f "$_SCRIPT2RUN_FILE_NAME" ]; then
      log "script file $_SCRIPT2RUN_FILE_NAME found, runnning.."
      bash "$_SCRIPT2RUN_FILE_NAME"
      #if [ "$?" != "0" ]; then
      #  warn "script $_SCRIPT2RUN_FILE_NAME exited with error $?"
      #else
      #  log " script $_SCRIPT2RUN_FILE_NAME ended"
      #fi
      log "sleeping for $_SLEEPTIME_SECONDS seconds"
      sleep "$_SLEEPTIME_SECONDS"
      rm "$_SCRIPT2RUN_FILE_NAME"
      if [ "$?" != "0" ]; then
        warn "unable to remove scritp file $_SCRIPT2RUN_FILE_NAME"
      fi
    else
      #log "sleeping for $_SLEEPTIME_SECONDS seconds"
      sleep "$_SLEEPTIME_SECONDS"
    fi
    if [ -f "$_EXIT_FILE_NAME" ]; then
      log " exit file $_EXIT_FILE_NAME found, exiting.."
      _runloop="false"
    fi
  done
}

parse_opt "$@"
init
main
fini
exit 0
