#!/bin/bash -e
#
# testfull.sh: Run testfile.sh with a variety of different filesizes.

bindir=../librsync

# These sizes pick out the sawtooth at the hashtable's 80% full mark.
fsizes="32K 51K 52K 64K 102K 103K 128K 204K 205K 256K 409K 410K 512K 819K 820K 1024K"

sigargs="$@"

header () {
  echo "Testing rdiff with signature args '${sigargs}'"
  echo "==============================================="
  echo
  ${bindir}/rdiff -V
  echo
}

header
for size in ${fsizes}; do
  ./testfile.sh $size $sigargs
done;
