# Copyright 2023 Cloudera. All Rights Reserved.
FROM ubuntu:20.04

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
  git-lfs \
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
  && \
  apt-get clean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/* && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

RUN rm -f /etc/krb5.conf

RUN mkdir -p /etc/pki/tls/certs
RUN ln -s /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt

RUN ln -s /usr/lib/x86_64-linux-gnu/libsasl2.so.2 /usr/lib/x86_64-linux-gnu/libsasl2.so.3

ENV PATH /home/cdsw/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/bin

ENV SHELL /bin/bash

ENV HADOOP_ROOT_LOGGER WARN,console



RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libsqlite3-0 \
        mime-support \
        libpq-dev \
        gcc \
        g++ \
    && \
    rm -rf /var/lib/apt/lists/*


RUN apt-get update && apt-get install -y --no-install-recommends python3.8 python3.8-dev python3-pip python-is-python3

COPY etc/pip.conf /etc/pip.conf
RUN pip3 config set install.user false


ENV ML_RUNTIME_KERNEL="R 4.1" \
    ML_RUNTIME_EDITION=Standard \
    ML_RUNTIME_DESCRIPTION="Standard edition R runtime provided by Cloudera" \
    R_VERSION=4.1.1

COPY build-utils/r/r-runtime-dependencies.txt /build/

ADD build/r-4.1.1-community-pkg.tar.gz /usr/local

RUN \
    apt-get update && \
    cat /build/r-runtime-dependencies.txt | \
      sed '/^$/d; /^#/d; s/#.*$//' | \
      xargs apt-get install -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /build && \
    chown -R cdsw:cdsw /usr/local/lib/R/etc && \
    ln -sf /usr/lib/x86_64-linux-gnu/libopenblas.so.0 /usr/local/lib/R/lib/libRblas.so

COPY etc/Rprofile.site /usr/local/lib/R/etc/Rprofile.site
COPY etc/Rserv.conf /etc/Rserv.conf

RUN chown cdsw:cdsw /usr/local/lib/R/etc/Rprofile.site


ENV ML_RUNTIME_EDITOR="PBJ Workbench" \
    ML_RUNTIME_EDITION="Standard" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py" \
    JUPYTERLAB_WORKSPACES_DIR=/tmp

COPY requirements/pbj-workbench-base/requirements-3.8.txt /build/requirements.txt

COPY etc/cloudera.mplstyle /etc/cloudera.mplstyle

RUN \
    SETUPTOOLS_USE_DISTUTILS=stdlib pip3 install \
        --no-cache-dir \
        --no-warn-script-location \
        -r /build/requirements.txt && \
    rm -rf /build

ENV ML_RUNTIME_JUPYTER_KERNEL_NAME="r4.1" \
    ML_RUNTIME_DESCRIPTION="PBJ Workbench R runtime provided by Cloudera"

RUN \
    /bin/bash -c "echo -e \"install.packages('IRkernel')\nIRkernel::installspec(prefix='/usr/local',name = '${ML_RUNTIME_JUPYTER_KERNEL_NAME}', displayname = '${ML_RUNTIME_KERNEL}')\" | R --no-save" && \
    rm -rf /build



ENV \
    ML_RUNTIME_METADATA_VERSION=2 \ 
    ML_RUNTIME_FULL_VERSION=2023.08.2-b8 \
    ML_RUNTIME_SHORT_VERSION=2023.08 \
    ML_RUNTIME_MAINTENANCE_VERSION=2 \
    ML_RUNTIME_GIT_HASH=cdee6e30026323b76feda974d3b6fba48bee5688 \
    ML_RUNTIME_GBN=45253874

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
