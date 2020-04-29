# wax

[![Build Status](https://travis-ci.org/chocolateboy/wax.svg)](http://travis-ci.org/chocolateboy/wax)
[![CPAN Version](https://badge.fury.io/pl/App-Wax.svg)](http://badge.fury.io/pl/App-Wax)

<!-- toc -->

- [NAME](#name)
- [SYNOPSIS](#synopsis)
- [DESCRIPTION](#description)
- [INSTALLATION](#installation)
  - [INSTALL](#install)
  - [UPDATE](#update)
  - [UNINSTALL](#uninstall)
- [EXAMPLES](#examples)
  - [espeak](#espeak)
  - [grep](#grep)
  - [jsview](#jsview)
  - [nman](#nman)
  - [rg](#rg)
- [VERSION](#version)
- [SEE ALSO](#see-also)
  - [Tools](#tools)
  - [Links](#links)
- [AUTHOR](#author)
- [COPYRIGHT AND LICENSE](#copyright-and-license)

<!-- tocstop -->

## NAME

wax - webify your CLI

## SYNOPSIS

    wax [OPTIONS] program [OPTIONS] ...

e.g.:

    $ wax vim -R https://registry.npmjs.org/left-pad/-/left-pad-1.2.0.tgz

runs:

    $ vim -R /tmp/wax_abcd1234.tgz

## DESCRIPTION

`wax` is a command-line program which runs other command-line programs and converts their URL
arguments to local file paths. By default, the files are removed after the command has exited.

As well as adding transparent support for remote resources to commands that don't support them
natively, `wax` can be used to:

- add support for HTTPS (and any other protocols supported by [LWP](https://metacpan.org/pod/LWP)) to programs that [only support HTTP](https://github.com/jgm/pandoc/issues/1266)
- add a mirroring layer to network requests (remote resources are only fetched if they've been updated)
- add a caching layer to network requests (remote resources are only fetched once)

For more details, see the `wax` [man page](bin/README.md).

## INSTALLATION

### INSTALL

Install [cpanminus](https://github.com/miyagawa/cpanminus/tree/devel/App-cpanminus#readme) if it's not already installed,
then:

    cpanm App::Wax

### UPDATE

    cpanm App::Wax

### UNINSTALL

    cpanm --uninstall App::Wax

## EXAMPLES

### espeak

    $ alias espeak="wax espeak"
    $ espeak -f http://www.setec.org/mel.txt

### grep

    $ wax grep -B1 demons http://www.mplayerhq.hu/DOCS/man/en/mplayer.1.txt

### jsview

Browse files in Node module tarballs

```bash
#!/bin/sh

# usage: jsview <module> e.g. jsview left-pad
wax --cache vim -R $(npm info --json "$@" | jq -r .dist.tarball)
```

### nman

Node.js man-page viewer

```bash
#!/bin/sh

# usage: nman <man-page> e.g. nman util
node_version=${NODE_VERSION:-`node --version`}
docroot="https://cdn.jsdelivr.net/gh/nodejs/node@$node_version/doc/api"
wax --cache -D pandoc --standalone --from markdown --to man "$docroot/$1.md" | man -l -
```

### rg

Get the default key bindings for mpv:

    wax rg -r '$1' '^#(\S.+)$' https://git.io/JfYlz | sort

## VERSION

2.3.1

## SEE ALSO

### Tools

- [zsh completion script](https://github.com/chocolateboy/App-Wax/wiki/Zsh-completion-script)

### Links

- [The Parrot Virtual File System](http://ccl.cse.nd.edu/software/parrot/) - a filesystem which provides transparent access to web resources
- [SSHFS](https://github.com/libfuse/sshfs) - a filesystem which provides transparent access to SSH shares
- [tmpin](https://github.com/sindresorhus/tmpin) - add stdin support to any CLI app that accepts file input

## AUTHOR

[chocolateboy](mailto:chocolate@cpan.org)

## COPYRIGHT AND LICENSE

Copyright © 2010-2020 by chocolateboy.

This is free software; you can redistribute it and/or modify it under the terms of the
[Artistic License 2.0](http://www.opensource.org/licenses/artistic-license-2.0.php).
