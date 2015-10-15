#!/bin/bash

export BUILD_TARGET=SAM
. sc04f.config

time ./_build-bootimg.sh $1
