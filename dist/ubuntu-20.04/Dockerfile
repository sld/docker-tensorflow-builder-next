FROM ubuntu:20.04

ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update && apt install -y \
    build-essential \
    curl \
    git \
    wget \
    libjpeg-dev \
    openjdk-8-jdk \
    gcc-7 \
    g++-7 \
    && rm -rf /var/lib/lists/*

# Install Anaconda
WORKDIR /
RUN wget "https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O "miniconda.sh" && \
    bash "miniconda.sh" -b -p "/conda" && \
    rm miniconda.sh && \
    echo PATH='/conda/bin:$PATH' >> /root/.bashrc && \
    /conda/bin/conda config --add channels conda-forge && \
    /conda/bin/conda update --yes -n base conda && \
    /conda/bin/conda update --all --yes

COPY build.sh /build.sh
COPY cuda.sh /cuda.sh

CMD bash build.sh
