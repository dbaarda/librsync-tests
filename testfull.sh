#!/bin/bash -e
#
# testfull.sh: Run testfile.sh with a variety of different filesizes.

. ./common.sh

sigargs="$@"

# These sizes pick out the sawtooth at the hashtable's 70% and 80% full mark.
fsizes="32K 44K 45K 51K 52K 64K 89K 90K 102K 103K 128K 179K 180K 204K 205K 256K 358K 359K 409K 410K 512K 716K 717K 819K 820K 1024K"

echo "Testing rdiff with signature args '${sigargs}'"
echo "==============================================="
echo
${bindir}/rdiff -V
echo
for size in ${fsizes}; do
  ./testfile.sh $size $sigargs
done;
