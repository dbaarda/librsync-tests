#!/bin/bash -e
#
# librsync -- the library for network deltas
# Copyright (C) 2001, 2014 by Martin Pool <mbp@sourcefrog.net>
#
# testfull.sh: Run testfile.sh with a variety of different
# numbers of blocks, using persistent data files in /tmp so the tests
# are repeatable.
if [ -z "$1" ]; then
  echo "Usage: $0 <versiontag> [<sigargs> ...]"
  exit 1
fi

bindir=../librsync
datadir=./data
# These sizes pick out the sawtooth at the hashtable's 80% full mark.
fsizes="32K 51K 52K 64K 102K 103K 128K 204K 205K 256K 409K 410K 512K 819K 820K 1024K"

version="$1"
shift 1
sigargs="$@"

if [ -z "$sigargs" ]; then
  argsname="defaults"
else
  argsname=$(echo $sigargs | sed 's/[-_ ]//g')
fi
out="${datadir}/perf_${argsname}_${version}.out"

build () {
  pushd ../librsync
  git checkout $version
  git clean -dfx
  cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_TRACE=OFF .
  make rdiff
  popd
}

header () {
  echo "Version ${version} with args '${sigargs}'"
  echo "==============================================="
  echo
  ${bindir}/rdiff -V
  echo
}

echo Testing $version with args \'${sigargs}\'
echo ========================================
build
header > $out
for size in ${fsizes}; do
  ./testfile.sh $size $sigargs >>$out
done;
