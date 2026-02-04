# Copyright 2026 Cloudera. All Rights Reserved.
FROM nvidia/cuda:12.5.1-devel-ubuntu24.04
ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=en_US.UTF-8 LANG=C.UTF-8 LANGUAGE=en_US.UTF-8 \
    TERM=xterm \
    PATH=/home/cdsw/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/bin \
    SHELL=/bin/bash \
    HADOOP_ROOT_LOGGER=WARN,console


RUN apt-get update && apt-get dist-upgrade -y && \
  apt-get install -y --no-install-recommends \
  locales \
  gpg \
  apt-transport-https \
  krb5-user \
  xz-utils \
  git \
  git-lfs \
  ssh \
  zip \
  unzip \
  gzip \
  curl \
  nano \
  wget \
  less \
  ca-certificates ca-certificates-java \
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
  build-essential \
  patch autoconf automake \
  libgl-dev \
  libjpeg-dev \
  libpng-dev \
  fonts-roboto \
  fonts-dejavu \
  tzdata && \
  apt-get clean && \
  apt-get autoremove --purge && \
  rm -rf /var/lib/apt/lists/* && \
  rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_rsa_key && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen && \
  addgroup --gid 8536 cdsw && \
  adduser --disabled-password --comment "CDSW User" --uid 8536 --gid 8536 cdsw && \
  for i in /etc /etc/alternatives; do \
    if [ -d ${i} ]; then chmod 777 ${i}; fi; \
  done && \
  chown cdsw / && \
  for i in /bin /etc /opt /sbin /usr; do \
    if [ -d ${i} ]; then \
      find ${i} -type d -exec chown cdsw {} +; \
    fi; \
  done && \
  ln -s /usr/lib/x86_64-linux-gnu/libsasl2.so.2 /usr/lib/x86_64-linux-gnu/libsasl2.so.3 && \
  mkdir -p /etc/pki/tls/certs && \
  ln -s /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt



RUN apt-get update && apt-get dist-upgrade -y && \
  apt-get install -y --no-install-recommends \
  ffmpeg \
  emacs-nox && \
  apt-get clean && \
  apt-get autoremove --purge && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /build

ENV PYTHON3_VERSION=3.10.19 \
    ML_RUNTIME_KERNEL="Python 3.10"

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    libsqlite3-0 \
    media-types \
    libpq-dev \
    libffi-dev \
    libkrb5-dev && \
    apt-get autoremove -y --purge && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY etc/pip.conf /etc/pip.conf

ADD build/python-prebuilt-3.10.19-20251124-pkg.tar.gz /usr/local
COPY requirements/python-standard-packages/requirements-3.10.txt /build/requirements.txt

RUN \
    ldconfig && \
    pip3 config set install.user false && \
    pip3 install --no-cache-dir --no-warn-script-location -r requirements.txt && \
    rm -rf /build && \
    cd /root && \
    rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
    rm -rf /tmp/*

ENV ML_RUNTIME_EDITOR="PBJ Workbench" \
    ML_RUNTIME_EDITION="Nvidia GPU" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py" \
    JUPYTERLAB_WORKSPACES_DIR=/tmp \
    IPYTHONDIR=/tmp/.ipython

COPY requirements/pbj-workbench-base/requirements-3.10.txt /build/requirements.txt

COPY etc/cloudera.mplstyle /etc/cloudera.mplstyle

RUN pip3 install --no-cache-dir --no-warn-script-location -r /build/requirements.txt && \
    rm -rf /build

ENV ML_RUNTIME_JUPYTER_KERNEL_NAME="python3" \
    ML_RUNTIME_DESCRIPTION="PBJ Workbench Python runtime provided by Cloudera"
    
RUN \
  cd /root && \
  rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
  apt-get autoremove -y --purge && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  rm -rf /tmp/*

ENV ML_RUNTIME_EDITOR="JupyterLab" \
    ML_RUNTIME_EDITION="Nvidia GPU" \
    ML_RUNTIME_DESCRIPTION="Jupyterlab Python runtime provided by Cloudera"

COPY requirements/pbj-jupyterlab/requirements-3.10.txt /build/requirements.txt
COPY etc/jupyterlab.sh /usr/local/bin/jupyterlab.sh
COPY etc/jupyter_lab_config.py /usr/local/etc/jupyter_lab_config.py
COPY etc/tectonic-nbconvert /usr/local/bin/tectonic-nbconvert
COPY etc/read_default_copilot_model.py /usr/local/bin/read_default_copilot_model.py
COPY etc/read_default_copilot_embedding_model.py /usr/local/bin/read_default_copilot_embedding_model.py

RUN \
  curl -fsSL --retry 3 --retry-delay 2 -o /tmp/nodejs.tar.xz https://nodejs.org/download/release/v20.8.1/node-v20.8.1-linux-x64.tar.xz && \
  tar xJ -f /tmp/nodejs.tar.xz -C /usr/local --strip-components 1 && \
  npm install -g npm@10.5.2 && \
  cd /tmp && \
  PANDOC_VERSION=3.1.3 && \
  PANDOC_TARBALL="pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz" && \
  curl -fsSL --retry 3 --retry-delay 2 -o pandoc.tar.gz "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/${PANDOC_TARBALL}" && \
  tar xzf pandoc.tar.gz && \
  install -m 0755 "/tmp/pandoc-${PANDOC_VERSION}/bin/pandoc" /usr/local/bin/pandoc && \
  apt-get update && apt-get install -y --no-install-recommends texlive-binaries && \
  TECTONIC_VERSION=0.13.1 && \
  TECTONIC_TARBALL="tectonic-${TECTONIC_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
  curl -fsSL --retry 3 --retry-delay 2 -o tectonic.tar.gz "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40${TECTONIC_VERSION}/${TECTONIC_TARBALL}" && \
  tar xzf tectonic.tar.gz && \
  install -m 0755 /tmp/tectonic /usr/local/bin/tectonic && \
  rm -f /tmp/tectonic /tmp/tectonic.tar.gz && \
  chmod +x /usr/local/bin/tectonic-nbconvert && \
  cd /usr/local && \
  ln -sf /usr/local/bin/jupyterlab.sh /usr/local/bin/ml-runtime-editor && \
  chmod +x /usr/local/bin/jupyterlab.sh && \
  pip install --no-cache-dir -r /build/requirements.txt && \
  rm -rf /build && \
  cd /usr/local && \
  tar tJf /tmp/nodejs.tar.xz | \
  cut -d/ -f2- | \
  egrep -v '^(\s*|.*/)$' | \
  xargs rm -f && \
  rm -rf /usr/local/lib/node_modules /usr/local/include/node && \
  jupyter labextension disable "@jupyterlab/apputils-extension:announcements" && \
  cd /root && \
  rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
  apt-get autoremove -y --purge && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  rm -rf /tmp/*

ENV ML_RUNTIME_EDITION="Nvidia GPU" \
    ML_RUNTIME_DESCRIPTION="Python runtime with CUDA libraries provided by Cloudera" \
    ML_RUNTIME_CUDA_VERSION="12.5.1"



ENV \
    ML_RUNTIME_METADATA_VERSION=2 \ 
    ML_RUNTIME_FULL_VERSION=2026.01.1-b6 \
    ML_RUNTIME_SHORT_VERSION=2026.01 \
    ML_RUNTIME_MAINTENANCE_VERSION=1 \
    ML_RUNTIME_GIT_HASH=6409ec7123de70a911751ad99e578040051be2df \
    ML_RUNTIME_GBN=74219765

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

WORKDIR /home/cdsw