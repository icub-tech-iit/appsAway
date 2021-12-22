#! /bin/bash

source ../appsAway_setEnvironment.local.sh

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
        _IS_CUDA=$( echo "${nodes_name_array[$i]}" | grep "icubcuda" )
        if [[ $_IS_CUDA != "" ]] ; then
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
