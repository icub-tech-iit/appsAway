#! /bin/bash

if [ -z "$(dpkg -l | grep nvidia-docker2)" ]; then
    distribution=$(
        . /etc/os-release
        echo $ID$VERSION_ID
    ) &&
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - &&
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

    sudo apt-get update

    sudo apt-get install -y nvidia-docker2

    sudo systemctl restart docker
else
    echo "nvidia-docker2 already installed"
fi

docker pull icubteamcode/superbuild-pytorch:master_master-unstable_sources
docker run -it --network host --gpus all icubteamcode/superbuild-pytorch:master_master-unstable_sources bash
