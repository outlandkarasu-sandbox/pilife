FROM library/debian@sha256:125f346eac7055d8e1de1b036b1bd39781be5bad3d36417c109729d71af0cd73 AS sysroot
RUN apt update \
  && apt install -y \
    xz-utils \
    curl \
  && apt clean \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /tmp/sysroot \
  && curl -L https://downloads.raspberrypi.org/raspios_lite_armhf/archive/2022-01-28-13:51/root.tar.xz \
         -o /tmp/sysroot/root.tar.xz \
  && cd /tmp/sysroot \
  && tar xvJf root.tar.xz /usr/lib /usr/include \
  && rm root.tar.xz

FROM library/debian@sha256:125f346eac7055d8e1de1b036b1bd39781be5bad3d36417c109729d71af0cd73 AS ldc
RUN apt update \
  && apt install -y \
    libxml2 \
    curl \
    gnupg \
    xz-utils \
    gcc-arm-linux-gnueabihf \
  && apt clean \
  && rm -rf /var/lib/apt/lists/* \
  && adduser ldc

USER ldc
WORKDIR /home/ldc

COPY cross-compiler/install.sh install.sh
RUN ./install.sh ldc-1.28.1

FROM ldc as druntime

USER root

RUN apt update \
  && apt install -y \
    build-essential \
    ninja-build \
    cmake \
  && apt clean \
  && rm -rf /var/lib/apt/lists/*

USER ldc
WORKDIR /home/ldc

RUN . ./dlang/ldc-1.28.1/activate \
  && CC=arm-linux-gnueabihf-gcc ldc-build-runtime \
    --ninja \
    --dFlags="-mtriple=arm-linux-gnueabihf;-mcpu=arm1176jzf-s" \
  && mkdir /tmp/druntime \
  && cp ./ldc-build-runtime.tmp/lib/* /tmp/druntime \
  && rm -rf ./ldc-build-runtime.tmp

FROM ldc

COPY --from=sysroot --chown=ldc:ldc /tmp/sysroot ./sysroot
COPY --from=druntime --chown=ldc:ldc /tmp/druntime ./druntime

RUN echo ". ~/dlang/ldc-1.28.1/activate" >> ~/.bashrc \
  && mkdir ./pilife

COPY --chown=ldc:ldc ldc2.conf ./pilife/ldc2.conf
COPY --chown=ldc:ldc dub.json ./pilife/dub.json
COPY --chown=ldc:ldc dub.selections.json ./pilife/dub.selections.json
#RUN mkdir ./pilife/source \
# && echo "void main() {}" > ./pilife/source/app.d \
# && . ./dlang/ldc-1.28.1/activate \
# && cd ./pilife \
# && dub build --arch=arm-linux-gnueabihf

