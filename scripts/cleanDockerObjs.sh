#!/bin/bash

docker container prune -f

docker volume rm $1
