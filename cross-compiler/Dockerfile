FROM library/debian@sha256:125f346eac7055d8e1de1b036b1bd39781be5bad3d36417c109729d71af0cd73 AS sysroot
RUN apt update \
  && apt install -y \
    p7zip-full \
    curl \
  && apt clean \
  && rm -rf /var/lib/apt/lists/* \
  && curl -L https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-01-28/2022-01-28-raspios-bullseye-armhf-lite.zip \
         -o /tmp/raspios.zip \
  && 7z e -o/tmp /tmp/raspios.zip '*.img' \
  && 7z e -spf -o/tmp /tmp/2022-01-28-raspios-bullseye-armhf-lite.img 1.img \
  && mkdir /tmp/sysroot \
  && 7z e -spf -o/tmp/sysroot /tmp/1.img usr/include/ usr/lib/ \
  && rm /tmp/raspios.zip /tmp/2022-01-28-raspios-bullseye-armhf-lite.img /tmp/1.img

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

COPY install.sh install.sh
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

RUN echo ". ~/dlang/ldc-1.28.1/activate" >> ~/.bashrc

