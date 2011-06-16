package App::Wax;

use 5.008008;

use strict;
use warnings;

use constant {
    NAME       => 'wax',
    TIMEOUT    => 5,
    USER_AGENT => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.8) Gecko/20100723 Firefox/3.6.8',
};

use File::Temp;
use HTTP::Request;
use LWP::UserAgent;
use Method::Signatures::Simple;
use MIME::Types;
use Mouse;
use URI::Split qw(uri_split);

our $VERSION = '0.0.1';

has app_name => (
    is      => 'rw',
    isa     => 'Str',
    default => NAME
);

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
    my $name = $self->app_name;
    die "usage: $name [OPTIONS] program [OPTIONS] ...", $/;
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
            if ($arg =~ /^(?:-[?h]|--help)$/) {
                exec('perldoc', $self->app_name());
            } elsif ($arg =~ /^(?:-d|--debug)$/) {
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

App::Wax - Helper library for wax

=head1 SYNOPSIS

    my $wax = App::Wax->new();
    $wax->run(\@ARGV);

=head1 DESCRIPTION

C<App::Wax> is the helper library for wax, a simple command-line program that runs
other command-line programs and converts their URI arguments to file paths.

See the L<wax> man page for more details.

=head1 ATTRIBUTES

Attributes are fields that can optionally be set in the C<App::Wax> constructor,
and get/set by invoking the corresponding getter/setter methods (which have the
same names as the constructor fields) after the C<App::Wax>
object has been initialized. Attributes can be initalized with a hash or hash ref e.g.

    my $wax = App::Wax->new(debug => 1);
    $wax->timeout(60);
    $wax->run(\@ARGV);

=head2 app_name([ $name ])

Getter/setter for the name used in the usage message and used to launch perldoc for the C<--help> &c.
options. Default: C<wax>.

=head2 debug([ $bool ])

Gets or sets the debug flag, used to determine whether to display diagnostic messages.

=head2 timeout([ $timeout ])

Getter/setter for the timeout (in seconds) for HTTP requests.

=head2 ua([ $ua ])

Getter/setter for the L<LWP::UserAgent> instance used to perform HTTP requests.

=head2 user_agent([ $user_agent ])

Getter/setter for the HTTP user-agent string.

=head1 METHODS

=head2 content_type($uri)

Returns the content type for the supplied URI.

=head2 download($uri, $path)

Saves the contents of the URI to the specified path.

=head2 log(@message)

Logs the string or list of strings to STDERR if debugging is enabled.

=head2 mime_types()

Getter for the L<MIME::Types> instance used to map the L<"content_type"> to an extension.

=head2 run($argv)

Takes a reference to a list of C<@ARGV>-style arguments and runs the specified command with substituted URIs.
Returns the command's exit code.

=head2 uri_to_path($uri)

Returns undef if the supplied argument isn't a URI, or a L<File::Temp> object representing the
temporary file to which the URI should be mirrored otherwise.

=head2 usage()

Prints a brief usage method and exits.

=head1 EXPORT

None by default.

=head1 SEE ALSO

=over

=item * L<wax>

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
