#!/bin/bash -e
#
# testfull.sh: Run testfull.sh with a variety of different arguments for all
# released versions.

. ./common.sh

platforminfo > $datadir/platforminfo.txt

for version in $(alltags); do
  buildversion $version
  runfull $version
  runfull $version -b1024 -S8
  # Use rollsum for versions that support rabinkarp
  if [[ "$version" > "v2.1.0" ]]; then
    runfull $version -Rrollsum
    runfull $version -b1024 -S8 -Rrollsum
  fi
  # Use min strongsum size for versions that support it.
  if [[ "$version" > "v2.2.1" ]]; then
    runfull $version -S-1
    runfull $version -b1024 -S-1
  fi
done;
