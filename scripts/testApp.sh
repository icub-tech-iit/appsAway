#! /bin/bash
# Getting the lines containing failed containers
failed_containers=$(docker ps -a --filter 'exited=1'| grep -i $1)
failed_containers+=$(docker ps -a --filter 'exited=1'| grep -i $2)
# Getting the name of failed containers
container_names=($(echo $failed_containers | tr ' ' '\n' | grep -i $1) $(echo $failed_containers | tr ' ' '\n' | grep -i $2))
filtered_container_names=(${container_names[@]/*[cC]onnect/})
for i in "${filtered_container_names[@]}"
do
    echo "Fetching logs from container name: $i" 
    docker logs $i 
done
if [[ ${#filtered_container_names[@]} != 0 ]]
then
    exit 1
fi


