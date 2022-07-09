#! /bin/bash
# _NUM_APPS=$( ps aux | grep -c ./appGUI ) 
# if (( $_NUM_APPS > 1 )) 
# then 
#   echo -e "\033[1;33m$(date +%d-%m-%Y) - $(date +%H:%M:%S) WARNING : An application is already running in your machine, please make sure you close it before launching a new one.\033[0m" 
#   echo -e "\033[1;33m$(date +%d-%m-%Y) - $(date +%H:%M:%S) WARNING : If you stopped an old application but it is still hanging, run the following command: \033[0m" 
#   echo "" 
#   echo "cd $HOME/teamcode/appsAway/scripts && ./appsAway_cleanupCluster.sh all" 
#   echo "" 
#   exit 1 
# fi 
# if [ -d "appsAway" ] 
# then
#   rm -rf appsAway
# fi
#git clone --depth=1 --branch master https://github.com/gsisinna/appsAway.git --quiet 

cd ./appsAway/scripts
echo "#! /bin/bash
export ROBOT_NAME=iCubErzelli02
export APPSAWAY_APP_NAME=iCubTest
export APPSAWAY_USER_NAME=icub
export APPSAWAY_APP_PATH=\${HOME}/iCubApps/\${APPSAWAY_APP_NAME}
export APPSAWAY_APP_PATH_NOT_CONSOLE=iCubApps/\${APPSAWAY_APP_NAME}
export APPSAWAY_ICUBHEADNODE_ADDR=10.0.0.2
export APPSAWAY_ICUBHEADNODE_USERNAME=icub
export APPSAWAY_CONSOLENODE_ADDR=10.0.0.130
export APPSAWAY_CONSOLENODE_USERNAME=icub
export APPSAWAY_NODES_NAME_LIST=\"icubhead icubconsole\"
export APPSAWAY_YML_IMAGES=\"icubteamcode/superbuild-icubhead icubteamcode/superbuild-icubtest\"
export APPSAWAY_IMAGES=\"icubteamcode/superbuild-icubhead test_icubtest001\"
export APPSAWAY_VERSIONS=\"v2022.02.1 n/a\"
export APPSAWAY_YARP_VERSIONS=\"LATEST LATEST\"
export APPSAWAY_ICUB_FIRMWARE_SHARED_VERSION=\"LATEST LATEST\"
export APPSAWAY_TAGS=\"sources latest\"
export APPSAWAY_SENSORS=\"/dev/ttyUSB0\"
export APPSAWAY_GUI_YAML_FILE_LIST=composeGui.yml
export APPSAWAY_HEAD_YAML_FILE_LIST=composeHead.yml
export APPSAWAY_DEPLOY_YAML_FILE_LIST=main.yml
export APPSAWAY_STACK_NAME=mystack
export APPSAWAY_NODES_ADDR_LIST=\"\${APPSAWAY_ICUBHEADNODE_ADDR} \${APPSAWAY_CONSOLENODE_ADDR} \${APPSAWAY_GUINODE_ADDR} \${APPSAWAY_CUDANODE_ADDR} \${APPSAWAY_WORKERNODE_ADDR}\" 
export APPSAWAY_NODES_USERNAME_LIST=\"\${APPSAWAY_ICUBHEADNODE_USERNAME} \${APPSAWAY_CONSOLENODE_USERNAME} \${APPSAWAY_GUINODE_USERNAME} \${APPSAWAY_CUDANODE_USERNAME} \${APPSAWAY_WORKERNODE_USERNAME}\" " > ./appsAway_setEnvironment.temp.sh 
chmod +x appsAway_setEnvironment.temp.sh
./appsAway_addResources.sh
if [[ "$?" != "0" ]]
then
  exit 1
fi
echo "about to set environment variables..."
chmod +x appsAway_setEnvironment.local.sh
source ./appsAway_setEnvironment.local.sh
nodes_addr_array=($APPSAWAY_NODES_ADDR_LIST)
nodes_usr_array=($APPSAWAY_NODES_USERNAME_LIST)
nodes_name_array=($APPSAWAY_NODES_NAME_LIST)
nodes_len=${#nodes_addr_array[@]}
cd ansible_setup
vault_password=$$
echo "$vault_password" > vault_password_file.txt
echo "" > passwords.enc
for (( i=0; i<$nodes_len; i++ ))
do 
    is_correct=false
    while (! $is_correct); do
    echo "Please insert password of the ${nodes_name_array[$i]} node with username ${nodes_usr_array[$i]} and ip address ${nodes_addr_array[$i]}"
    read -p "Insert your password: " -s password
    echo ""
    if (ssh -oBatchMode=yes ${nodes_usr_array[$i]}@${nodes_addr_array[$i]} -C "cat ~/.ssh/authorized_keys" &> /dev/null)
    then
   	 echo "Passwordless authentication enabled."
    else
   	 echo "ERROR: you need to set up the passwordless ssh login for ${nodes_name_array[$i]} node with username ${nodes_usr_array[$i]} and ip address ${nodes_addr_array[$i]}."
      exit 0
    fi
    if (echo $password | ssh ${nodes_usr_array[$i]}@${nodes_addr_array[$i]} sudo -lS &> /dev/null)
    then
   	 is_correct=true
   	 echo "Correct password."
   	 ansible-vault encrypt_string --vault-password-file vault_password_file.txt $password --name "${nodes_name_array[$i]}_pass" >> passwords.enc
    else
   	 is_correct=false
   	 echo "Wrong password."
    fi
    password=""
    done
done
ansible_output=""
cd ~/teamcode/appsAway/scripts/
echo "Should we clean up Docker installation?"
read -p "[Y/N] (default No): " INSTALL
case $INSTALL in
Y|Y?|y|y?)
  cd ~/teamcode/appsAway/scripts/ansible_setup/
  ./setup_hosts_ini.sh
  echo "Installing docker and docker-compose with Ansible..."
  script -efq ansible_output.txt -c "make prepare_all"
  ansible_output=$(cat ansible_output.txt)
  rm ansible_output.txt
  echo "Done checking installation with Ansible..."
  ;;
*)
  echo "Checking if all machines have docker and docker-compose necessary for the deployment..."
  ./appsAway_checkDocker.sh
  cd ~/teamcode/appsAway/scripts/ansible_setup/
  if [ -f "hosts_docker.ini" ] ; then
    echo "Installing docker and docker-compose with Ansible in machines without docker..."
    script -efq ansible_output.txt -c "make prepare_docker"
    ansible_output=$(cat ansible_output.txt)
    rm ansible_output.txt
    if [[ "$ansible_output" =~ .*"failed="[^0].* ]]
    then
      echo -e "\033[0;31mAnsible installation failed, check the output for more details.\033[0m"
      rm vault_password_file.txt
      exit 0
    fi
  fi
  if [ -f "hosts_compose.ini" ] ; then
    echo "Installing docker-compose with Ansible in machines without docker-compose..."
    script -efq ansible_output.txt -c "make prepare_compose"
    ansible_output=$(cat ansible_output.txt)
    rm ansible_output.txt
    if [[ "$ansible_output" =~ .*"failed="[^0].* ]]
    then
      echo -e "\033[0;31mAnsible installation failed, check the output for more details.\033[0m"
      rm vault_password_file.txt
      exit 0
    fi
  fi
  if [ -f "hosts_cuda.ini" ] ; then
    echo "Installing nvidia-container-runtime with Ansible in machines with cuda..."
    script -efq ansible_output.txt -c "make prepare_cuda"
    ansible_output=$(cat ansible_output.txt)
    rm ansible_output.txt
    if [[ "$ansible_output" =~ .*"failed="[^0].* ]]
    then
      echo -e "\033[0;31mAnsible installation failed, check the output for more details.\033[0m"
      rm vault_password_file.txt
      exit 0
    fi
  fi
  ;;
esac
if [[ "$ansible_output" =~ .*"failed="[^0].* ]]
then
  echo -e "\033[0;31mAnsible installation failed, check the output for more details.\033[0m"
  exit 0
fi
echo "Configuring docker daemon.json file and restarting docker..."
cd ~/teamcode/appsAway/scripts/ansible_setup/
./setup_hosts_ini.sh
script -efq ansible_output.txt -c "make prepare_daemon"
ansible_output=$(cat ansible_output.txt)
rm ansible_output.txt
if [[ "$ansible_output" =~ .*"failed="[^0].* ]]
then
  echo -e "\033[0;31mAnsible installation failed, check the output for more details.\033[0m"
  rm vault_password_file.txt
  cd ~/teamcode/appsAway/scripts/
  ./appsAway_cleanupCluster.sh "registry"
  exit 1
fi
cd ~/teamcode/appsAway/scripts/
echo "About to setup the registry..."
./appsAway_setupRegistry.sh
if [[ "$?" != "0" ]]
then
  echo "Something failed in the script appsAway_setupRegistry.sh."
  echo "About to cleanup the cluster..."
  ./appsAway_cleanupCluster.sh "registry"
  exit 1
fi
cd ~/teamcode/appsAway/scripts/ansible_setup/
script -efq ansible_output.txt -c "make restart_docker"
ansible_output=$(cat ansible_output.txt)
rm ansible_output.txt
if [[ "$ansible_output" =~ .*"failed="[^0].* ]]
then
  echo -e "\033[0;31mAnsible installation failed, check the output for more details.\033[0m"
  rm vault_password_file.txt
  exit 1
fi
rm vault_password_file.txt
cd ~/teamcode/appsAway/scripts/
echo "About to setup the swarm..."
./appsAway_setupSwarm.sh
if [[ "$?" != "0" ]]
then
  echo "Something failed in the script appsAway_setupSwarm.sh."
  echo "About to cleanup the cluster..."
  ./appsAway_cleanupCluster.sh swarm registry
  exit 1
fi
os=`uname -s`
if [ "$os" = "Darwin" ]
then
    socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\" &
    export XAUTHORITY=/tmp/.Xauthority.$USER
fi
cd ~/teamcode/appsAway/scripts/
echo "About to setup the cluster..." 
./appsAway_setupCluster.sh
if [[ "$?" != "0" ]]
then
  echo "Something failed in the script appsAway_setupCluster.sh."
  echo "About to cleanup the cluster..."
  ./appsAway_cleanupCluster.sh swarm registry volumes icubapps
  exit 1
fi
cd ~/teamcode/appsAway/scripts
./appsAway_setupGui.sh
./appsAway_cleanupCluster.sh all
