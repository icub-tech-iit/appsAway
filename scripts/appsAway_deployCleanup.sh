#!/bin/bash
#set -x
# #####################################################
# SCRIPT NAME: appsAway_preDeployCleanup
#
# DESCRIPTION: This script is used to cleanup the setup of a robot before any deployment

# AUTHOR : Vadim Tikhanoff
#
# LATEST MODIFICATION DATE (2019-11-11):
#
SCRIPT_VERSION="0.1"          # Sets version variable
#
SCRIPT_TEMPLATE_VERSION="1.1.0" #
#
# #####################################################
# Default variables

NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
LGRAY='\033[0;37m'

has_icubBuild=true
has_superBuild=true
has_checkedValue=false
total_cleanup=false

# #####################################################

function checkSuperbuild(){

has_icubBuild=$(ssh -n -T ${APPSAWAY_USER_NAME}@$1 echo "\${ICUB_DIR}")

    if [ "$has_icubBuild" == "" ];
       then echo -e "${BLUE}ICUB_DIR ${NC} is ${RED} unset ${NC}"; else echo -e "variable is set to ${GREEN} '$has_icubBuild' ${NC}"; fi

has_superBuild=$(ssh -n -T ${APPSAWAY_USER_NAME}@$1 echo "\${ROBOTOLOGY_SUPERBUILD_INSTALL_PREFIX}")
    if [ "$has_superBuild" == "" ];
        then echo -e "${BLUE}SUPERBUILD ${NC} is ${RED} unset ${NC}"; else echo -e "variable is set to ${GREEN} '$has_superBuild' ${NC}"; fi

echo ""

}

# #####################################################

function checkFunc(){

ssh -T ${APPSAWAY_USER_NAME}@$1<<EOF

    echo "The path I should look is is $2"

    cd `echo "\${2}"`/bin
    pwd
    echo "I have found the following modules:"

    ls -l --time-style="long-iso" --ignore=*.sh --ignore=*.py | grep '^-' | awk '{print `echo '\$8'`}' | while read \line
    do
        ps -ef | grep -iw `echo '\$line'` | grep -v grep | grep -v ssh | grep -v 'bash -c export DISPLAY=:0.0'
    done
    echo ""
EOF
}

# #####################################################

function checkAndKillFunc(){

ssh -T ${APPSAWAY_USER_NAME}@$1<<EOF

    echo "The path I should look is is $2"

    cd `echo "\${2}"`/bin
    pwd
    echo "I have found the following modules:"

    ls -l --time-style="long-iso" --ignore=*.sh --ignore=*.py | grep '^-' | awk '{print `echo '\$8'`}' | while read \line
    do
        ps -ef | grep -iw `echo '\$line'` | grep -v grep | grep -v ssh | grep -v 'bash -c export DISPLAY=:0.0'
    done

    #echo "Killing them all"

    ls -l --time-style="long-iso" --ignore=*.sh --ignore=*.py | grep '^-' | awk '{print `echo '\$8'`}' | while read line
    do
       ps -ef | grep -i `echo '\$line'` | grep -v grep | grep -v ssh | grep -v 'sh -c' | awk '{print `echo '\$2'`}' | xargs kill -9 &>/dev/null
       # grep -v 'bash -c export DISPLAY=:0.0
    done
    yarp clean timeout 0.1 &>/dev/null
    echo ""
EOF
}

# #####################################################

function killFunc(){

ssh -T ${APPSAWAY_USER_NAME}@$1<<EOF

    cd `echo "\${ENV_VAR}"`/bin

    ls -l --time-style="long-iso" --ignore=*.sh --ignore=*.py | grep '^-' | awk '{print `echo '\$8'`}' | while read line
    do
       ps -ef | grep -i `echo '\$line'` | grep -v grep | grep -v ssh | grep -v 'sh -c' |awk '{print `echo '\$2'`}' | xargs kill -9 &>/dev/null
       # grep -v 'bash -c export DISPLAY=:0.0
    done
    yarp clean timeout 0.1 &>/dev/null

    echo ""
EOF

}

# #####################################################

function dockerRemoveVolumes(){
ssh -T ${APPSAWAY_USER_NAME}@$1<<EOF

   
    dockerVolumes=\$(docker volume ls --format "{{.Name}}")
    if [ "\$dockerVolumes" != "" ]; then
        docker volume rm \$dockerVolumes # To remove (what is called) dangling volumes
        docker volume ls -qf dangling=true | xargs -r docker volume rm #command to make sure the cleanup is complete
    fi

EOF
}

# #####################################################

function dockerCleanupStack(){
ssh -T ${APPSAWAY_USER_NAME}@$1<<EOF

    appsPath=\$(echo $APPSAWAY_APP_PATH)
    
    #docker-compose -f \$appsPath/*.yml kill -s SIGINT

    if [ -f "\$(echo $APPSAWAY_APP_PATH)/main.yml" ]
    then
        docker-compose -f \$(echo $APPSAWAY_APP_PATH)/main.yml kill -s SIGINT
    fi
    if [ -f "\$(echo $APPSAWAY_APP_PATH)/composeGui.yml" ]
    then 
        docker-compose -f \$(echo $APPSAWAY_APP_PATH)/composeGui.yml kill -s SIGINT 
    fi 
    if [ -f "\$(echo $APPSAWAY_APP_PATH)/composeHead.yml" ] 
    then 
        docker-compose -f \$(echo $APPSAWAY_APP_PATH)/composeHead.yml kill -s SIGINT 
    fi


    docker container prune --force

    dockerPS=\$(docker ps -a -q)
    dockerStack=\$(docker stack ls --format "{{json .Name}}" |& grep -v Error | grep -v NAME)
    dockerPS=\$(docker ps -a -q)
    #dockerVolumes=\$(docker volume ls -qf dangling=true)
    dockerVolumes=\$(docker volume ls --format "{{.Name}}")

    if [ "\$dockerPS" != "" ]; then
        docker stop \$dockerPS # stop all containers
    fi

    #sleep 1.0

    if [ "\$dockerStack" != "" ]; then
        docker stack rm \$dockerStack
    fi

    #sleep 2.0

    #if [ "\$dockerVolumes" != "" ]; then
    #    docker volume rm \$dockerVolumes # To remove (what is called) dangling volumes
    #    docker volume ls -qf dangling=true | xargs -r docker volume rm #command to make sure the cleanup is complete
    #fi

    docker swarm leave --force |& grep -v Error #remove swarm
EOF
}

# #####################################################

function dockerCleanupImages(){

ssh -T ${APPSAWAY_USER_NAME}@$1<<END

    dockerPS=\$(docker ps -a -q)
    dockerImages=\$(docker images -a -q)
    dockerImagesUntag=\$(docker images | grep "^<none>" | awk "{print $3}")

    if [ "\$dockerPS" != "" ]; then
        docker stop \$dockerPS # stop all containers
        docker rm \$dockerPS -f # delete all containers
    fi

    if [ "\$dockerImages" != "" ]; then
        docker rmi -f \$dockerImages # delete all images
    fi

    if [ "\$dockerImagesUntag" != "" ]; then
        docker rmi \$dockerImagesUntag # To remove all untagged images , images with use
    fi

END
}

if [[ -n "$1" ]] ; then
    if [ "$1" = "total" ] ; then
	    echo -e "running in mode ${PURPLE} $1 ${NC}"
	    total_cleanup=true
    elif [ "$1" = "stack" ] ; then
	    echo -e "running in mode ${PURPLE} $1 ${NC}"
	    total_cleanup=false
    else
	    echo "running in mode ${RED}unknown${NC}"
	    echo -e "${RED} wrong argument ${NC}, please select the ${WHITE}cleaning mode${NC}: ${PURPLE}total ${NC}or ${PURPLE}stack${NC}"
	exit
    fi
else
    echo 'please select the cleaning mode: total or stack'
    exit
fi

# #####################################################
start=`date +%s`
source appsAway_setEnvironment.local.sh
for p in ${APPSAWAY_NODES_ADDR_LIST}
do
    if [[ -n "$p" ]] ; then
        echo ""
        echo '|---------------------------------------------------------- |'
        echo -ne "|--- Started Cleanup Script on the${NC}"
        echo -e "${LGRAY} $(date +%d-%m-%Y)${PURPLE} @ ${LGRAY}$(date +%H:%M:%S)${NC} ---|"

        echo -ne "|                 on node  | "
        printf "${GREEN} %s${NC}                  |\n" "$p"
        echo -e '|---------------------------------------------------------- |'


        echo -e "|----------------- ${BLUE}Running System Cleanup${NC} ------------------|"
        echo ""

        checkSuperbuild $p

        if [ "$has_superBuild" != "" ] ; then
            echo -e "I have ${BLUE}superbuild${NC}"
        elif [ "$has_icubBuild" != "" ] ; then
            echo -e "I have a system ${BLUE}installed manually${NC}"
        else
            echo -e "I ${RED}do not ${NC}have a ${BLUE}yarp${NC} installation, ${BLUE}skipping${NC} \n\n"
        fi

        if [ "$has_superBuild" != "" ] || [ "$has_icubBuild" != "" ] ; then
            if [ "$has_superBuild" != "" ] ; then
                #checkFunc $p '${ROBOTOLOGY_SUPERBUILD_INSTALL_PREFIX}'
                checkAndKillFunc $p '${ROBOTOLOGY_SUPERBUILD_INSTALL_PREFIX}' &
                #killFunc $p '${ROBOTOLOGY_SUPERBUILD_INSTALL_PREFIX}'
            fi
            if [ "$has_icubBuild" != "" ] ; then
                #checkFunc $p '${ICUB_DIR}'
                checkAndKillFunc $p '${ICUB_DIR}' &
                #killFunc $p '${ICUB_DIR}'

                #checkFunc $p '${ICUBcontrib_DIR}'
                checkAndKillFunc $p '${ICUBcontrib_DIR}' &
                #killFunc $p '${ICUBcontrib_DIR}'

                #checkFunc $p '${YARP_DIR}'
                checkAndKillFunc $p '${YARP_DIR}' &
                #killFunc $p '${YARP_DIR}'
            fi
            sleep 0.5
            echo -ne "${GREEN}########################## ${NC}(100%)\r"
            sleep 0.5
            echo -ne '\n'

            echo ""
        fi

        echo -e "|----------------- ${BLUE}Running Docker Cleanup${NC} ------------------|"
        echo  ""

    echo -e "running in mode ${PURPLE} $1 ${NC}"

	if [ "$total_cleanup" = true ] ; then
        echo -e "starting ${PURPLE}cleaning ${NC}of the${PURPLE} images${NC} and ${PURPLE}stack${NC}"
        dockerCleanupStack $p &
        wait
	dockerCleanupImages $p &
    else
        echo -e "starting${PURPLE} cleaning${NC} of just the ${PURPLE}stack${NC}"
        dockerCleanupStack $p &
    fi

	#echo "Do you want to clean the docker images along with the stack ?"
        #select yn in "Yes" "No"; do
        #case $yn in
        #    Yes )   dockerCleanupStack $p
	    #    	    dockerCleanupImages $p
        #            break;;
        #    No )    dockerCleanupStack $p
        #            break;;
        #    *)      echo "Invalid entry."
        #            ;;
        #    esac
        #done </dev/tty

        wait
        echo ""
        echo -e "|------------ Node ${GREEN}$p${NC} is now ${GREEN}cleaned${NC} ------------ |"
        echo ""

    else
        echo -ne '\n'
        echo -e "${RED}node is empty or unreachable please check the cluster list ${NC}"
    fi

done

for p in ${APPSAWAY_NODES_ADDR_LIST}
do
    echo ""
    echo '|---------------------------------------------------------- |'
    echo -ne "|--- Started Cleanup Script on the${NC}"
    echo -e "${LGRAY} $(date +%d-%m-%Y)${PURPLE} @ ${LGRAY}$(date +%H:%M:%S)${NC} ---|"

    echo -ne "|                 on node  | "
    printf "${GREEN} %s${NC}                  |\n" "$p"
    echo -e '|---------------------------------------------------------- |'


    echo -e "|----------------- ${BLUE}Running System Cleanup${NC} ------------------|"
    echo ""
    dockerRemoveVolumes $p
done

end=`date +%s`
echo Execution time was `expr $end - $start` seconds.

echo -e "|------------------- ${BLUE}CLEANUP COMPLETE${NC} --------------------- |"
echo ""
