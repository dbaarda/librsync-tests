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
  # Use rollsum for versions that support rabinkarp
  if [[ "$version" > "v2.1.0" || "$version" == "master" ]]; then
    runfull $version -Rrollsum
    runfull $version -b1024 -S8 -Rrollsum
  fi
  # Use min strongsum size for versions that support it.
  if [[ "$version" > "v2.2.1" || "$version" == "master" ]]; then
    runfull $version -S-1
    runfull $version -b1024 -S-1
  fi
done
