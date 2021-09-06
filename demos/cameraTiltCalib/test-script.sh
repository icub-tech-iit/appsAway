function check_failure { #TODO: we can't give a script as input to the function (unless the script is returning something...)
    "$@"
    local status=$?
    if (( status != 0 ))
    then
        echo "error with $1" >&2
        failure_counter=$(($failure_counter+1))
        echo "Failure counter: $failure_counter"
    fi
}

function setupEnvironment {
        cd $HOME/teamcode/appsAway/demos/$APPSAWAY_APP_NAME
        yml_files_default=("main.yml" "composeGui.yml")
        yml_files_default_len=${#yml_files_default[@]}
        yml_files=()

        for (( i=0; i<$yml_files_default_len; i++ ))
        do
          if [ -f "${yml_files_default[$i]}" ]
          then
            yml_files+=(${yml_files_default[$i]})
          fi
        done
        for (( i=0; i<${#yml_files[@]}; i++ ))
        do  
            if [[ $APPSAWAY_IMAGES != '' ]] 
            then
                list_images=($APPSAWAY_IMAGES)
                list_versions=($APPSAWAY_VERSIONS)
                list_tags=($APPSAWAY_TAGS)
            fi
            for (( j=0; j<${#list_images[@]}; j++ ))
            do
                sed -i 's,image: '"${list_images[$j]}"'.*$,image: '"${list_images[$j]}"':'"${list_versions[$j]}"'_'"${list_tags[$j]}"',g' ${yml_files[$i]}
            done
            # while read -r line || [ -n "$line" ]
            # do
              

            # done < ${yml_files[$i]} 
        done
      

        # # env file is located in iCubApps folder, so we need APPSAWAY_APP_PATH
        # os.chdir(os.environ.get('APPSAWAY_APP_PATH'))

        # env_file = open(".env", "r")
        # env_list = env_file.read().split('\n')
        # env_file.close()

        # # Checking if we already have all the environment variables in the .env; if yes we overwrite them, if not we add them 
        # for button in self.button_list:
        #   not_found = True
        #   not_found_path = True
        #   for i in range(len(env_list)):
        #     if button.varType == 'fileInput':
        #       if env_list[i].find(button.varName + "_PATH=") != -1 and os.environ.get(button.varName + "_PATH") != None:
        #         env_list[i] = button.varName + "_PATH=" + os.environ.get(button.varName + "_PATH")
        #         not_found_path = False
        #     if env_list[i].find(button.varName + "=") != -1 and os.environ.get(button.varName) != None:
        #       env_list[i] = button.varName + "=" + os.environ.get(button.varName)
        #       not_found = False
        #   if not_found and os.environ.get(button.varName) != None:
        #     env_list.insert(len(env_list), button.varName + "=" + os.environ.get(button.varName))
        #   if not_found_path and os.environ.get(button.varName + "_PATH") != None:
        #     env_list.insert(len(env_list), button.varName + "_PATH=" + os.environ.get(button.varName + "_PATH"))


        # env_file = open(".env", "w")
        # for line in env_list:
        #   env_file.write(line + '\n')
        # env_file.close()

        # os.chdir(os.path.join(os.environ.get('HOME'), "teamcode","appsAway","scripts"))
          
        # # now we copy all the files to their respective machines
        cd $HOME/teamcode/appsAway/scripts
}


failure_counter=0

echo "Passed parameters: $1 $2 $3 $4 $5 $6" 

cd $HOME/teamcode/appsAway/scripts
echo "#! /bin/bash
export APPSAWAY_APP_NAME=$1
export APPSAWAY_USER_NAME=icub
export APPSAWAY_APP_PATH=\${HOME}/iCubApps/\${APPSAWAY_APP_NAME}
export APPSAWAY_CONSOLENODE_ADDR=$2
export APPSAWAY_CONSOLENODE_USERNAME=icub
export APPSAWAY_IMAGES=${3:-\"icubteamcode/supervise-calib\"}
export APPSAWAY_VERSIONS=${4:-\"master-unstable_master\"}  
export APPSAWAY_TAGS=${5:-\"binaries\"} 
export APPSAWAY_DEPLOY_YAML_FILE_LIST=main.yml
export APPSAWAY_GUI_YAML_FILE_LIST=composeGui.yml
export APPSAWAY_STACK_NAME=mystack
export APPSAWAY_NODES_NAME_LIST=\"icubconsole\" 
export APPSAWAY_NODES_ADDR_LIST=\"\${APPSAWAY_GUINODE_ADDR} \${APPSAWAY_ICUBHEADNODE_ADDR} \${APPSAWAY_CONSOLENODE_ADDR} \${APPSAWAY_CUDANODE_ADDR} \${APPSAWAY_WORKERNODE_ADDR}\" 
export APPSAWAY_NODES_USERNAME_LIST=\"\${APPSAWAY_GUINODE_USERNAME} \${APPSAWAY_ICUBHEADNODE_USERNAME} \${APPSAWAY_CONSOLENODE_USERNAME} \${APPSAWAY_CUDANODE_USERNAME} \${APPSAWAY_WORKERNODE_USERNAME}\" " > ./appsAway_setEnvironment.local.sh 
chmod +x appsAway_setEnvironment.local.sh
source ./appsAway_setEnvironment.local.sh

echo "images: $APPSAWAY_IMAGES"
echo "versions: $APPSAWAY_VERSIONS"
echo "tags: $APPSAWAY_TAGS"

echo "
LEFT_CUSTOM_PORT=/icub/cam/left
RIGHT_CUSTOM_PORT=/icub/cam/right" >> $HOME/iCubApps/$APPSAWAY_APP_NAME/.env 

echo "about to setup the swarm..." 
./appsAway_setupSwarm.sh

echo "about to setup the cluster..." 
./appsAway_setupCluster.sh

setupEnvironment
./appsAway_copyFiles.sh
check_failure ./appsAway_startApp.sh
sleep 30
check_failure ./testApp.sh $APPSAWAY_APP_NAME $APPSAWAY_STACK_NAME
./appsAway_stopApp.sh 

if (( $failure_counter > 0 )) 
then 
    echo "Some commands failed"
    exit 1
fi
