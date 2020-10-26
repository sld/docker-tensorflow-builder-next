#!/bin/bash

LINUX_DISTRO="ubuntu-18.04"
cd "tensorflow/$LINUX_DISTRO"

export PYTHON_VERSION=3.6.8
export TF_VERSION_GIT_TAG=v2.0.1
export BAZEL_VERSION=0.24.1
export USE_GPU=0

# Build the Docker image
docker-compose build

# Start the compilation
docker-compose run tf

# You can also do:
# docker-compose run tf bash
# bash build.sh
