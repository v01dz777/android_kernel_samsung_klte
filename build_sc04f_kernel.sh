#!/bin/bash

export BUILD_TARGET=AOSP
. sc04f.config

time ./_build-bootimg.sh $1
