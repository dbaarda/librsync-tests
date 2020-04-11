#!/usr/bin/python -O
"""Generate graphs comparing librsync versions.

This reads the run output text files in data/perf_*.out to extract the data.
"""
import re
import glob
import itertools
import matplotlib
matplotlib.use('svg')
import matplotlib.pyplot as plt

cmds = ('sig', 'delta', 'patch')
args = ('defaults', 'b1024S8')


def saveplt(filename, title, xlabel, ylabel, xticks, xlabels=None, yticks=None):
  xlabels = xlabels or [str(n) for n in xticks]
  plt.title(title)
  plt.xlabel(xlabel)
  plt.ylabel(ylabel)
  plt.xticks(xticks, xlabels)
  if yticks:
    ylabels = [str(n) for n in yticks]
    plt.yticks(yticks, ylabels)
  plt.grid()
  plt.legend()
  plt.savefig(filename)
  plt.cla()


def GetFiles(sigargs='*'):
  return glob.glob('data/perf_%s_*.out' % sigargs)


def GetFileArgsVer(fname):
  return re.match(r'.*_(.*)_(.*).out',fname).groups()


def GetFileData(data, fname):
  args,ver = GetFileArgsVer(fname)
  cyclecmds = itertools.cycle(cmds)
  for l in open(fname):
    smatch = re.match(r'(\d+)K blocks of .*', l)
    if smatch:
      size = int(smatch.group(1))
    tmatch = re.match(r'([0-9.]+)user ([0-9.]+)system .* ([0-9]+)maxresident.*', l)
    if tmatch:
      u,s,m = tmatch.groups()
      cmd = cyclecmds.next()
      stats = (float(u) + float(s), int(m))
      data.setdefault(args, {}).setdefault(cmd, {}).setdefault(ver, {})[size] = stats
    deltamatch = re.match(r'.* (\d+) ... .. ..:.. /tmp/delta.*', l)
    if deltamatch:
      data[args].setdefault('deltasize', {}).setdefault(ver, {})[size] = int(deltamatch.group(1))/(2.0**20)
    sigmatch = re.match(r'.* (\d+) ... .. ..:.. /tmp/sig.*', l)
    if sigmatch:
      data[args].setdefault('sigsize', {}).setdefault(ver, {})[size] = int(sigmatch.group(1))/(2.0**20)


def GetAllData():
  data = {}
  for f in GetFiles():
    GetFileData(data, f)
  return data


def GraphTimeVsSize(data, args, cmd):
  """Plot how execution times vary with file size."""
  p = data[args][cmd]
  for ver in sorted(p):
    sizes = sorted(p[ver])
    times = [p[ver][size][0] for size in sizes]
    plt.plot(sizes, times, label=ver)
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/time-size-%s-%s.svg' % (args,cmd), '%s times vs filesize for %s' % (cmd, args),
            'size', 'time', sizes)


def GraphTimeVsVers(data, args, cmd):
  """Plot how execution times vary with file size."""
  p = data[args][cmd]
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for size in sizes:
    times = [p[ver][size][0] for ver in vers]
    plt.plot(vers, times, label="%sM" % size)
  #plt.xscale('log')
  saveplt('data/time-vers-%s-%s.svg' % (args,cmd), '%s times vs version for %s' % (cmd, args),
            'version', 'time', vers, vers)


def GraphMemVsSize(data, args, cmd):
  """Plot how execution times vary with file size."""
  p = data[args][cmd]
  for ver in sorted(p):
    sizes = sorted(p[ver])
    mems = [p[ver][size][1] for size in sizes]
    plt.plot(sizes, mems, label=ver)
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/mem-size-%s-%s.svg' % (args,cmd), '%s memory vs filesize for %s' % (cmd, args),
            'filesize', 'KB', sizes)


def GraphMemVsVers(data, args, cmd):
  """Plot how execution times vary with file size."""
  p = data[args][cmd]
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for size in sizes:
    mems = [p[ver][size][1] for ver in vers]
    plt.plot(vers, mems, label="%sM" % size)
  #plt.xscale('log')
  saveplt('data/mem-vers-%s-%s.svg' % (args,cmd), '%s memory vs version for %s' % (cmd, args),
            'version', 'KB', vers, vers)


def GraphSigVsSize(data, args):
  """Plot how signature size vary with file size."""
  p = data[args]['sigsize']
  for ver in sorted(p):
    sizes = sorted(p[ver])
    sigs = [p[ver][size] for size in sizes]
    plt.plot(sizes, sigs, label=ver)
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/file-size-%s-%s.svg' % (args,'sig'), 'sigsize vs filesize for %s' % args,
            'filesize', 'MB', sizes)


def GraphDeltaVsSize(data, args):
  """Plot how delta size vary with file size."""
  p = data[args]['deltasize']
  for ver in sorted(p):
    sizes = sorted(p[ver])
    sigs = [p[ver][size] for size in sizes]
    plt.plot(sizes, sigs, label=ver)
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/file-size-%s-%s.svg' % (args,'delta'), 'deltasize vs filesize for %s' % args,
            'filesize', 'MB', sizes)


if __name__ == '__main__':
  data = GetAllData()
  for arg in args:
    GraphSigVsSize(data, arg)
    GraphDeltaVsSize(data, arg)
    for cmd in cmds:
      GraphTimeVsSize(data, arg, cmd)
      GraphTimeVsVers(data, arg, cmd)
      GraphMemVsSize(data, arg, cmd)
      GraphMemVsVers(data, arg, cmd)
