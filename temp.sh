#!/bin/bash -e
#
# testfull.sh: Run testfull.sh with a variety of different arguments for all
# released versions.

. ./common.sh
echo read common

buildversion opt/rabinkarp1
runfull rabinkarp-opt
runfull rabinkarpopt -b1024 -S8
