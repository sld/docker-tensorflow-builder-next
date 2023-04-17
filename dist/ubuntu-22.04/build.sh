#!/usr/bin/env bash
set -ex;
export CUDA_HOME=/usr/local/cuda-11.8/targets/x86_64-linux
ln -s /usr/local/cuda/bin $CUDA_HOME/bin
ln -s /usr/local/cuda-11.8/nvvm $CUDA_HOME/nvvm

rm -rf $CUDA_HOME/include/cudnn_version.h
rm -rf $CUDA_HOME/include/cudnn_version.h

ln -s /usr/include/x86_64-linux-gnu/cudnn_version_v8.h $CUDA_HOME/include/cudnn_version.h
ln -s /usr/include/x86_64-linux-gnu/cudnn_backend_v8.h $CUDA_HOME/include/cudnn_backend.h
ln -s /usr/include/x86_64-linux-gnu/cudnn_v8.h $CUDA_HOME/include/cudnn.h
ln -s /usr/include/x86_64-linux-gnu/cudnn_adv_infer_v8.h $CUDA_HOME/include/cudnn_adv_infer.h
ln -s /usr/include/x86_64-linux-gnu/cudnn_cnn_train_v8.h $CUDA_HOME/include/cudnn_cnn_train.h
ln -s /usr/include/x86_64-linux-gnu/cudnn_ops_train_v8.h $CUDA_HOME/include/cudnn_ops_train.h
ln -s /usr/include/x86_64-linux-gnu/cudnn_adv_train_v8.h $CUDA_HOME/include/cudnn_adv_train.h
ln -s /usr/include/x86_64-linux-gnu/cudnn_cnn_infer_v8.h $CUDA_HOME/include/cudnn_cnn_infer.h
ln -s /usr/include/x86_64-linux-gnu/cudnn_ops_infer_v8.h $CUDA_HOME/include/cudnn_ops_infer.h



mkdir -p $CUDA_HOME/lib64/
cp -R /usr/lib/x86_64-linux-gnu/*  $CUDA_HOME/lib64/
ln -s /usr/include/nccl.h $CUDA_HOME/include/nccl.h


mkdir -p /usr/local/cuda-11.8/targets/x86_64-linux/targets
ln -s /usr/local/cuda-11.8/targets/x86_64-linux /usr/local/cuda-11.8/targets/x86_64-linux/targets/x86_64-linux

export PATH="/conda/bin:/usr/bin:/usr/local/cuda/bin:$PATH"
source activate tensorflow
# rm -rf /usr/local/cuda/include/cudnn_version.h

#pip install keras-applications keras-preprocessing

# Compile TensorFlow

# Here you can change the TensorFlow version you want to build.
# You can also tweak the optimizations and various parameters for the build compilation.
# See https://www.tensorflow.org/install/install_sources for more details.
#TF_VERSION_GIT_TAG="v1.14.0-rc0"


cd /
rm -fr tensorflow/
git clone --depth 1 --branch $TF_VERSION_GIT_TAG "https://github.com/tensorflow/tensorflow.git"




if [ -d /root/.cache/bazel/ ]; then
     echo "removing bazel cache"
     rm -fr /root/.cache/bazel/
fi


TF_ROOT=/tensorflow
cd $TF_ROOT

# Python path options
export PYTHON_BIN_PATH=$(which python)
export PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')"
export PYTHONPATH=${TF_ROOT}/lib
export PYTHON_ARG=${TF_ROOT}/lib


# Compilation parameters
export TF_NEED_CUDA=0
export TF_NEED_GCP=1
export TF_CUDA_COMPUTE_CAPABILITIES=8.6
export TF_NEED_HDFS=1
export TF_NEED_OPENCL=0
export TF_NEED_JEMALLOC=1  # Need to be disabled on CentOS 6.6
export TF_ENABLE_XLA=0
export TF_NEED_VERBS=0
export TF_CUDA_CLANG=0
export TF_DOWNLOAD_CLANG=0
export TF_NEED_MKL=0
export TF_DOWNLOAD_MKL=0
export TF_NEED_MPI=0
export TF_NEED_S3=1
export TF_NEED_KAFKA=1
export TF_NEED_GDR=0
export TF_NEED_OPENCL_SYCL=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_NEED_AWS=0
export TF_NEED_IGNITE=0
export TF_NEED_ROCM=0

# Compiler options
export GCC_HOST_COMPILER_PATH=$(which gcc)

# Here you can edit this variable to set any optimizations you want.
# export CC_OPT_FLAGS="-march=native"
export CC_OPT_FLAGS="-march=native -mssse3 -mcx16 -msse4.1 -msse4.2 -mpopcnt"

if [ "$USE_GPU" -eq "1" ]; then
  # Cuda parameters
  export CUDA_TOOLKIT_PATH=$CUDA_HOME
  export CUDNN_INSTALL_PATH=$CUDA_HOME
  export TF_CUDA_VERSION="$CUDA_VERSION"
  export TF_CUDNN_VERSION="$CUDNN_VERSION"
  export TF_NEED_CUDA=1
  export TF_NEED_TENSORRT=0
  export TF_NCCL_VERSION=$NCCL_VERSION
  export NCCL_INSTALL_PATH=$CUDA_HOME
  export NCCL_INSTALL_PATH=$CUDA_HOME

  # Those two lines are important for the linking step.
  export LD_LIBRARY_PATH="$CUDA_TOOLKIT_PATH/lib64:${LD_LIBRARY_PATH}"
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${CUDA_HOME}/lib64
  export PATH=$PATH:${CUDA_HOME}/bin

  ldconfig
fi

# Compilation
./configure

if [ "$USE_GPU" -eq "1" ]; then

  bazel build --config=opt \
              --config=cuda \
              --linkopt="-lrt" \
              --linkopt="-lm" \
              --host_linkopt="-lrt" \
              --host_linkopt="-lm" \
              --action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" \
              //tensorflow/tools/pip_package:build_pip_package

  PACKAGE_NAME=tensorflow-gpu
 export SUBFOLDER_NAME="${TF_VERSION_GIT_TAG}-py${PYTHON_VERSION}-cuda${TF_CUDA_VERSION}-cudnn${TF_CUDNN_VERSION}"

else
#--cxxopt=-std=c++11 \
  bazel build --config=opt \
              --linkopt="-lrt" \
              --linkopt="-lm" \
              --host_linkopt="-lrt" \
              --host_linkopt="-lm" \
              --action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" \
              //tensorflow/tools/pip_package:build_pip_package

  PACKAGE_NAME=tensorflow
  SUBFOLDER_NAME="${TF_VERSION_GIT_TAG}-py${PYTHON_VERSION}"
fi

mkdir -p "/wheels/$SUBFOLDER_NAME"

bazel-bin/tensorflow/tools/pip_package/build_pip_package "/wheels/$SUBFOLDER_NAME" --project_name "$PACKAGE_NAME"

# Use the following for TF <= 1.8
# bazel-bin/tensorflow/tools/pip_package/build_pip_package "/wheels/$SUBFOLDER_NAME"

# Fix wheel folder permissions
