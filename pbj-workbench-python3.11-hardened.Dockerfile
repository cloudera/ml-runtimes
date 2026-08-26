# Copyright 2026 Cloudera. All Rights Reserved.
FROM cgr.dev/chainguard/wolfi-base

RUN apk update && apk add --no-cache bash shadow openjdk-17 python-3.11 py3.11-pip

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
    binutils \
    gcc \
    glibc-dev \
    glibc-locales \
    gmp \
    gnupg \
    isl \
    libatomic \
    libstdc++-dev \
    libgomp \
    libquadmath \
    linux-headers \
    mpc \
    mpfr \
    pkgconf \
    posix-cc-wrappers \
    krb5 \
    krb5-dev \
    xz \
    git \
    git-lfs \
    openssh-client \
    openssh \
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
    openssl-dev \
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
    libzstd1 \
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

ENV PYTHON3_VERSION=3.11 \
    ML_RUNTIME_KERNEL="Python 3.11"




RUN command -v python3.11 && \
    command -v pip3.11 && \
    command -v python3 && \
    command -v pip3 && \
    command -v python && \
    command -v pip && \
    [ -e /usr/bin/python ] && \
    [ -e /usr/bin/pip ]

RUN apk add --no-cache python-3.11-dev python-3.11-base-dev

RUN ln -s /usr/sbin/python3 /usr/local/bin/python3


COPY etc/pip.conf /etc/pip.conf
COPY requirements/py311/python-comcloud-chainguard-extras-requirements.txt /build/requirements_extras.txt
COPY requirements/py311/python-standard-packages-requirements.txt /build/requirements.txt


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

COPY requirements/py311/pbj-workbench-base-requirements.txt /build/requirements.txt

COPY etc/cloudera.mplstyle /etc/cloudera.mplstyle

RUN pip3 install --no-cache-dir --no-warn-script-location -r /build/requirements.txt && \
    rm -rf /build

ENV ML_RUNTIME_JUPYTER_KERNEL_NAME="python3" \
    ML_RUNTIME_DESCRIPTION="PBJ Workbench Python runtime provided by Cloudera"
    
RUN \
  cd /root && \
  rm -rf .cache .ipython .ivy2 .sbt .npm .yarn && \
  rm -rf /tmp/*



ENV \
    ML_RUNTIME_METADATA_VERSION=3 \ 
    ML_RUNTIME_FULL_VERSION=2026.08.1-b5 \
    ML_RUNTIME_SHORT_VERSION=2026.08 \
    ML_RUNTIME_MAINTENANCE_VERSION=1 \
    ML_RUNTIME_GIT_HASH=f36d1ea370c0f6da7fee102265bfbd697c47694d \
    ML_RUNTIME_GBN=81754395

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