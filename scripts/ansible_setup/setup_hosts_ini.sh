#! /bin/bash

source ../appsAway_setEnvironment.local.sh

_SSH_BIN=$(which ssh || true)
_SSH_PARAMS="-T"

if [ "${_SSH_BIN}" == "" ]; then
    echo "ssh binary not found"
    exit 1
fi

if [ -f "hosts.ini" ]
then
    rm hosts.ini
fi

echo "[nodes:children]" >> ./hosts.ini

nodes_addr_array=($APPSAWAY_NODES_ADDR_LIST)
nodes_usr_array=($APPSAWAY_NODES_USERNAME_LIST)
nodes_name_array=($APPSAWAY_NODES_NAME_LIST)
nodes_len=${#nodes_addr_array[@]}
 
for (( i=0; i<$nodes_len; i++ )) 
do  
     echo "${nodes_name_array[$i]}" >> ./hosts.ini
done 
echo "" >> ./hosts.ini
if [[ $APPSAWAY_CUDANODE_ADDR != "" ]] ; then
    echo "[cuda:children]" >> ./hosts.ini
    for (( i=0; i<$nodes_len; i++ )) 
    do  
        username=${nodes_usr_array[$i]}
        node=${nodes_addr_array[$i]}
        _IS_CUDA=$( echo "${nodes_name_array[$i]}" | grep "icubcuda" )
        _HAS_GPU=$( ${_SSH_BIN} ${_SSH_PARAMS} $username@$node "lshw -C display" | grep NVIDIA || true)
        if [[ $_IS_CUDA != "" ]] || [[ $_HAS_GPU != "" ]]; then
            echo "${nodes_name_array[$i]}" >> ./hosts.ini
        fi
    done 
    echo "" >> ./hosts.ini
fi

# now we populate each node
for (( i=0; i<$nodes_len; i++ ))
do  
    echo "[${nodes_name_array[$i]}]
${nodes_name_array[$i]}_host ansible_host=${nodes_addr_array[$i]}

[${nodes_name_array[$i]}:vars]
ansible_ssh_user=\"${nodes_usr_array[$i]}\"
ansible_become_pass={{ ${nodes_name_array[$i]}_pass }}
ansible_console_host=${APPSAWAY_CONSOLENODE_ADDR}
" >> ./hosts.ini
done
