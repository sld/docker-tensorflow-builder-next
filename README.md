# Compile Tensorflow on Docker

Docker images to compile TensorFlow yourself.

Tensorflow only provide a limited set of build and it can be challenging to compile yourself on certain configuration. With this `Dockerfile`, you should be able to compile TensorFlow on any Linux platform that run Docker.

Compilation images are provided for targeting platforms in the [dist](/dist) path.

```json
[
   "ubuntu-16.04",
   "ubuntu-18.04",
   "ubuntu-18.10",
   "ubuntu-20.04",
   "centos-6.6",
   "centos-7.4"
]
```

This fork includes NVIDIA ``cuda==10.2, NCCL==2.7`` support and will be maintained on forward releases as TensorFlow evolves.

## Requirements

- `docker`
- `docker-compose`

#### Optional GPU Hardware

- Docker CUDA Support `nvidia-container-toolkit`
- CUDA Hardware `tf.test.is_gpu_available()`

## Usage: Compile Wheels in Container

Get started compiling TensorFlow python3 wheels, ensure you have a supported docker container environment. Note that it may take a considerable time to prep image layers with CUDA env and build from source (example: Xeon 24C, build times ~3h).

#### Clone Repo

```bash
$ git clone https://github.com/SarMalik/docker-tensorflow-builder.git
$ cd docker-tensorflow-builder
```

#### Modify Build Params

Clone the [build/compile.tf{version}-cuda{version}.sh](/build) starter script with bash params for targeting wheel compilation. 

Refer to tested configs listed in the [Builds](#Builds) section.

```bash
$ cat build/compile.*.sh >> vim
```

#### Variables

```bash
# Target:OS:Distribution
# Supported: [
#   'ubuntu-16.04',
#   'ubuntu-18.04',
#   'ubuntu-18.10',
#   'ubuntu-20.04',
#   'centos-6.6',
#   'centos-7.4'
# ]
LINUX_DISTRO="ubuntu-16.04"

# Target:Python Version
# Number<1,2>
export PYTHON_VERSION=3.6.12

# Target:Checkout TensorFlow Release Tag
# String<Number<2>>
export TF_VERSION_GIT_TAG=v1.15.0

# Target:Build:Bazel
# String<Number<1,2>>
export BAZEL_VERSION=0.19

# TF Graph Hardware Support
# 0: CPU, 1: GPU
# Int
export USE_GPU=1

# Required if USE_GPU=1
# CUDA, CUDNN, NCCL major increments
# Number<1>
export CUDA_VERSION=10.2
export CUDNN_VERSION=7.6
export NCCL_VERSION=2.7
```

#### Build

To instantiate the compiler environment, save and run the platform targeting script.

```bash
$ docker ./build/compile.tf{version}-cuda{version}.sh
```

#### Build Output

The compiled wheels are written to `${PWD}/wheels/**/*.wheel`.

#### Cleanup Output

Intermediate container layers used for the build process may take up considerable space and can be safely removed from the host using the command: ``$ sudo docker system prune``.

---

## Builds

| Tensorflow | Python | Distribution | Bazel | CUDA | cuDNN | NCCL | Comment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2.0.1 | 3.6.8 | Ubuntu 18.04 | 0.24.1 | 10.0 | 7.5 | 2.4 | OK |
| 2.0.1 | 3.6.8 | Ubuntu 18.04 | 0.24.1 | - | - | - | OK |
| v2.0.0-alpha0 | 3.6 | Ubuntu 18.10 | 0.20 | 10.0 | 7.5 | 2.4 | seg fault error  |
| v2.0.0-alpha0 | 3.6 | Ubuntu 18.10 | 0.20 | - | - | - | OK |
| v2.0.0-alpha0 | 3.6 | Ubuntu 16.04 | 0.20 | 10.0 | 7.5 | 2.4 | TODO |
| v2.0.0-alpha0 | 3.6 | Ubuntu 16.04 | 0.20 | - | - | - | TODO |
| 1.9.0 | 3.6 | Ubuntu 16.04 | - | - | 0.19 | - | OK |
| 1.9.0 | 3.6 | Ubuntu 16.04 | 0.19 | 9.0 | 7.1 | - | OK |
| 1.9.0 | 3.6 | Ubuntu 16.04 | 0.19 | 9.1 | 7.1 | - | OK |
| 1.9.0 | 3.6 | Ubuntu 16.04 | 0.19 | 9.2 | 7.1 | - | OK |
| 1.9.0 | 3.6 | CentOS 6.6 | - | 0.19 | - | - | OK |
| 1.9.0 | 3.6 | CentOS 6.6 | 0.19 | 9.0 | 7.1 | - | OK |
| 1.9.0 | 3.6 | CentOS 6.6 | 0.19 | 9.1 | 7.1 | - | OK |
| 1.9.0 | 3.6 | CentOS 6.6 | 0.19 | 9.2 | 7.1 | - | OK |
| 1.15.0 | 3.7.5 | Ubuntu 18.04 | 0.24.1 | - | - | - | seg fault error |
| 1.15.0 | 3.6 | Ubuntu 18.04 | 0.24.1 | - | - | - | seg fault error |
| 1.15.0 | 3.6.12 | Ubuntu 18.04 | 0.26.1 | 10.2 | 7.6 | 2.1 | OK |
| 1.15.0 | 3.6.12 | Ubuntu 18.04 | 0.26.1 | - | - | - | OK |

## Package Sources

* [bazel==0.26.1](https://github.com/bazelbuild/bazel/releases/tag/0.26.1)
* [CUDA*.run <= 10.2](https://developer.nvidia.com/cuda-toolkit-archive)
* [libnccl2](https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/)

## Repo Tree

```bash
. #repo:docker-tensorflow-builder
├── Hadrien Mary <hadrien.mary@gmail.com>
│    └── Dimitri Gerin <dimitri.gerin@gmail.com>
└────────└── Sar Malik <github.com/SarMalik>
```

## License

MIT License. See [LICENSE](LICENSE).
