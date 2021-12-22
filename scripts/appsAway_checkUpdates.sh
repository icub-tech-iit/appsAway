#!/bin/bash -e



_APPSAWAY_ENV_FILE="appsAway_setEnvironment.local.sh"
######################################################

_SSH_CHECK_UPD="/usr/lib/update-notifier/apt-check -p"


source ${_APPSAWAY_ENV_FILE}
##################### IT PRINTS TO STDERR!!!!!! #############################
#OUTPUT=$($_SSH_CHECK_UPD 2>&1)
#############################################################################

#$_SSH_CHECK_UPD 2>&1 | grep '-'

iter=1
List=$APPSAWAY_NODES_USERNAME_LIST
set -- $List
for p in ${APPSAWAY_NODES_ADDR_LIST}
do
    if [[ -n "$p" ]] ; then

        username=$( eval echo "\$$iter")
        _OUTPUT=$(ssh -T $username@$p "${_SSH_CHECK_UPD}" 2>&1 | grep 'docker' || true)
        if [[ ! $_OUTPUT = "" ]] ; then
          echo "true"
          exit 0
        fi
    fi
iter=$((iter+1))
done
echo "false"
