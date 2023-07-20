#!/bin/bash
set -ex;
LINUX_DISTRO="ubuntu-22.04"

cd "dist/$LINUX_DISTRO"

# Set env variables
export PYTHON_VERSION=3.10.12

export USE_GPU=0
export CUDA_VERSION=11.8
export CUDNN_VERSION=8.7
export NCCL_VERSION=2.15



export BAZEL_VERSION=5.3.0
export TF_VERSION_GIT_TAG=v2.12.0
export CC_OPT_FLAGS="-march=westmere -Wno-sign-compare"

docker-compose rm -f

# Build the Docker image
docker-compose build

# Start the compilation
docker-compose run tf