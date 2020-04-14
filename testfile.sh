#!/bin/bash -e
#
# testfile.sh: Generate a large random file with 50% matches and generate
# signature, delta, and patch files using provided sig args. Outputs rdiff
# stats, time info, and generated file sizes. Generates, leaves, and reuses
# input data files in /tmp.

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

# Generate input files if they don't already exist.
if [ ! -f "$new" ]; then
   dd bs=$blocks count=1024 if=/dev/urandom >"$old"
   dd bs=$blocks count=256 if=/dev/urandom >"$new"
   dd bs=$blocks count=256 skip=128 if="$old" >>"$new"
   dd bs=$blocks count=256 if=/dev/urandom >>"$new"
   dd bs=$blocks count=256 skip=640 if="$old" >>"$new"
fi

# Delete existing outputs, since We can't use rdiff -f on old binaries.
rm -f $sig $delta $out

# Note: usne '\time' to avoid the bash builtin which doesn't have memstats.
echo $blocks blocks of 1K size using sig args \'$sigargs\'
echo ========================================
\time $bindir/rdiff $debug -s $sigargs signature $old $sig 2>&1
echo
\time $bindir/rdiff $debug -s delta $sig $new $delta 2>&1
echo
\time $bindir/rdiff $debug -s patch $old $delta $out 2>&1
echo
ls -l $sig $delta
echo
# Clean up output files. Leave input files for reuse.
rm -f $sig $delta $out
