#! /bin/bash

docker pull icubteamcode/superbuild-pytorch:master_master-unstable_sources
docker run  -it --network host --gpus all icubteamcode/superbuild-pytorch:master_master-unstable_sources bash
