#!/usr/bin/python -O
"""Generate graphs comparing librsync versions.

This reads the run output text files in data/perf_*.txt to extract the data.
"""
import re
import glob
import itertools
import matplotlib
matplotlib.use('svg')
import matplotlib.pyplot as plt
from matplotlib.ticker import *

cmds = ('sig', 'delta', 'patch')
args = ('defaults', 'b1024S8')

sizeticks = (32, 64, 128, 256, 512, 1024)

def saveplt(filename, title, xlabel, ylabel, xticks, xlabels=None, yticks=None):
  xlabels = xlabels or [str(n) for n in xticks]
  plt.title(title)
  plt.xlabel(xlabel)
  plt.ylabel(ylabel)
  plt.xticks(xticks, xlabels)
  if yticks:
    ylabels = [str(n) for n in yticks]
    plt.yticks(yticks, ylabels)
  ax = plt.gca()
  ax.ticklabel_format(axis='y', style='plain', useOffset=False)
  plt.grid()
  plt.legend(bbox_to_anchor=(1,1), loc='upper left')
  plt.savefig(filename, bbox_inches='tight')
  plt.cla()


def GetFiles(sigargs='*'):
  return glob.glob('data/perf_%s_*.txt' % sigargs)


def GetFileArgsVer(fname):
  return re.match(r'.*_(.*)_(.*).txt',fname).groups()


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
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for ver in vers:
    times = [p[ver][size][0] for size in sizes]
    plt.plot(sizes, times, label=ver)
  if cmd == 'delta':
    plt.gca().yaxis.set_major_locator(MultipleLocator(60))
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/time-size-%s-%s.svg' % (args,cmd), '%s times vs filesize for %s' % (cmd, args),
            'size', 'time', sizeticks)


def GraphTimeVsVers(data, args, cmd):
  """Plot how execution times vary with version."""
  p = data[args][cmd]
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for size in sizes:
    times = [p[ver][size][0] for ver in vers]
    plt.plot(vers, times, label="%sM" % size)
  if cmd == 'delta':
    plt.gca().yaxis.set_major_locator(MultipleLocator(60))
  #plt.xscale('log')
  saveplt('data/time-vers-%s-%s.svg' % (args,cmd), '%s times vs version for %s' % (cmd, args),
            'version', 'time', vers)


def GraphMemVsSize(data, args, cmd):
  """Plot how memory usage varys with file size."""
  p = data[args][cmd]
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for ver in vers:
    mems = [p[ver][size][1] for size in sizes]
    plt.plot(sizes, mems, label=ver)
  if cmd == 'delta':
    mult=10240
  else:
    mult=32
  plt.gca().yaxis.set_major_locator(MultipleLocator(mult))
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/mem-size-%s-%s.svg' % (args,cmd), '%s memory vs filesize for %s' % (cmd, args),
            'filesize', 'KB', sizeticks)


def GraphMemVsVers(data, args, cmd):
  """Plot how memory usage varys with version."""
  p = data[args][cmd]
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for size in sizes:
    mems = [p[ver][size][1] for ver in vers]
    plt.plot(vers, mems, label="%sM" % size)
  if cmd == 'delta':
    mult=10240
  else:
    mult=32
  plt.gca().yaxis.set_major_locator(MultipleLocator(mult))
  #plt.xscale('log')
  saveplt('data/mem-vers-%s-%s.svg' % (args,cmd), '%s memory vs version for %s' % (cmd, args),
            'version', 'KB', vers)


def GraphSigVsSize(data, args):
  """Plot how signature size vary with file size."""
  p = data[args]['sigsize']
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for ver in vers:
    sigs = [p[ver][size]/size for size in sizes]
    plt.plot(sizes, sigs, label=ver)
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/file-size-%s-%s.svg' % (args,'sig'), 'sigsize vs filesize for %s' % args,
          'filesize', 'ratio', sizeticks)


def GraphSigVsVers(data, args):
  """Plot how signature size vary with version."""
  p = data[args]['sigsize']
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for size in sizes:
    sigs = [p[ver][size]/size for ver in vers]
    plt.plot(vers, sigs, label="%sM" % size)
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/file-vers-%s-%s.svg' % (args,'sig'), 'sigsize vs version for %s' % args,
          'version', 'ratio', vers)


def GraphDeltaVsSize(data, args):
  """Plot how delta size vary with file size."""
  p = data[args]['deltasize']
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for ver in vers:
    deltas = [p[ver][size]/size for size in sizes]
    plt.plot(sizes, deltas, label=ver)
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/file-size-%s-%s.svg' % (args,'delta'), 'deltasize vs filesize for %s' % args,
          'filesize', 'ratio', sizeticks)


def GraphDeltaVsVers(data, args):
  """Plot how delta size vary with version."""
  p = data[args]['deltasize']
  vers = sorted(p)
  sizes = sorted(p[vers[0]])
  for size in sizes:
    deltas = [p[ver][size]/size for ver in vers]
    plt.plot(vers, deltas, label="%sM" % size)
  #plt.xscale('log')
  #plt.yscale('log')
  saveplt('data/file-vers-%s-%s.svg' % (args,'delta'), 'deltasize vs version for %s' % args,
          'version', 'ratio', vers)


if __name__ == '__main__':
  data = GetAllData()
  for arg in args:
    GraphSigVsSize(data, arg)
    GraphSigVsVers(data, arg)
    GraphDeltaVsSize(data, arg)
    GraphDeltaVsVers(data, arg)
    for cmd in cmds:
      GraphTimeVsSize(data, arg, cmd)
      GraphTimeVsVers(data, arg, cmd)
      GraphMemVsSize(data, arg, cmd)
      GraphMemVsVers(data, arg, cmd)
