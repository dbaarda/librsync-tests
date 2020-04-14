#!/bin/bash -e
#
# testfull.sh: Run testfull.sh with a variety of different arguments for all
# released versions.
datadir=./data

alltags () {
  pushd ../librsync >/dev/null
  # skip first version that didn't use cmake.
  git tag | tail +2
  popd >/dev/null
}

# Usage: buildversion <version>
buildversion () {
  version="$1"
  pushd ../librsync
  git checkout $version
  git clean -dfx
  cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_TRACE=OFF .
  make rdiff
  popd
}

# Usage: runfull <version> [<sigargs>...]
runfull () {
  version="$1"
  shift 1
  sigargs="$@"
  if [ -z "${sigargs}" ]; then
    argsname="defaults"
  else
    argsname=$(echo $sigargs | sed 's/[-_ ]//g')
  fi
  out="${datadir}/perf_${argsname}_${version}.txt"
  ./testfull.sh $sigargs >$out
}

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
