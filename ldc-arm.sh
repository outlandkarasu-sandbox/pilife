#!/bin/sh

ldc2 -mtriple=arm-linux-gnueabihf -mcpu=arm1176jzf-s -gcc=arm-linux-gnueabihf-gcc -L=-L/home/ldc/druntime $@
