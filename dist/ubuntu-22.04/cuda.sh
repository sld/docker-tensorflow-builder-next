#!/usr/bin/env bash
set -ex;
# Cuda and friends installation done right.
# Switch default Cuda version using symbolic link: cuda.switch 9.2
# Install Cuda: cuda.install.cuda 10.2
# Install cuDNN to CUDA_HOME: cuda.install.cudnn 7.6
# Install NCCL to CUDA_HOME: cuda.install.nccl 2.7
# Install Cuda, cuDNN and NCCL: cuda.install 10.2 10.0 7.5 2.4

# Author: Hadrien Mary <hadrien.mary@gmail.com>
# License: MIT License
# Date: 11/03/2019

is_cuda_home_set() {
  if [ -z "$CUDA_HOME" ]; then
    echo "CUDA_HOME is not set. Please set it:"
    echo 'export CUDA_HOME="/usr/local/cuda/"'
    return 1
  fi
  return 0
}

is_cuda_home_symbolic_link() {
  if [[ -e "${CUDA_HOME}" && -L "${CUDA_HOME}" ]]; then
    return 0
  elif [[ ! -d "${CUDA_HOME}" && ! -f "${CUDA_HOME}" ]]; then
    return 0
  else
    echo "CUDA_HOME is not a symbolic link."
    echo "Please make it a symbolic link."
    return 1
  fi
}

guess_cuda_version() {
	if ! is_cuda_home_set; then
	  return 1
	fi

	if ! is_cuda_home_symbolic_link; then
	  return 1
	fi

	POSSIBLE_CUDA_VERSION=$(cat "$CUDA_HOME/version.txt" | cut -d' ' -f 3 | cut -d'.' -f 1-2)
	if [ -z $POSSIBLE_CUDA_VERSION]; then
    POSSIBLE_CUDA_VERSION=$(nvcc --version | grep -oP 'release \K\d+\.\d+')
  fi

	if [ -z $POSSIBLE_CUDA_VERSION]; then
    POSSIBLE_CUDA_VERSION=$CUDA_VERSION
  fi
  echo $POSSIBLE_CUDA_VERSION
}

cuda.see() {
  if ! is_cuda_home_set; then
    return 1
  fi

  PARENT_BASE_DIR=$(dirname $CUDA_HOME)
  ls -l $PARENT_BASE_DIR
  return 0
}

cuda.switch() {
  if ! is_cuda_home_set; then
    return 1
  fi

  if ! is_cuda_home_symbolic_link; then
    return 1
  fi

  if [ -z "$1" ]; then
      echo "Please specify a Cuda version."
      echo "Usage: cuda.switch CUDA_VERSION"
      echo "Cuda version available: 9.0, 9.1, 9.2, 10.0, 10.1"
      return 1
  fi

  NEW_CUDA_VERSION="$1"
  NEW_CUDA_HOME="$CUDA_HOME-$NEW_CUDA_VERSION"

  if [ ! -d $NEW_CUDA_HOME ]; then
    echo "Cuda $NEW_CUDA_VERSION doesn't exist at $NEW_CUDA_HOME."
    return 1
  fi

  PARENT_BASE_DIR=$(dirname $CUDA_HOME)
  if [ ! -w "$PARENT_BASE_DIR" ]; then
    # sudo rm -f $CUDA_HOME
    sudo ln -s $NEW_CUDA_HOME $CUDA_HOME
  else
    # rm -f $CUDA_HOME
    ln -s $NEW_CUDA_HOME $CUDA_HOME
  fi
  echo "Default Cuda version is now $NEW_CUDA_VERSION at $NEW_CUDA_HOME"
}

cuda.install.cuda() {

  CUDA_VERSION="$1"
  if [ -z "$CUDA_VERSION" ]; then
    echo "Please specify a Cuda version."
    echo "Usage: cuda.install.cuda CUDA_VERSION"
    echo "Example: cuda.install.cuda 10.0"
    echo "Cuda version available: 9.0, 9.1, 9.2, 10.0, 9.2."
    return 1
  fi

  if ! is_cuda_home_set; then
    return 1
  fi

  if ! is_cuda_home_symbolic_link; then
    return 1
  fi

  CUDA_PATH="$CUDA_HOME-$CUDA_VERSION"
  if [ -d $CUDA_PATH ]; then
    echo "$CUDA_PATH exists. Please remove the previous Cuda folder first."
    return 1
  fi

  # Setup Cuda URL
  if [ "$CUDA_VERSION" = "9.0" ]; then
    CUDA_URL="https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_384.81_linux-run"
  elif [ "$CUDA_VERSION" = "9.1" ]; then
    CUDA_URL="https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.85_387.26_linux"
  elif [ "$CUDA_VERSION" = "9.2" ]; then
    CUDA_URL="https://developer.nvidia.com/compute/cuda/9.2/Prod/local_installers/cuda_9.2.88_396.26_linux"
  elif [ "$CUDA_VERSION" = "10.0" ]; then
    CUDA_URL="https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda_10.0.130_410.48_linux"
  elif [ "$CUDA_VERSION" = "10.1" ]; then
    CUDA_URL="https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.105_418.39_linux.run"
  elif [ "$CUDA_VERSION" = "10.2" ]; then
    CUDA_URL="https://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run"
  elif [ "$CUDA_VERSION" = "11.8" ]; then
    CUDA_URL="https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run" 
  else
    echo "Error: You need to set CUDA_VERSION to 9.0, 9.1, 9.2, 10.0, 10.1, or 10.2."
    return 1
  fi
  rm -rf /tmp/* 

  CUDA_INSTALLER_PATH="/src/cuda-$CUDA_VERSION.run"

  echo "Download Cuda $CUDA_VERSION."
  if [ ! -f $CUDA_INSTALLER_PATH ]; then
    wget -q "$CUDA_URL" -O "$CUDA_INSTALLER_PATH"
    # echo $(md5sum $CUDA_INSTALLER_PATH) > $CUDA_INSTALLER_PATH.md5
  fi
  # cp $CUDA_INSTALLER_PATH /tmp
  # CUDA_INSTALLER_PATH=/tmp/$(basename $CUDA_INSTALLER_PATH)

  echo "Install Cuda $CUDA_VERSION."
  PARENT_BASE_DIR=$(dirname $CUDA_HOME)
  if [ ! -w "$PARENT_BASE_DIR" ]; then
    sudo bash "$CUDA_INSTALLER_PATH" --silent --toolkit --override --toolkitpath="$CUDA_PATH"
  else
    bash "$CUDA_INSTALLER_PATH" --silent --toolkit --override --toolkitpath="$CUDA_PATH"
  fi

  # Set the symbolic link.
  cuda.switch $CUDA_VERSION

  ln -s /usr/local/cuda-$CUDA_VERSION/targets/x86_64-linux/include/cublas_api.h /usr/include/x86_64-linux-gnu
  echo "Cuda $CUDA_VERSION is installed at $CUDA_PATH."

  return 0
}

cuda.install.cudnn() {
  # Install cuDNN in $CUDA_HOME

  if ! is_cuda_home_set; then
    return 1
  fi

  if ! is_cuda_home_symbolic_link; then
    return 1
  fi

  CUDA_VERSION="$(guess_cuda_version)"
  if [ -z "$CUDA_VERSION" ]; then
    echo "Can't guess the Cuda version from $CUDA_HOME."
    return 1
  fi

  CUDNN_VERSION="$1"
  if [ -z "$CUDNN_VERSION" ]; then
    echo "Please specify a cuDNN version."
    echo "Usage: cuda.install.cudnn CUDNN_VERSION"
    echo "Example: cuda.install.cudnn 7.5"
    echo "cuDNN version available: 7.0, 7.1, 7.4, 7.5."
    return 1
  fi

  # cuDNN 7.0
  if [ "$CUDNN_VERSION" = "7.0" ]; then

    if [ "$CUDA_VERSION" = "9.0" ]; then
      CUDNN_VERSION_DETAILED="7.0.5.15"
    elif [ "$CUDA_VERSION" = "9.1" ]; then
      CUDNN_VERSION_DETAILED="7.0.5.15"
    elif [ -n "$CUDNN_VERSION" ]; then
      echo "Error: cuDNN $CUDNN_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  # cuDNN 7.1
  elif [ "$CUDNN_VERSION" = "7.1" ]; then

    if [ "$CUDA_VERSION" = "9.0" ]; then
      CUDNN_VERSION_DETAILED="7.1.4.18"
    elif [ "$CUDA_VERSION" = "9.2" ]; then
      CUDNN_VERSION_DETAILED="7.1.4.18"
    elif [ -n "$CUDNN_VERSION" ]; then
      echo "Error: cuDNN $CUDNN_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  # cuDNN 7.4
  elif [ "$CUDNN_VERSION" = "7.4" ]; then

    if [ "$CUDA_VERSION" = "9.0" ]; then
      CUDNN_VERSION_DETAILED="7.4.2.24"
    elif [ "$CUDA_VERSION" = "9.2" ]; then
      CUDNN_VERSION_DETAILED="7.4.2.24"
    elif [ "$CUDA_VERSION" = "10.0" ]; then
      CUDNN_VERSION_DETAILED="7.4.2.24"
    elif [ -n "$CUDNN_VERSION" ]; then
      echo "Error: cuDNN $CUDNN_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  # cuDNN 7.5
  elif [ "$CUDNN_VERSION" = "7.5" ]; then

    if [ "$CUDA_VERSION" = "9.0" ]; then
      CUDNN_VERSION_DETAILED="7.5.0.56"
    elif [ "$CUDA_VERSION" = "9.2" ]; then
      CUDNN_VERSION_DETAILED="7.5.0.56"
    elif [ "$CUDA_VERSION" = "10.0" ]; then
      CUDNN_VERSION_DETAILED="7.5.0.56"
    elif [ "$CUDA_VERSION" = "10.1" ]; then
      CUDNN_VERSION_DETAILED="7.5.0.56"
    elif [ -n "$CUDNN_VERSION" ]; then
      echo "Error: cuDNN $CUDNN_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  # cuDNN 7.6
  elif [ "$CUDNN_VERSION" = "7.6" ]; then

    if [ "$CUDA_VERSION" = "10.2" ]; then
      CUDNN_VERSION_DETAILED="7.6.5.32"
    elif [ -n "$CUDNN_VERSION" ]; then
      echo "Error: cuDNN $CUDNN_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  fi

  # cuDNN 8.9
  if [ "$CUDNN_VERSION" = "8.9" ]; then

    if [ "$CUDA_VERSION" = "11.0" ] || [ "$CUDA_VERSION" = "11.1" ] || [ "$CUDA_VERSION" = "11.2" ] || \
      [ "$CUDA_VERSION" = "11.3" ] || [ "$CUDA_VERSION" = "11.4" ] || [ "$CUDA_VERSION" = "11.5" ] || \
      [ "$CUDA_VERSION" = "11.6" ] || [ "$CUDA_VERSION" = "11.7" ] || [ "$CUDA_VERSION" = "11.8" ]; then
      CUDNN_VERSION_DETAILED="8.9.0.131"
    elif [ -n "$CUDNN_VERSION" ]; then
      echo "Error: cuDNN $CUDNN_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  elif [ -n "$CUDNN_VERSION" ]; then
    echo "Error: You need to set CUDNN_VERSION to 8.9 or another supported version."
    return 1
  fi



  #https://developer.download.nvidia.com/compute/cudnn/secure/8.9.0/local_installers/11.8/cudnn-local-repo-ubuntu2004-8.9.0.131_1.0-1_amd64.deb


  # Setup URLs
  # https://ubuntu.pkgs.org/20.04/cuda-amd64/libcudnn8-dev_8.9.0.131-1+cuda11.8_amd64.deb.html


  CUDNN_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/libcudnn8_${CUDNN_VERSION_DETAILED}-1+cuda${CUDA_VERSION}_amd64.deb"
  CUDNN_URL_DEV="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/libcudnn8-dev_${CUDNN_VERSION_DETAILED}-1+cuda${CUDA_VERSION}_amd64.deb"

  # Setup temporary paths
  CUDNN_TMP_PATH="/src/cudnn-$CUDNN_VERSION.deb"
  CUDNN_DEV_TMP_PATH="/src/cudnn-$CUDNN_VERSION-dev.deb"

  CUDNN_TMP_DIR_PATH="/tmp/cudnn-$CUDNN_VERSION"
  CUDNN_DEV_TMP_DIR_PATH="/tmp/cudnn-$CUDNN_VERSION-dev"

  echo "Download binaries."
  if [ ! -f $CUDNN_TMP_PATH ]; then
    wget -q "$CUDNN_URL" -O "$CUDNN_TMP_PATH"
    # echo $(md5sum $CUDNN_TMP_PATH) > $CUDNN_TMP_PATH.md5
  fi
  # cp $CUDNN_TMP_PATH /tmp
  # CUDNN_TMP_PATH=/tmp/$(basename $CUDNN_TMP_PATH)


  if [ ! -f $CUDNN_DEV_TMP_PATH ]; then
    wget -q "$CUDNN_URL_DEV" -O "$CUDNN_DEV_TMP_PATH"
    # echo $(md5sum $CUDNN_DEV_TMP_PATH) > $CUDNN_DEV_TMP_PATH.md5
  fi
  # cp $CUDNN_DEV_TMP_PATH /tmp
  # CUDNN_DEV_TMP_PATH=/tmp/$(basename $CUDNN_DEV_TMP_PATH)


  mkdir -p "$CUDNN_TMP_DIR_PATH"
  mkdir -p "$CUDNN_DEV_TMP_DIR_PATH"

  echo "Extract binaries."
  cd "$CUDNN_TMP_DIR_PATH"
  ar x "$CUDNN_TMP_PATH"
  tar -xJf data.tar.xz
  cd "$CUDNN_DEV_TMP_DIR_PATH"
  ar x "$CUDNN_DEV_TMP_PATH"
  tar -xJf data.tar.xz

  echo "Install cuDNN files."

  MAJOR_CUDNN=$(echo $CUDNN_VERSION | cut -d '.' -f 1)
  PARENT_BASE_DIR=$(dirname $CUDA_HOME)
  # if [ ! -w "$PARENT_BASE_DIR" ]; then
  #   #sudo mv $CUDNN_TMP_DIR_PATH/usr/lib/x86_64-linux-gnu/libcudnn* "$CUDA_HOME/lib64/"
  #   #sudo mv "$CUDNN_DEV_TMP_DIR_PATH/usr/include/x86_64-linux-gnu/cudnn_v$MAJOR_CUDNN.h" "$CUDA_HOME/lib64/"
  #   # sudo mv "$CUDNN_DEV_TMP_DIR_PATH/usr/lib/x86_64-linux-gnu/libcudnn_static_v$MAJOR_CUDNN.a" "$CUDA_HOME/lib64/"

  #   # sudo rm -f "$CUDA_HOME/include/cudnn.h"
  #   # sudo rm -f "$CUDA_HOME/lib64/libcudnn_static.a"

  #   sudo ln -s "$CUDA_HOME/include/cudnn_v$MAJOR_CUDNN.h" "$CUDA_HOME/include/cudnn.h"
  #   sudo ln -s "$CUDA_HOME/include/cudnn_version_v$MAJOR_CUDNN.h" "$CUDA_HOME/lib64/cudnn_version.h"
  #   sudo ln -s "$CUDA_HOME/lib64/libcudnn_static_v$MAJOR_CUDNN.a" "$CUDA_HOME/lib64/libcudnn_static.a"
  # else
  #   mv "$CUDNN_TMP_DIR_PATH/usr/lib/x86_64-linux-gnu/libcudnn*" "$CUDA_HOME/lib64/"
  #   mv "$CUDNN_DEV_TMP_DIR_PATH/usr/include/x86_64-linux-gnu/cudnn_v$MAJOR_CUDNN.h" "$CUDA_HOME/lib64/"
  #   # mv "$CUDNN_DEV_TMP_DIR_PATH/usr/lib/x86_64-linux-gnu/libcudnn_static_v$MAJOR_CUDNN.a" "$CUDA_HOME/lib64/"

  #   # rm -f "$CUDA_HOME/include/cudnn.h"
  #   # rm -f "$CUDA_HOME/lib64/libcudnn_static.a"

  #   ln -s "$CUDA_HOME/include/cudnn_v$MAJOR_CUDNN.h" "$CUDA_HOME/lib64/cudnn.h"
  #   ln -s "$CUDA_HOME/include/cudnn_version_v$MAJOR_CUDNN.h" "$CUDA_HOME/lib64/cudnn_version.h"
  #   ln -s "$CUDA_HOME/lib64/libcudnn_static_v$MAJOR_CUDNN.a" "$CUDA_HOME/lib64/libcudnn_static.a"
  # fi

  echo "Cleanup files."
  # rm -fr "$CUDNN_TMP_DIR_PATH"
  # rm -fr "$CUDNN_DEV_TMP_DIR_PATH"

  echo "cuDNN $CUDNN_VERSION is installed at $CUDA_HOME."
}

cuda.install.nccl() {
  # Install NCCL in $CUDA_HOME

  if ! is_cuda_home_set; then
    return 1
  fi

  if ! is_cuda_home_symbolic_link; then
    return 1
  fi

  CUDA_VERSION="$(guess_cuda_version)"
  if [ -z "$CUDA_VERSION" ]; then
    echo "Can't guess the Cuda version from $CUDA_HOME."
    return 1
  fi

  NCCL_VERSION="$1"
  if [ -z "$NCCL_VERSION" ]; then
    # echo "Please specify a NCCL version."
    # echo "Usage: cuda.install.nccl NCCL_VERSION"
    # echo "Example: cuda.install.nccl 2.4"
    # echo "NCCL version available: 2.1, 2.2, 2.3, 2.3 and 2.7"
    # return 1
    # Default NCCL version
    NCCL_VERSION="2.4"
  fi

  # NCCL 2.1
  if [ "$NCCL_VERSION" = "2.1" ]; then


    if [ "$CUDA_VERSION" = "9.0" ]; then
      NCCL_VERSION_DETAILED="2.1.15-1"
    elif [ "$CUDA_VERSION" = "9.1" ]; then
      NCCL_VERSION_DETAILED="2.1.15-1"
    elif [ -n "$NCCL_VERSION" ]; then
      echo "Error: NCCL $NCCL_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  # NCCL 2.3
  elif [ "$NCCL_VERSION" = "2.2" ]; then

    # NCCL 2.2
    if [ "$CUDA_VERSION" = "9.0" ]; then
      NCCL_VERSION_DETAILED="2.2.13-1"
    elif [ "$CUDA_VERSION" = "9.2" ]; then
      NCCL_VERSION_DETAILED="2.2.13-1"
    elif [ -n "$NCCL_VERSION" ]; then
      echo "Error: NCCL $NCCL_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  # NCCL 2.3
  elif [ "$NCCL_VERSION" = "2.3" ]; then

    if [ "$CUDA_VERSION" = "9.0" ]; then
      NCCL_VERSION_DETAILED="2.3.7-1"
    elif [ "$CUDA_VERSION" = "9.2" ]; then
      NCCL_VERSION_DETAILED="2.3.7-1"
    elif [ "$CUDA_VERSION" = "10.0" ]; then
      NCCL_VERSION_DETAILED="2.3.7-1"
    elif [ -n "$NCCL_VERSION" ]; then
      echo "Error: NCCL $NCCL_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  # NCCL 2.4
  elif [ "$NCCL_VERSION" = "2.4" ]; then

    if [ "$CUDA_VERSION" = "9.0" ]; then
      NCCL_VERSION_DETAILED="2.4.2-1"
    elif [ "$CUDA_VERSION" = "9.2" ]; then
      NCCL_VERSION_DETAILED="2.4.2-1"
    elif [ "$CUDA_VERSION" = "10.0" ]; then
      NCCL_VERSION_DETAILED="2.4.2-1"
    elif [ "$CUDA_VERSION" = "10.1" ]; then
      NCCL_VERSION_DETAILED="2.4.2-1"
    elif [ -n "$NCCL_VERSION" ]; then
      echo "Error: NCCL $NCCL_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  # NCCL 2.7
  elif [ "$NCCL_VERSION" = "2.7" ]; then

    if [ "$CUDA_VERSION" = "10.2" ]; then
      NCCL_VERSION_DETAILED="2.7.8-1"
    elif [ -n "$NCCL_VERSION" ]; then
      echo "Error: NCCL $NCCL_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi
  fi


  # NCCL 2.15
  if [ "$NCCL_VERSION" = "2.15" ]; then

    if [ "$CUDA_VERSION" = "11.0" ] || [ "$CUDA_VERSION" = "11.1" ] || [ "$CUDA_VERSION" = "11.2" ] || \
      [ "$CUDA_VERSION" = "11.3" ] || [ "$CUDA_VERSION" = "11.4" ] || [ "$CUDA_VERSION" = "11.5" ] || \
      [ "$CUDA_VERSION" = "11.6" ] || [ "$CUDA_VERSION" = "11.7" ] || [ "$CUDA_VERSION" = "11.8" ]; then
      NCCL_VERSION_DETAILED="2.15.5"
    elif [ -n "$NCCL_VERSION" ]; then
      echo "Error: NCCL $NCCL_VERSION is not compatible with Cuda $CUDA_VERSION."
      return 1
    fi

  elif [ -n "$NCCL_VERSION" ]; then
    echo "Error: You need to set NCCL_VERSION to 2.1, 2.2, 2.3, 2.4, 2.7, or 2.15."
    return 1
  fi


  # Setup URLs
  NCCL_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/libnccl2_${NCCL_VERSION_DETAILED}-1+cuda${CUDA_VERSION}_amd64.deb"
  NCCL_URL_DEV="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/libnccl-dev_${NCCL_VERSION_DETAILED}-1+cuda${CUDA_VERSION}_amd64.deb"

  # Setup temporary paths
  NCCL_TMP_PATH="/src/nccl-$NCCL_VERSION.deb"
  NCCL_DEV_TMP_PATH="/src/nccl-$NCCL_VERSION-dev.deb"

  NCCL_TMP_DIR_PATH="/tmp/nccl-$NCCL_VERSION"
  NCCL_DEV_TMP_DIR_PATH="/tmp/nccl-$NCCL_VERSION-dev"

  echo "Download binaries."
  if [ ! -f $NCCL_TMP_PATH ]; then
    wget -q "$NCCL_URL" -O "$NCCL_TMP_PATH"
    # echo $(md5sum $NCCL_TMP_PATH) > $NCCL_TMP_PATH.md5
  fi
  # cp $NCCL_TMP_PATH /tmp
  # NCCL_TMP_PATH=/tmp/$(basename $NCCL_TMP_PATH)

  if [ ! -f $NCCL_DEV_TMP_PATH ]; then
    wget -q "$NCCL_URL_DEV" -O "$NCCL_DEV_TMP_PATH"
    # echo $(md5sum $NCCL_DEV_TMP_PATH) > $NCCL_DEV_TMP_PATH.md5
  fi
  # cp $NCCL_DEV_TMP_PATH /tmp
  # NCCL_DEV_TMP_PATH=/tmp/$(basename $NCCL_DEV_TMP_PATH)


  mkdir -p "$NCCL_TMP_DIR_PATH"
  mkdir -p "$NCCL_DEV_TMP_DIR_PATH"

  echo "Extract binaries."
  cd "$NCCL_TMP_DIR_PATH"
  ar x "$NCCL_TMP_PATH"
  tar -xJf data.tar.xz
  cd "$NCCL_DEV_TMP_DIR_PATH"
  ar vx "$NCCL_DEV_TMP_PATH"
  tar -xJf data.tar.xz

  echo "Install NCCL files."

  PARENT_BASE_DIR=$(dirname $CUDA_HOME)
  if [ ! -w "$PARENT_BASE_DIR" ]; then
    sudo mv $NCCL_TMP_DIR_PATH/usr/lib/x86_64-linux-gnu/libnccl* "$CUDA_HOME/lib64/"
    # sudo rm -f "$CUDA_HOME/include/nccl.h"
    sudo mv "$NCCL_DEV_TMP_DIR_PATH/usr/include/nccl.h" "$CUDA_HOME/include/nccl.h"
    # sudo rm -f "$CUDA_HOME/lib64/libnccl_static.a"
    # sudo mv "$NCCL_DEV_TMP_DIR_PATH/usr/lib/x86_64-linux-gnu/libnccl_static.a" "$CUDA_HOME/lib64/libnccl_static.a"
  else
    mv $NCCL_TMP_DIR_PATH/usr/lib/x86_64-linux-gnu/libnccl* "$CUDA_HOME/lib64/"
    # rm -f "$CUDA_HOME/include/nccl.h"
    mv "$NCCL_DEV_TMP_DIR_PATH/usr/include/nccl.h" "$CUDA_HOME/include/nccl.h"
    # rm -f "$CUDA_HOME/lib64/libnccl_static.a"
    # mv "$NCCL_DEV_TMP_DIR_PATH/usr/lib/x86_64-linux-gnu/libnccl_static.a" "$CUDA_HOME/lib64/libnccl_static.a"
  fi

  echo "Cleanup files."
  # rm -fr "$NCCL_TMP_DIR_PATH"
  # rm -fr "$NCCL_DEV_TMP_DIR_PATH"

  echo "NCCL $NCCL_VERSION is installed at $CUDA_HOME."
}

cuda.gcc.install() {

  if [ -z "$1" ]; then
    echo "Please specify a GCC version."
    return
  fi
  export GCC_VERSION="$1"

  sudo apt install --yes gcc-$GCC_VERSION g++-$GCC_VERSION

  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VERSION 10
  sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCC_VERSION 10

  sudo update-alternatives --set gcc "/usr/bin/gcc-$GCC_VERSION"
  sudo update-alternatives --set g++ "/usr/bin/g++-$GCC_VERSION"
}
mkdir /src
cuda.install.cuda $1
cuda.install.cudnn $2
cuda.install.nccl $3
rm -rf /src/*