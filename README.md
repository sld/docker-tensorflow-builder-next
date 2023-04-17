# Compile Tensorflow on Docker ubuntu22.04

Docker images to compile TensorFlow yourself.

Tensorflow only provide a limited set of build and it can be challenging to compile yourself on certain configuration. With this `Dockerfile`, you should be able to compile TensorFlow on any Linux platform that run Docker.

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
### CPUflags

```
grep flags -m1 /proc/cpuinfo | cut -d ":" -f 2 | tr '[:upper:]' '[:lower:]' | { read FLAGS; OPT="-march=native"; for flag in $FLAGS; do case "$flag" in "sse4_1" | "sse4_2" | "ssse3" | "fma" | "cx16" | "popcnt" | "avx" | "avx2") OPT+=" -m$flag";; esac; done; MODOPT=${OPT//_/\.}; echo "$MODOPT"; }
```

#### Modify Build Params

Clone the [build/compile.tf{version}-cuda{version}.sh](/build) starter script with bash params for targeting wheel compilation. 

Refer to tested configs listed in the [Builds](#Builds) section.

```bash
$ cat build/compile.*.sh >> vim
```

Check Dockerfile for change params

export PYTHON_VERSION=3.6.12
export TF_VERSION_GIT_TAG=v1.15.0
export USE_GPU=1
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

## License

MIT License. See [LICENSE](LICENSE).
