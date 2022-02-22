#!/bin/sh

ldc2 \
    -defaultlib=phobos2-ldc,druntime-ldc \
    -link-defaultlib-shared=false \
    -mtriple=arm-linux-gnueabihf \
    -gcc=arm-linux-gnueabihf-gcc \
    -L=-L/home/ldc/druntime \
    -L=-L/home/ldc/sysroot/usr/lib \
    $@
