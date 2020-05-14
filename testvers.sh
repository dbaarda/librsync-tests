#!/bin/bash -e
#
# testvers.sh: Run a performance tests for particular versions.

. ./common.sh

if [ -z "$1" ]; then
  echo "Usage: $0 <versions>..."
  exit 1
fi
versions="$@"

for version in $versions; do
  buildversion $version
  runfull $version
  runfull $version -b1024 -S8
done
