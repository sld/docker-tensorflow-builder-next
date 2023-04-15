#!/bin/bash

LINUX_DISTRO="ubuntu-20.04"

cd "dist/$LINUX_DISTRO"

# Set env variables
export PYTHON_VERSION=3.8.0

export USE_GPU=1
export CUDA_VERSION=11.8
export CUDNN_VERSION=8.9
export NCCL_VERSION=2.15



export BAZEL_VERSION=5.3.0
export TF_VERSION_GIT_TAG=v2.12.0
export CC_OPT_FLAGS="-march=native -mssse3 -mcx16 -msse4.1 -msse4.2 -mpopcnt"

docker-compose rm -f

# Build the Docker image
docker-compose build

# Start the compilation
docker-compose run tf