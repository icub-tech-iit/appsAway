#! /bin/bash

cd ${HOME}/teamcode/appsAway/scripts/ansible_setup
./setup_hosts_ini.sh
echo "Checking installation with Ansible..."
make prepare
echo "Done checking installation with Ansible..."
cd ..

docker run  -it --network host icubteamcode/superbuild:master-unstable_sources bash
