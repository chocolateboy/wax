package App::Wax;

use 5.006002;

use strict;
use warnings;

use constant {
    TEMPLATE   => 'wax_XXXXXXXX',
    USER_AGENT => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.8) Gecko/20100723 Firefox/3.6.8',
    TIMEOUT    => 5,
};

use File::Temp;
use HTTP::Request;
use LWP::UserAgent;
use Method::Signatures::Simple;
use MIME::Types;
use Mouse;
use URI::Split qw(uri_split);

our $VERSION = 0.0.1;

has debug => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

has mime_types => (
    is      => 'ro',
    isa     => 'MIME::Types',
    lazy    => 1,
    default => sub { MIME::Types->new() }
);

has timeout => (
    is      => 'rw',
    isa     => 'Int',
    default => TIMEOUT
);

has ua => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub { LWP::UserAgent->new() }
);

has user_agent => (
    is      => 'rw',
    isa     => 'Str',
    default => USER_AGENT
);

method content_type ($uri) {
    my $request  = HTTP::Request->new(HEAD => $uri);
    my $response = $self->ua->request($request);
    my $content_type = '';

    if ($response->is_success) {
        ($content_type) = scalar($response->header('Content-Type')) =~ /^([^;]+)/;
    }

    return $content_type;
}

method download ($uri, $filename) {
    my $request = HTTP::Request->new(GET => $uri);
    my $response = $self->ua->request($request, $filename);
    my $rc = $response->code;

    die "can't retrieve URI ($rc): $uri" unless ($response->is_success);
}

method usage {
    die "usage: $0 [OPTIONS] program [OPTIONS] ...", $/;
}

method log {
    warn ('wax: ', @_, $/) if ($self->debug);
}

method uri_to_path($uri) {
    return unless ($uri =~ m{^\w+://});

    my ($scheme, $auth, $path, $query, $fragment) = uri_split($uri);

    if ($scheme && $path) {
        $self->log("uri: $uri");

        my $suffix = do {
            my $extension;
            my $content_type = $self->content_type($uri);
            $self->log("content type: $content_type");

            if ($content_type eq 'text/plain') {
                # require Data::Dumper;
                # local ($Data::Dumper::Terse, $Data::Dumper::Indent) = (1, 1);
                # $self->log(Data::Dumper::Dumper({
                #     scheme   => $scheme,
                #     auth     => $auth,
                #     path     => $path,
                #     query    => $query,
                #     fragment => $fragment
                # }));

                # try to get a more specific extension from the path
                if (not(defined $query) && not(defined($fragment)) && ($path =~ /\w+(\.\w+)$/)) {
                    $extension = $1;
                }
            }

            unless ($extension) {
                my $mime_type = $self->mime_types->type($content_type);
                my @extensions = $mime_type->extensions;
                $extension = '.' . $extensions[0];
            }

            $extension;
        };

        my $temp_file = File::Temp->new($suffix ? (SUFFIX  => $suffix) : ());

        $self->download($uri, $temp_file->filename);

        return $temp_file; # return the object to prevent premature unlinking
    }
}

method run ($argv) {
    $| = 1;

    $self->usage unless (@$argv);

    my $wax_options = 1;
    my ($command, @command, @files);

    while (@$argv) {
        my $arg = shift @$argv;
        my $temp_file;

        if ($wax_options) {
            if ($arg =~ /^(?:-d|--debug)$/) {
                $self->debug(1);
            } elsif ($arg =~ /^(?:-t|--timeout)$/) {
                $self->timeout(shift @$argv);
            } elsif ($arg =~ /^(?:-u|--user-agent)$/) {
                $self->user_agent(shift @$argv);
            } else {
                $command = $arg;
                $wax_options = 0;
            }
        } elsif ($arg eq '--') {
            push @command, @$argv;
            last;
        } elsif ($temp_file = $self->uri_to_path($arg)) {
            push @files, $temp_file; # keep a reference to this to prevent premature unlinking
            push @command, $temp_file->filename;
        } else {
            push @command, $arg;
        }
    }

    $self->log("command: $command @command");
    # XXX: exec { $command } @args doesn't work with cat...
    system($command, @command);
    my $exit_code = $? >> 8;
    $self->log("exit code: $exit_code");
    return $exit_code;
}

1;

__END__

=head1 NAME

App::Wax - Webify Your CLI

=head1 USAGE

    wax [OPTIONS] program [OPTIONS] ...

=head1 SYNOPSIS

    $ wax grep -F needle http://www.haysta.ck
    $ wax espeak -f http://www.setec.org/mel.txt

    $ alias perldoc="wax perldoc"
    $ perldoc -F "http://www.pair.com/~comdog/brian's_guide.pod"

=head1 DESCRIPTION

C<wax> is a simple command-line program that runs other command-line programs and converts their URI
arguments to file paths. The remote resources are saved as temporary files, which are
cleaned up after the waxed program has exited.

=head1 OPTIONS

The following wax options can be supplied before the command name. Subsequent options are passed to
the waxed program verbatim, apart from URIs, which are converted to paths to the corresponding temporary
files. To exclude args from waxing, pass them after C<--> e.g.

    wax --timeout 5 command -f http://example.com -- --title http://www.example.com

=head2 -d, --debug

Print diagnostic information to STDERR.

=head2 -t, --timeout INTEGER

Set the timeout for HTTP requests in seconds. Default: 5.

=head2 -u, --user-agent STRING

Set the user-agent string for HTTP requests.

=head1 EXPORT

None by default.

=head1 CAVEATS

As with any command-line programs that take URI parameters, care should be taken to ensure that
special shell characters are suitably quoted. As a general rule, URIs that contain C<&>, C<~>,
C<<>, C<>>, C<$> &c. should be single- or double-quoted on Unix-like shells and double-quoted with embedded
escapes in Windows C<cmd/command.exe>-like shells.

It's worth checking that a program actually needs waxing. Many command-line programs already support URIs:

    vim http://www.vim.org/
    gedit http://projects.gnome.org/gedit/
    eog http://upload.wikimedia.org/wikipedia/commons/4/4c/Eye_of_GNOME.png
    gimp http://upload.wikimedia.org/wikipedia/commons/6/6c/Gimpscreen.png

&c.

=head1 SEE ALSO

=over

=item * rlwrap

=item * sshfs

=begin html

<li>
<a href="http://rt.cpan.org/Public/Bug/Display.html?id=37347">RT #37347</a>
</li>

=end html

=back

=head1 AUTHOR

chocolateboy, <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
