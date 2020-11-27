#! /bin/bash

docker pull icubteamcode/superbuild-tensorflow-gpu:master_master-unstable_sources
docker run  -it --network host --gpus all icubteamcode/superbuild-tensorflow-gpu:master_master-unstable_sources bash
