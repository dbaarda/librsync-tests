# common.sh: Common definitions and functions used for tests.

tmpdir=/tmp
bindir=../librsync
datadir=./data

alltags () {
  pushd ${bindir} >/dev/null
  # skip first version that didn't use cmake.
  git tag | tail +2
  popd >/dev/null
}

# Usage: buildversion <version> [<cmakeargs> ...]
buildversion () {
  version="$1"
  shift 1
  pushd ${bindir}
  git checkout $version
  git clean -dfx
  cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_TRACE=OFF "$@" .
  make rdiff
  popd
}

# Usage: outputfile <prefix> <version> [<sigargs>...]
outputfile () {
  prefix="$1"
  version="$2"
  shift 2
  sigargs="$@"
  versname=$(echo $version | sed 's:/:-:g')
  if [ -z "${sigargs}" ]; then
    argsname="defaults"
  else
    argsname=$(echo $sigargs | sed 's/[-_ ]//g')
  fi
  echo "${datadir}/${prefix}_${argsname}_${versname}.txt"
}

# Usage: runfull <version> [<sigargs>...]
runfull () {
  out=$(outputfile perf "$@")
  ./testfull.sh $sigargs >$out
}
