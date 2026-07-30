# Copyright 2026 Cloudera. All Rights Reserved.
FROM ubuntu:25.10
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
  unixodbc \
  unixodbc-dev \
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



WORKDIR /build

ENV PYTHON3_VERSION=3.11.15 \
    ML_RUNTIME_KERNEL="Python 3.11"

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

ADD build/python-prebuilt-3.11.15-20260309-freshline-pkg.tar.gz /usr/local
COPY requirements/python-standard-packages/requirements-3.11.txt /build/requirements.txt

RUN \
    ldconfig && \
    pip3 config set install.user false && \
    pip3 install --no-cache-dir --no-warn-script-location -r requirements.txt && \
    rm -rf /build && \
    cd /root && \
    rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
    rm -rf /tmp/*

ENV ML_RUNTIME_KERNEL="R 4.5" \
    ML_RUNTIME_EDITION="Freshline" \
    ML_RUNTIME_DESCRIPTION="Freshline edition R runtime provided by Cloudera" \
    R_VERSION=4.5.2

COPY build-utils/r/r-runtime-dependencies.txt /build/
COPY r/python*.deb /tmp/

ADD build/r-prebuilt-4.5.2-20251124-freshline-pkg.tar.gz /usr/local

RUN \
    dpkg -i /tmp/python*.deb && \
    apt-get update && \
    cat /build/r-runtime-dependencies.txt | \
      sed '/^$/d; /^#/d; s/#.*$//' | \
      xargs apt-get install -y --no-install-recommends && \
    rm -rf /build && \
    chown -R cdsw:cdsw /usr/local/lib/R/etc && \
    echo '/usr/local/lib/R/lib' > /etc/ld.so.conf.d/cloudera-R.conf && \
    ldconfig && \
    cd /root && \
    rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
    apt-get autoremove -y --purge && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*
    

COPY etc/Rprofile.site /usr/local/lib/R/etc/Rprofile.site
COPY etc/Rserv.conf /etc/Rserv.conf

RUN chown cdsw:cdsw /usr/local/lib/R/etc/Rprofile.site

ENV ML_RUNTIME_EDITOR="PBJ Workbench" \
    ML_RUNTIME_EDITION="Freshline" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py" \
    JUPYTERLAB_WORKSPACES_DIR=/tmp \
    IPYTHONDIR=/tmp/.ipython

COPY requirements/pbj-workbench-base/requirements-3.11.txt /build/requirements.txt

COPY etc/cloudera.mplstyle /etc/cloudera.mplstyle

RUN pip3 install --no-cache-dir --no-warn-script-location -r /build/requirements.txt && \
    rm -rf /build

ENV ML_RUNTIME_JUPYTER_KERNEL_NAME="python3" \
    ML_RUNTIME_DESCRIPTION="PBJ Workbench Python runtime provided by Cloudera"
    
RUN \
  cd /root && \
  rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
  rm -rf /tmp/*

ENV ML_RUNTIME_EDITOR="JupyterLab" \
    ML_RUNTIME_EDITION="Freshline" \
    ML_RUNTIME_DESCRIPTION="Jupyterlab Python runtime provided by Cloudera"

COPY requirements/pbj-jupyterlab/requirements-3.11.txt /build/requirements.txt
COPY etc/jupyterlab.sh /usr/local/bin/jupyterlab.sh
COPY etc/jupyter_lab_config.py /usr/local/etc/jupyter_lab_config.py
COPY etc/tectonic-nbconvert /usr/local/bin/tectonic-nbconvert
COPY etc/read_default_copilot_model.py /usr/local/bin/read_default_copilot_model.py
COPY etc/read_default_copilot_embedding_model.py /usr/local/bin/read_default_copilot_embedding_model.py

RUN \
  curl -fsSL --retry 3 --retry-delay 2 -o /tmp/nodejs.tar.xz https://nodejs.org/dist/v20.19.0/node-v20.19.0-linux-x64.tar.xz && \
  tar xJ -f /tmp/nodejs.tar.xz -C /usr/local --strip-components 1 && \
  npm install -g npm@10.5.2 && \
  cd /tmp && \
  PANDOC_VERSION=3.1.3 && \
  PANDOC_TARBALL="pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz" && \
  curl -fsSL --retry 3 --retry-delay 2 -o pandoc.tar.gz "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/${PANDOC_TARBALL}" && \
  tar xzf pandoc.tar.gz && \
  install -m 0755 "/tmp/pandoc-${PANDOC_VERSION}/bin/pandoc" /usr/local/bin/pandoc && \
  . /etc/os-release && \
  if [ "$ID" = "ubuntu" ]; then \
    apt-get update && apt-get install -y --no-install-recommends texlive-binaries; \
  fi && \
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
  if [ "$ID" = "ubuntu" ]; then \
    apt-get autoremove -y --purge && \
    apt-get clean && rm -rf /var/lib/apt/lists/*; \
    fi && \
  rm -rf /tmp/*

ENV ML_RUNTIME_JUPYTER_KERNEL_NAME="r4.5" \
    ML_RUNTIME_DESCRIPTION="${ML_RUNTIME_EDITOR} R runtime provided by Cloudera" \
    CML_JUPYTER_ENSURE_NATIVE_KERNEL="False"


RUN \
    /bin/echo -e 'r <- getOption("repos")\nr["CRAN"] <- "https://packagemanager.posit.co/cran/__linux__/noble/2025-05-16"\noptions(repos=r)\ninstall.packages("IRkernel")\nIRkernel::installspec(prefix="/usr/local",name = "'${ML_RUNTIME_JUPYTER_KERNEL_NAME}'", displayname = "'${ML_RUNTIME_KERNEL}'")\nprint("done!")' | R --no-save && \
    jupyter kernelspec remove -y python3 && \
    rm -rf /build && \
    echo "set enable-bracketed-paste off" >> /etc/inputrc && \
    cd /root && \
    rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
    apt-get autoremove -y --purge && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*



ENV \
    ML_RUNTIME_METADATA_VERSION=2 \ 
    ML_RUNTIME_FULL_VERSION=2026.04.2-b16 \
    ML_RUNTIME_SHORT_VERSION=2026.04 \
    ML_RUNTIME_MAINTENANCE_VERSION=2 \
    ML_RUNTIME_GIT_HASH=39067be37a7f846368777330082e234b9cb68857 \
    ML_RUNTIME_GBN=81154741

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