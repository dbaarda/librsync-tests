#! /bin/sh -e
#
# librsync -- the library for network deltas
# Copyright (C) 2001, 2014 by Martin Pool <mbp@sourcefrog.net>
#
# testfile.sh: Generate some large random files with 50% matches
# and generate signature, delta, and patch files, comparing for
# correctness.

tmpdir=/tmp
bindir=../librsync

if [ -z "$1" ]; then
  echo "Usage: $0 <blocks>K [<sigargs> ...]"
  exit 1
fi
blocks=$1
shift 1
sigargs="$@"

old="$tmpdir/old.$blocks"
new="$tmpdir/new.$blocks"
sig="$tmpdir/sig.$blocks"
delta="$tmpdir/delta.$blocks"
out="$tmpdir/out.$blocks"

if [ ! -f "$new" ]; then
   mkdir -p $tmpdir
   dd bs=$blocks count=1024 if=/dev/urandom >"$old"
   dd bs=$blocks count=256 if=/dev/urandom >"$new"
   dd bs=$blocks count=256 skip=128 if="$old" >>"$new"
   dd bs=$blocks count=256 if=/dev/urandom >>"$new"
   dd bs=$blocks count=256 skip=640 if="$old" >>"$new"
fi
# We can't use rdiff -f on old binaries.
rm -f $sig $delta $out

echo $blocks blocks of 1K size using sig args \'$sigargs\'
echo ========================================
time $bindir/rdiff $debug -s $sigargs signature $old $sig 2>&1
echo
time $bindir/rdiff $debug -s delta $sig $new $delta 2>&1
echo
time $bindir/rdiff $debug -s patch $old $delta $out 2>&1
echo
ls -l $sig $delta
echo
rm $sig $delta $out
