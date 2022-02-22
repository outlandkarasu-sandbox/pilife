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
    --dFlags="-w;-mtriple=arm-linux-gnueabihf" \
    --targetSystem="Linux;UNIX" \
  && mkdir /tmp/druntime \
  && cp ./ldc-build-runtime.tmp/lib/* /tmp/druntime \
  && rm -rf ./ldc-build-runtime.tmp

FROM ldc

COPY --from=druntime --chown=ldc:ldc /tmp/druntime ./druntime

RUN echo ". ~/dlang/ldc-1.28.1/activate" >> ~/.bashrc

