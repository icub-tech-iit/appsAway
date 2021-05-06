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

# now we populate each node
for (( i=0; i<$nodes_len; i++ ))
do  
     echo "[${nodes_name_array[$i]}]
${nodes_name_array[$i]}Laptop ansible_host=${nodes_addr_array[$i]}

[${nodes_name_array[$i]}:vars]
ansible_ssh_user=\"${nodes_usr_array[$i]}\"
ansible_become_pass={{ ${nodes_name_array[$i]}_pass }}
" >> ./hosts.ini
done








