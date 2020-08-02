# wax

<!-- toc -->

- [NAME](#name)
- [SYNOPSIS](#synopsis)
- [DESCRIPTION](#description)
- [OPTIONS](#options)
  - [-c, --cache](#-c---cache)
  - [-d, --dir, --directory STRING](#-d---dir---directory-string)
  - [-D, --default-directory](#-d---default-directory)
  - [-h, -?, --help](#-h-----help)
  - [-m, --mirror](#-m---mirror)
  - [-s, --separator STRING](#-s---separator-string)
  - [-S, --no-separator](#-s---no-separator)
  - [-t, --timeout INTEGER](#-t---timeout-integer)
  - [-u, --user-agent STRING](#-u---user-agent-string)
  - [-v, --verbose](#-v---verbose)
  - [-V, --version](#-v---version)
- [EXAMPLES](#examples)
  - [espeak](#espeak)
  - [grep](#grep)
  - [jsview](#jsview)
  - [nman](#nman)
  - [ripgrep](#ripgrep)
- [CAVEATS](#caveats)
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

`wax` is a command-line program which runs other command-line programs and
converts their URL arguments to local file paths. By default, the files are
removed after the command has exited.

As well as adding transparent support for remote resources to commands that
don't support them natively, wax can be used to:

- add support for HTTPS (and any other protocols supported by [LWP](https://metacpan.org/pod/LWP)) to programs that [only support HTTP](https://github.com/jgm/pandoc/issues/1266)
- add a mirroring layer to network requests (remote resources are only fetched if they've been updated)
- add a caching layer to network requests (remote resources are only fetched once)

## OPTIONS

The following `wax` options can be supplied before the command name. Subsequent
options are passed to the command verbatim, apart from URLs, which are
converted to paths to the corresponding files. URL arguments can be excluded
from the conversion process by supplying a [separator token](#-s---separator-string)
(default `--`). Arguments after this are no longer processed by `wax` and are
passed through verbatim e.g.:

    $ wax --cache cmd https://example.com/foo -- --referrer https://example.com

Note that the `--cache` and `--mirror` options are mutually exclusive i.e. only
one (or neither) should be supplied. Supplying both will cause `wax` to
terminate with an error.

### -c, --cache

Don't remove the downloaded file(s) after the command exits. Subsequent
invocations will resolve the URL(s) to the cached files(s) (if still available)
rather than hitting the network.

If a local file no longer exists, the resource is re-downloaded.

Note: by default, files are saved to the system's temp directory, which is
typically cleared when the system restarts. To save files to another directory,
use the `--directory` or `--default-directory` option.

### -d, --dir, --directory STRING

Specify the directory to download files to. Default: the system's
[temp directory](https://en.wikipedia.org/wiki/Temporary_folder).

If the directory doesn't exist, it is created if its parent directory exists.
Otherwise, an error is raised.

### -D, --default-directory

Download files to `$XDG_CACHE_HOME/wax` or `$HOME/.cache/wax` rather than the
system's temp directory. Can be overriden by `--directory`.

If the directory doesn't exist, it is created if its parent directory exists.
Otherwise, an error is raised.

### -h, -?, --help

Display this documentation.

### -m, --mirror

Like the `--cache` option, this keeps the downloaded file(s) after the command
exits. In addition, a HEAD request is issued for each resource to see if it has
been updated. If so, the latest version is downloaded; otherwise, the cached
version is used (if still available).

If a local file no longer exists, the resource is re-downloaded.

### -s, --separator STRING

Override the default separator-token (`--`) used to mark the end of waxable
options e.g.:

    $ wax --cache --separator :: cmd https://example.com/foo :: --referrer https://example.com

Note: the separator token is removed from the list of options passed to the
command.

### -S, --no-separator

Disable separator-token handling i.e. leave the default separator (`--`) to be
handled by the command.

### -t, --timeout INTEGER

Set the timeout for network requests in seconds. Default: 60.

### -u, --user-agent STRING

Set the user-agent string for network requests.

### -v, --verbose

Print diagnostic information to STDERR.

### -V, --version

Print the version of wax.

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

```sh
#!/bin/sh

# usage: nman <man-page> e.g. nman util
node_version=${NODE_VERSION:-`node --version`}
docroot="https://cdn.jsdelivr.net/gh/nodejs/node@$node_version/doc/api"
wax --cache -D pandoc --standalone --from markdown --to man "$docroot/$1.md" | man -l -
```

### ripgrep

Get the default key bindings for mpv:

    $ wax rg -r '$1' '^#(\S.+)$' https://git.io/JfYlz | sort

## CAVEATS

As with any command-line programs that take URL parameters, care should be
taken to ensure that special shell characters are suitably quoted. As a general
rule, URLs that contain `&`, `~`, `<`, `>`, `$` etc. should be quoted in shells
on Unix-like systems and quoted with embedded escapes in Windows
`cmd`/`command.exe`-like shells.

It's worth checking that a program actually needs waxing. Many command-line
programs already support URLs e.g:

```bash
$ eog https://upload.wikimedia.org/wikipedia/commons/4/4c/Eye_of_GNOME.png
$ gedit https://projects.gnome.org/gedit/
$ gimp https://upload.wikimedia.org/wikipedia/commons/6/6c/Gimpscreen.png
$ vim https://www.vim.org/
```

etc.

## VERSION

2.3.3

## SEE ALSO

### Tools

- [zsh completion script](https://github.com/chocolateboy/wax/wiki/Zsh-completion-script)

### Links

- [The Parrot Virtual File System](https://ccl.cse.nd.edu/software/parrot/) - a filesystem which provides transparent access to web resources
- [SSHFS](https://github.com/libfuse/sshfs) - a filesystem which provides transparent access to SSH shares
- [tmpin](https://github.com/sindresorhus/tmpin) - add stdin support to any CLI app that accepts file input

## AUTHOR

[chocolateboy](mailto:chocolate@cpan.org)

## COPYRIGHT AND LICENSE

Copyright © 2010-2020 by chocolateboy.

This is free software; you can redistribute it and/or modify it under the
terms of the [Artistic License 2.0](https://www.opensource.org/licenses/artistic-license-2.0.php).
