# Copyright 2025 Cloudera. All Rights Reserved.
FROM ubuntu:24.04
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
  emacs-nox \
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
  ffmpeg \
  fonts-roboto \
  fonts-dejavu && \
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



WORKDIR /build

ENV PYTHON3_VERSION=3.12.8 \
    ML_RUNTIME_KERNEL="Python 3.12"

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    libsqlite3-0 \
    media-types \
    libpq-dev \
    libkrb5-dev && \
    apt-get autoremove -y --purge && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY etc/pip.conf /etc/pip.conf

ADD build/python-prebuilt-3.12.8-20241205-pkg.tar.gz /usr/local
COPY requirements/python-standard-packages/requirements-3.12.txt /build/requirements.txt

RUN \
    ldconfig && \
    pip3 config set install.user false && \
    pip3 install --no-cache-dir --no-warn-script-location -r requirements.txt && \
    rm -rf /build && \
    cd /root && \
    rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
    rm -rf /tmp/*

ENV ML_RUNTIME_EDITOR="PBJ Workbench" \
    ML_RUNTIME_EDITION="Standard" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py" \
    JUPYTERLAB_WORKSPACES_DIR=/tmp

COPY requirements/pbj-workbench-base/requirements-3.12.txt /build/requirements.txt

COPY etc/cloudera.mplstyle /etc/cloudera.mplstyle

RUN pip3 install --no-cache-dir --no-warn-script-location -r /build/requirements.txt && \
    rm -rf /build

ENV ML_RUNTIME_KERNEL="PBJ Scala 2.12" \
    ML_RUNTIME_JUPYTER_KERNEL_NAME="apache_toree_scala" \
    ML_RUNTIME_LANGUAGE_EXECUTABLE_PATH="/usr/local/share/chunker/chunker.sh" \
    ML_RUNTIME_DESCRIPTION="PBJ Workbench Scala runtime provided by Cloudera"

COPY scala/chunker.sh /usr/local/share/chunker/
COPY scala/chunker /tmp/chunker
COPY scala/toree.patch /tmp

RUN \
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/scalasbt-release.gpg] https://repo.scala-sbt.org/scalasbt/debian all main" >/etc/apt/sources.list.d/sbt.list && \
  curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | gpg --dearmor >/etc/apt/trusted.gpg.d/scalasbt-release.gpg && \
  apt-get update && \
  apt-get install --no-install-recommends -y sbt && \
  apt-get install --no-install-recommends -y openjdk-8-jdk-headless && \
  cd /tmp/chunker && \
  sbt assembly && \
  mv target/scala-2.11/ScalaChunker-assembly-1.1.jar /usr/local/share/chunker && \
  cd /tmp && \
  git clone https://github.com/apache/incubator-toree.git && \
  cd incubator-toree && \
  git checkout 1e7e0c058f965eaf09044961af592626ddc0a5cc && \
  patch -p1 </tmp/toree.patch && \
  ln -s /usr/bin/true /usr/bin/docker && \
  make build pip-release && \
  rm -f /usr/bin/docker && \
  cd dist/toree-pip && \
  pip3 install . && \
  jupyter toree install --spark_home=/opt/spark && \
  apt-get remove -y --purge openjdk-8-jdk-headless && \
  cd /root && \
  rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
  apt-get autoremove -y --purge && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  rm -rf /tmp/*




ENV \
    ML_RUNTIME_METADATA_VERSION=2 \ 
    ML_RUNTIME_FULL_VERSION=2025.01.3-b8 \
    ML_RUNTIME_SHORT_VERSION=2025.01 \
    ML_RUNTIME_MAINTENANCE_VERSION=3 \
    ML_RUNTIME_GIT_HASH=25ac39f9f3d2cc7da6435e7f12fd7cda754da5fe \
    ML_RUNTIME_GBN=64692867

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