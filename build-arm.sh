#!/bin/sh

cd `dirname $0`

dub build --compiler=./ldc-arm.sh --force

