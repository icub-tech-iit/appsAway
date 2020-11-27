#! /bin/bash

docker pull icubteamcode/superbuild-tensorflow-cpu:master_master-unstable_sources
docker run  -it --network host icubteamcode/superbuild-tensorflow-cpu:master_master-unstable_sources bash
