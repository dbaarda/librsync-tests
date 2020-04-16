#!/bin/bash -e
#
# testfull.sh: Run testfull.sh with a variety of different arguments for all
# released versions.

. ./common.sh

if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi
version=$1

blocks=1024K

old="$tmpdir/old.$blocks"
new="$tmpdir/new.$blocks"
sig="$tmpdir/sig.$blocks"
delta="$tmpdir/delta.$blocks"
out="$tmpdir/out.$blocks"

# Usage: runprofile <version> [<sigargs>...]
runprofile () {
  version=$1
  shift 1
  sigargs="$@"

  # Delete existing outputs, since We can't use rdiff -f on old binaries.
  rm -f $sig $delta $out

  $bindir/rdiff -s $sigargs signature $old $sig 2>&1
  gprof $bindir/rdiff gmon.out >$(outputfile prof_sig $version $sigargs)
  gprof -l $bindir/rdiff gmon.out >$(outputfile profl_sig $version $sigargs)

  $bindir/rdiff -s delta $sig $new $delta 2>&1
  gprof $bindir/rdiff gmon.out >$(outputfile prof_delta $version $sigargs)
  gprof -l $bindir/rdiff gmon.out >$(outputfile profl_delta $version $sigargs)

  $bindir/rdiff -s patch $old $delta $out 2>&1
  gprof $bindir/rdiff gmon.out >$(outputfile prof_patch $version $sigargs)
  gprof -l $bindir/rdiff gmon.out >$(outputfile profl_patch $version $sigargs)

  # Clean up output files. Leave input files for reuse.
  rm -f $sig $delta $out gmon.out
}

buildversion $version -DCMAKE_C_FLAGS="-pg -g" -DBUILD_SHARED_LIBS=OFF

#runprofile $version
runprofile $version -b 1024 -S 8
# Use rollsum for versions that support rabinkarp
if [[ "$version" > "v2.1.0" ]]; then
  #runprofile $version -Rrollsum
  runprofile $version -b1024 -S8 -Rrollsum
fi
