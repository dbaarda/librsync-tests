#!/bin/bash -e
#
# librsync -- the library for network deltas
# Copyright (C) 2001, 2014 by Martin Pool <mbp@sourcefrog.net>
#
# performance.test: Run largefile.test with a variety of different
# numbers of blocks, using persistent data files in /tmp so the tests
# are repeatable.
sigargs="$@"

alltags () {
  pushd ../librsync >/dev/null
  # skip first version that didn't use cmake.
  git tag | tail +2
  popd >/dev/null
}

for version in $(alltags); do
  ./performance.test $version $sigargs
done;
