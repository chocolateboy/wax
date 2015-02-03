# wax

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [NAME](#name)
- [SYNOPSIS](#synopsis)
- [DESCRIPTION](#description)
- [INSTALLATION](#installation)
  - [INSTALL](#install)
  - [UPDATE](#update)
  - [UNINSTALL](#uninstall)
- [EXAMPLES](#examples)
  - [grep](#grep)
  - [espeak](#espeak)
  - [nman](#nman)
- [VERSION](#version)
- [SEE ALSO](#see-also)
- [AUTHOR](#author)
- [COPYRIGHT AND LICENSE](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## NAME

wax - webify your CLI

## SYNOPSIS

    wax [OPTIONS] program [OPTIONS] ...

## DESCRIPTION

`wax` is a command-line program which runs other command-line programs and converts their URL
arguments to file paths. By default, the files are cleaned up after the command has exited.

As well as adding transparent support for remote resources to commands that don't support them
natively, `wax` can be used to:

- add support for HTTPS (and any other protocols supported by [LWP](https://metacpan.org/pod/LWP)) to programs that only support HTTP
- add a mirroring layer to network requests (remote resources are only fetched if they have been updated)
- add a caching layer to network requests (remote resources are only fetched once)

For more details, see the `wax` [man page](bin/wax.pod).

## INSTALLATION

### INSTALL

Install [cpanminus](http://search.cpan.org/perldoc?App::cpanminus#INSTALLATION) if it's not already installed,
then:

    cpanm App::Wax

### UPDATE

    cpanm App::Wax

### UNINSTALL

Install [pm-uninstall](http://search.cpan.org/perldoc?pm-uninstall) if it's not already installed:

    cpanm App::pmuninstall

Then:

    pm-uninstall App::Wax

## EXAMPLES

### grep

    $ wax grep -B1 demons http://www.mplayerhq.hu/DOCS/man/en/mplayer.1.txt

### espeak

    $ alias espeak="wax espeak"
    $ espeak -f http://www.setec.org/mel.txt

### nman

```bash
#!/bin/sh

# nman - Node.js man-page viewer

node_version=${NODE_VERSION:-`node --version`}
docroot="https://cdn.rawgit.com/joyent/node/$node_version-release/doc/api"

# https://stackoverflow.com/a/7603703
wax --cache pandoc --standalone --from markdown --to man "$docroot/$1.markdown" | man -l -
```

## VERSION

1.0.0

## SEE ALSO

- [rlwrap](http://utopia.knoware.nl/~hlub/uck/rlwrap/)
- [sshfs](http://fuse.sourceforge.net/sshfs.html)
- [zsh completion script](https://github.com/chocolateboy/App-Wax/wiki/Zsh-completion-script)

## AUTHOR

[chocolateboy](mailto:chocolate@cpan.org)

## COPYRIGHT AND LICENSE

Copyright (C) 2010-2015 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
