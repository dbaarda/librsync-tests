# common.sh: Common definitions and functions used for tests.

tmpdir=/tmp
bindir=../librsync
datadir=./data

platforminfo () {
  echo cpuinfo
  echo =======
  cat /proc/cpuinfo
  echo
  echo meminfo
  echo =======
  cat /proc/meminfo
  echo
}

alltags () {
  pushd ${bindir} >/dev/null
  # skip first version that didn't use cmake.
  git tag | tail +2
  popd >/dev/null
}

# Usage: buildversion <version> [<build_type> [<cmakeargs> ...]]
buildversion () {
  version="$1"
  shift 1
  build_type="${1:-Release}"
  [ -n "$1" ] && shift 1
  pushd ${bindir}
  git checkout $version
  git clean -dfx
  cmake -DCMAKE_BUILD_TYPE=${build_type} -DENABLE_TRACE=OFF "$@" .
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
  version="$1"
  shift 1
  sigargs="$@"
  out=$(outputfile perf $version $sigargs)
  [ -f ${out} ] || ./testfull.sh $sigargs >$out
}
