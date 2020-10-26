#!/bin/bash

LINUX_DISTRO="ubuntu-18.04"

cd "tensorflow/$LINUX_DISTRO"

export PYTHON_VERSION=3.6.12
export TF_VERSION_GIT_TAG=v1.15.0
export BAZEL_VERSION=0.26.1
export USE_GPU=1
export CUDA_VERSION=10.2
export CUDNN_VERSION=7.6
export NCCL_VERSION=2.7

# Build the Docker image
docker-compose build

# Start the compilation
docker-compose run tf