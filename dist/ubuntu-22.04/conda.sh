#!/usr/bin/env bash
set -ex;
PYTHON_VERSION=$1
BAZEL_VERSION=$2
export PATH="/conda/bin:/usr/bin:$PATH"

# if [ "$USE_GPU" -eq "1" ]; then
#   export CUDA_HOME="/usr/local/cuda"
#   alias sudo=""
#   source cuda.sh
#   cuda.install $CUDA_VERSION $CUDNN_VERSION $NCCL_VERSION
#   cd /
# fi

# Set correct GCC version
GCC_VERSION="11"
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VERSION 10
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCC_VERSION 10
update-alternatives --set gcc "/usr/bin/gcc-$GCC_VERSION"
update-alternatives --set g++ "/usr/bin/g++-$GCC_VERSION"
gcc --version

export NUMPY_VERSION=1.18.5

# Install an appropriate Python environment
conda config --add channels conda-forge
conda create --yes -n tensorflow python==$PYTHON_VERSION
source activate tensorflow
conda install --yes numpy==$NUMPY_VERSION wheel bazel==$BAZEL_VERSION
conda install --yes packaging requests
#pip install keras-applications keras-preprocessing

