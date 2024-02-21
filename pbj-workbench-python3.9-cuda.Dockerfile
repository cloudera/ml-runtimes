# Copyright 2024 Cloudera. All Rights Reserved.
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04
RUN apt-key del 7fa2af80 && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub


RUN \
  addgroup --gid 8536 cdsw && \
  adduser --disabled-password --gecos "CDSW User" --uid 8536 --gid 8536 cdsw


RUN for i in /etc /etc/alternatives; do \
  if [ -d ${i} ]; then chmod 777 ${i}; fi; \
  done

RUN chown cdsw /

RUN for i in /bin /etc /opt /sbin /usr; do \
  if [ -d ${i} ]; then \
    chown cdsw ${i}; \
    find ${i} -type d -exec chown cdsw {} +; \
  fi; \
  done

WORKDIR /
ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=en_US.UTF-8 LANG=C.UTF-8 LANGUAGE=en_US.UTF-8 \
    TERM=xterm


RUN apt-get update && apt-get dist-upgrade -y && \
  apt-get update && apt-get install -y --no-install-recommends \
  locales \
  apt-transport-https \
  krb5-user \
  xz-utils \
  git \
  ssh \
  unzip \
  gzip \
  curl \
  nano \
  emacs-nox \
  wget \
  ca-certificates \
  zlib1g-dev \
  libbz2-dev \
  liblzma-dev \
  libssl-dev \
  libsasl2-dev \
  libsasl2-2 \
  libsasl2-modules-gssapi-mit \
  libzmq3-dev \
  cpio \
  cmake \
  make \
  libgl-dev \
  libjpeg-dev \
  libpng-dev \
  ffmpeg \
  && \
  apt-get clean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/* && \
  rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_rsa_key && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen


RUN wget https://packagecloud.io/github/git-lfs/packages/ubuntu/focal/git-lfs_3.4.1_amd64.deb/download.deb?distro_version_id=210 -O git-lfs.deb && \
  echo "7f4b65f2cc61fc2741641003784ea605727b629a4d28a8ec7a3052068122dcc6a8c41a45a4df8e34f94fe8bc143c6c8754c03824ad8358b70083c66a1a7187a4  git-lfs.deb" | sha512sum -c - && \
  dpkg -i git-lfs.deb && \
  rm git-lfs.deb


RUN rm -f /etc/krb5.conf

RUN mkdir -p /etc/pki/tls/certs
RUN ln -s /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt

RUN ln -s /usr/lib/x86_64-linux-gnu/libsasl2.so.2 /usr/lib/x86_64-linux-gnu/libsasl2.so.3

ENV PATH /home/cdsw/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/bin

ENV SHELL /bin/bash

ENV HADOOP_ROOT_LOGGER WARN,console



WORKDIR /build

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libsqlite3-0 \
        mime-support \
        libpq-dev \
        gcc \
        g++ \
        libkrb5-dev \
    && \
    rm -rf /var/lib/apt/lists/*

ENV PYTHON3_VERSION=3.9.18 \
    ML_RUNTIME_KERNEL="Python 3.9"

ADD build/python-3.9.18-pkg.tar.gz /usr/local

COPY etc/pip.conf /etc/pip.conf
COPY requirements/python-standard-packages/requirements-3.9.txt /build/requirements.txt

RUN \
    ldconfig && \
    pip3 config set install.user false && \
    SETUPTOOLS_USE_DISTUTILS=stdlib pip3 install \
        --no-cache-dir \
        --no-warn-script-location \
        -r requirements.txt && \
    rm -rf /build


ENV ML_RUNTIME_EDITOR="PBJ Workbench" \
    ML_RUNTIME_EDITION="Standard" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py" \
    JUPYTERLAB_WORKSPACES_DIR=/tmp

COPY requirements/pbj-workbench-base/requirements-3.9.txt /build/requirements.txt

COPY etc/cloudera.mplstyle /etc/cloudera.mplstyle

RUN \
    SETUPTOOLS_USE_DISTUTILS=stdlib pip3 install \
        --no-cache-dir \
        --no-warn-script-location \
        -r /build/requirements.txt && \
    rm -rf /build

ENV ML_RUNTIME_JUPYTER_KERNEL_NAME="python3" \
    ML_RUNTIME_DESCRIPTION="PBJ Workbench Python runtime provided by Cloudera"

ENV ML_RUNTIME_EDITION="Nvidia GPU" \
    ML_RUNTIME_DESCRIPTION="Python runtime with CUDA libraries provided by Cloudera" \
    ML_RUNTIME_CUDA_VERSION="11.8.0"




ENV \
    ML_RUNTIME_METADATA_VERSION=2 \ 
    ML_RUNTIME_FULL_VERSION=2024.02.1-b4 \
    ML_RUNTIME_SHORT_VERSION=2024.02 \
    ML_RUNTIME_MAINTENANCE_VERSION=1 \
    ML_RUNTIME_GIT_HASH=522971789d992f2c6fbbb5f8a63301b9a21cbe3e \
    ML_RUNTIME_GBN=50300524

LABEL \
    com.cloudera.ml.runtime.runtime-metadata-version=$ML_RUNTIME_METADATA_VERSION \
    com.cloudera.ml.runtime.editor=$ML_RUNTIME_EDITOR \
    com.cloudera.ml.runtime.edition=$ML_RUNTIME_EDITION \
    com.cloudera.ml.runtime.description=$ML_RUNTIME_DESCRIPTION \
    com.cloudera.ml.runtime.kernel=$ML_RUNTIME_KERNEL \
    com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
    com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
    com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION \
    com.cloudera.ml.runtime.git-hash=$ML_RUNTIME_GIT_HASH \
    com.cloudera.ml.runtime.gbn=$ML_RUNTIME_GBN \
    com.cloudera.ml.runtime.cuda-version=$ML_RUNTIME_CUDA_VERSION
