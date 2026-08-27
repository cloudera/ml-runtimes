# Copyright 2026 Cloudera. All Rights Reserved.
FROM cgr.dev/chainguard/wolfi-base
RUN apk update && apk add --no-cache bash shadow openjdk-17 python-3.14 py3.14-pip
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH="$JAVA_HOME/bin:$PATH"
ENV LANG=en_US.UTF-8
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
RUN ln -s $JAVA_HOME /usr/lib/jvm/default-jvm

USER root
ENV HOME=/root

CMD []
ENTRYPOINT []

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8 LANGUAGE=C.UTF-8

RUN groupadd -g 8536 cdsw && \
    useradd -u 8536 -g 8536 --shell /bin/bash -c "CDSW User" -m cdsw

RUN printf '/bin/bash\n' >> /etc/shells

RUN for i in /etc /etc/alternatives; do \
  if [ -d ${i} ]; then chmod 777 ${i}; fi; \
  done

RUN chown cdsw /

RUN chmod u+w /usr/lib /usr/bin

WORKDIR /

ENV TERM=xterm

RUN apk update && apk add --no-cache \
    gcc \
    glibc-locales \
    gnupg \
    krb5 \
    krb5-dev \
    xz \
    git \
    git-lfs \
    openssh-client=10.2_p1-r7 \
    openssh=10.2_p1-r7 \
    zip \
    unzip \
    gzip \
    curl \
    nano \
    wget \
    less \
    ca-certificates \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    openssh-keygen=10.2_p1-r7 \
    openssh-server=10.2_p1-r7 \
    openssh-server-config=10.2_p1-r7 \
    openssh-sftp-server=10.2_p1-r7 \
    libcrypto3=3.6.1-r2 \
    libssl3=3.6.1-r2 \
    openssl-dev=3.6.1-r3 \
    unixodbc \
    unixodbc-dev \
    cyrus-sasl-dev \
    cyrus-sasl \
    cyrus-sasl-heimdal \
    zeromq-dev \
    cpio \
    cmake \
    build-base \
    patch autoconf automake \
    mesa-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    ttf-dejavu \
    tzdata \
    diffutils \
    findutils \
    procps \
    busybox \ 
    ffmpeg \
    emacs \
    sqlite \
    mailcap \
    postgresql-dev \
    libffi-dev

  
RUN for i in /bin /etc /opt /sbin /usr; do \
  if [ -d ${i} ]; then \
    chown cdsw ${i}; \
    find ${i} -type d -exec chown cdsw {} +; \
  fi; \
  done

RUN rm -f /etc/krb5.conf

ENV PATH=/home/cdsw/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    SHELL=/bin/bash

ENV HADOOP_ROOT_LOGGER=WARN,console


WORKDIR /build

ENV PYTHON3_VERSION=3.14 \
    ML_RUNTIME_KERNEL="Python 3.14"




RUN command -v python3.14 && \
    command -v pip3.14 && \
    command -v python3 && \
    command -v pip3 && \
    command -v python && \
    command -v pip && \
    [ -e /usr/bin/python ] && \
    [ -e /usr/bin/pip ]

RUN ln -s /usr/sbin/python3 /usr/local/bin/python3


COPY etc/pip.conf /etc/pip.conf
COPY requirements/python-comcloud-chainguard-extras/requirements-3.14.txt /build/requirements_extras.txt
COPY requirements/python-standard-packages/requirements-3.14.txt /build/requirements.txt


RUN pip3 config set install.user false && \
    pip3 install \
        --no-cache-dir \
        --no-warn-script-location \
        -r /build/requirements_extras.txt && \
    pip3 install \
        --no-cache-dir \
        --no-warn-script-location \
        -r /build/requirements.txt 


RUN rm -rf /build

ENV ML_RUNTIME_EDITOR="PBJ Workbench" \
    ML_RUNTIME_EDITION="Hardened" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py" \
    JUPYTERLAB_WORKSPACES_DIR=/tmp \
    IPYTHONDIR=/tmp/.ipython

COPY requirements/pbj-workbench-base/requirements-3.14.txt /build/requirements.txt

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
    ML_RUNTIME_EDITION="Hardened" \
    ML_RUNTIME_DESCRIPTION="Jupyterlab Python runtime provided by Cloudera"

COPY requirements/pbj-jupyterlab/requirements-3.14.txt /build/requirements.txt
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



ENV \
    ML_RUNTIME_METADATA_VERSION=3 \ 
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