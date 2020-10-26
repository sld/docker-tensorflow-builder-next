#!/bin/bash

LINUX_DISTRO="ubuntu-18.04"

cd "tensorflow/$LINUX_DISTRO"

# Set env variables
export PYTHON_VERSION=3.6.8
export TF_VERSION_GIT_TAG=v2.0.1
export BAZEL_VERSION=0.24.1
export USE_GPU=1
export CUDA_VERSION=10.0
export CUDNN_VERSION=7.5
export NCCL_VERSION=2.4

# Build the Docker image
docker-compose build

# Start the compilation
docker-compose run tf