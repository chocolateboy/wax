# NAME

wax - webify your CLI

# USAGE

    wax [OPTIONS] program [OPTIONS] ...

# SYNOPSIS

    $ wax grep needle http://www.haysta.ck
    $ wax espeak -f http://www.setec.org/mel.txt

    $ alias perldoc="wax perldoc"
    $ perldoc -F "http://www.pair.com/~comdog/brian's_guide.pod"

# DESCRIPTION

`wax` is a simple command-line program that runs other command-line programs and converts their URL arguments to file paths. The remote resources are saved as temporary files, which are cleaned up after the waxed program has exited.

# OPTIONS

The following wax options can be supplied before the command name. Subsequent options are passed to the waxed program verbatim, apart from URLs, which are converted to paths to the corresponding temporary files. To exclude args from waxing, pass them after `--` e.g.

    wax command -f http://www.example.com -- --title http://www.example.com

The separator token can be overridden with the `-s` or `--separator` option e.g.

    wax -s --nowax command -f http://www.example.com --nowax --title http://www.example.com

## -d, --debug

Print diagnostic information to STDERR.

## -?, -h, --help

Display this documentation.

## -s, --separator

Set the token used to mark the end of waxable options. Default: `--`.

Note: the separator token is removed from the list of options passed to the command.

## -S, --no-separator

Disable detection of the wax separator token i.e. the default `--` separator is not used to mark the end of waxable options.

## -t, --timeout INTEGER

Set the timeout for HTTP requests in seconds. Default: 60.

## -u, --user-agent STRING

Set the user-agent string for HTTP requests.

# INSTALL

## Recommended

Install [cpanminus](http://search.cpan.org/perldoc?App::cpanminus#INSTALLATION), then:

    cpanm App::Wax

## Traditional

Unpack the tarball, then:

    perl Makefile.PL
    make
    make test
    make install

# UPDATE

    cpanm App::Wax

# UNINSTALL

Install [pm-uninstall](http://search.cpan.org/perldoc?pm-uninstall) if it's not already installed:

    cpanm App::pmuninstall

Then:

    pm-uninstall App::Wax

# CAVEATS

As with any command-line programs that take URL parameters, care should be taken to ensure that special shell characters are suitably quoted. As a general rule, URLs that contain `&`, `~`, `<`, `>`, `$` &c. should be single- or double-quoted in shells on Unix-like systems, and double-quoted with embedded escapes in Windows `cmd`/`command.exe`-like shells.


It's worth checking that a program actually needs waxing. Many command-line programs already support URLs:

    vim http://www.vim.org/
    gedit http://projects.gnome.org/gedit/
    eog http://upload.wikimedia.org/wikipedia/commons/4/4c/Eye_of_GNOME.png
    gimp http://upload.wikimedia.org/wikipedia/commons/6/6c/Gimpscreen.png

&c.

# VERSION

0.3.0

# SEE ALSO

* [rlwrap](http://utopia.knoware.nl/~hlub/uck/rlwrap/rlwrap.html)
* [sshfs](http://fuse.sourceforge.net/sshfs.html)
* [zsh completion script](https://github.com/chocolateboy/App-Wax/wiki/Zsh-completion-script)

# AUTHOR

[chocolateboy](mailto:chocolate@cpan.org)

# COPYRIGHT AND LICENSE

Copyright 2010-2011 [chocolateboy](mailto:chocolate@cpan.org).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
