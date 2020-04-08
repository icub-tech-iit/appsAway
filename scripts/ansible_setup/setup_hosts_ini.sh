#! /bin/bash

source ../appsAway_setEnvironment.local.sh

if [ -f "hosts.ini" ]
then
    rm hosts.ini
fi

echo "[nodes:children]" >> ./hosts.ini


if [ ! -z "${APPSAWAY_CONSOLENODE_ADDR}" ]
then
    echo "console" >> ./hosts.ini
fi

if [ ! -z "${APPSAWAY_GUINODE_ADDR}" ]
then
    echo "gui" >> ./hosts.ini
fi

if [ ! -z "${APPSAWAY_ICUBHEADNODE_ADDR}" ]
then
    echo "head" >> ./hosts.ini
fi

if [ ! -z "${APPSAWAY_WORKERNODE_ADDR}" ]
then
    echo "worker" >> ./hosts.ini
fi

if [ ! -z "${APPSAWAY_CUDANODE_ADDR}" ]
then
    echo "cuda" >> ./hosts.ini
fi

echo "" >> ./hosts.ini

# now we populate each node

if [ ! -z "${APPSAWAY_CONSOLENODE_ADDR}" ]
then
    echo "[console]
consoleLaptop ansible_host=${APPSAWAY_CONSOLENODE_ADDR}
" >> ./hosts.ini
fi

if [ ! -z "${APPSAWAY_GUINODE_ADDR}" ]
then
    echo "[gui]
guiLaptop ansible_host=${APPSAWAY_GUINODE_ADDR}
" >> ./hosts.ini
fi

if [ ! -z "${APPSAWAY_ICUBHEADNODE_ADDR}" ]
then
    echo "[head]
headLaptop ansible_host=${APPSAWAY_ICUBHEADNODE_ADDR}
" >> ./hosts.ini
fi

if [ ! -z "${APPSAWAY_WORKERNODE_ADDR}" ]
then
    echo "[worker]" >> ./hosts.ini
    it_num=0
    for IP in ${APPSAWAY_WORKERNODE_ADDR}
    do
        echo "workerLaptop$it_num ansible_host=$IP" >> ./hosts.ini
        it_num=$(( $it_num+1 ))
    done
    echo "" >> ./hosts.ini
fi

if [ ! -z "${APPSAWAY_CUDANODE_ADDR}" ]
then
    echo "[cuda]" >> ./hosts.ini
    it_num=0
    for IP in ${APPSAWAY_CUDANODE_ADDR}
    do
        echo "workerLaptop$it_num ansible_host=$IP" >> ./hosts.ini
        it_num=$(( $it_num+1 ))
    done
    echo "" >> ./hosts.ini
fi

echo "[all:vars]
ansible_ssh_user=\"${APPSAWAY_USER_NAME}\"
ansible_become_pass=\"${APPSAWAY_USER_PASSWORD}\" " >> ./hosts.ini
