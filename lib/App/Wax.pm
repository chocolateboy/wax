package App::Wax;

use 5.008008;

use strict;
use warnings;

use constant {
    DEBUG      => 0,
    ENV_PROXY  => 1,
    NAME       => 'wax',
    SEPARATOR  => '--',
    TEMPLATE   => 'XXXXXXXX',
    TIMEOUT    => 60,
    USER_AGENT => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.8) Gecko/20100723 Firefox/3.6.8',
};

use File::Temp;
use HTTP::Request;
use LWP::UserAgent;
use Method::Signatures::Simple;
use MIME::Types;
use Mouse;
use URI::Split qw(uri_split);

our $VERSION = '0.3.1';

has app_name => (
    is      => 'rw',
    isa     => 'Str',
    default => NAME
);

has debug => (
    is      => 'rw',
    isa     => 'Bool',
    default => DEBUG
);

# FIXME: this should be a class attribute, but there's no MouseX::ClassAttribute (on CPAN)
has mime_types => (
    is      => 'ro',
    isa     => 'MIME::Types',
    lazy    => 1,
    default => sub { MIME::Types->new() }
);

has separator => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => SEPARATOR
);

has timeout => (
    is      => 'rw',
    isa     => 'Int',
    default => TIMEOUT,
    trigger => method ($timeout) { $self->ua->timeout($timeout) }
);

has ua => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => method {
        LWP::UserAgent->new(
            env_proxy => ENV_PROXY,
            timeout   => $self->timeout,
            agent     => $self->user_agent
          )
      }
);

has user_agent => (
    is      => 'rw',
    isa     => 'Str',
    default => USER_AGENT,
    trigger => method ($user_agent) { $self->ua->agent($user_agent) }
);

method content_type ($url) {
    my $request  = HTTP::Request->new(HEAD => $url);
    my $response = $self->ua->request($request);
    my $content_type = '';

    if ($response->is_success) {
        ($content_type) = scalar($response->header('Content-Type')) =~ /^([^;]+)/;
        $self->log("content type: $content_type");
    }

    return $content_type;
}

method download ($url, $filename) {
    my $ua = $self->ua;
    my $request = HTTP::Request->new(GET => $url);
    my $response = $ua->request($request, $filename);
    my $status = $response->status_line;

    die "can't save URL ($url) to filename ($filename): $status", $/ unless ($response->is_success);
}

method usage {
    my $name = $self->app_name;
    die "usage: $name [OPTIONS] program [OPTIONS] ...", $/;
}

method log {
    warn ('wax: ', @_, $/) if ($self->debug);
}

method extension($url) {
    my $split = $self->is_url($url);

    return unless ($split);

    my ($scheme, $domain, $path, $query, $fragment) = @$split;
    my $content_type = $self->content_type($url);

    return unless ($content_type); # won't be defined if the URL is invalid

    my $extension;

    if ($content_type eq 'text/plain') {
        # try to get a more specific extension from the path
        if (not(defined $query) && not(defined($fragment)) && $path && ($path =~ /\w+(\.\w+)$/)) {
            $extension = $1;
        }
    }

    unless ($extension) {
        my $mime_type = $self->mime_types->type($content_type);
        my @extensions = $mime_type->extensions;
        if (@extensions) {
            $extension = '.' . $extensions[0];
        }
    }

    $self->log('extension: ', $extension ? $extension : '');
    return $extension;
}

method is_url($url) {
    if ($url =~ m{^[a-zA-Z][\w+]*://}) { # basic sanity check
        my ($scheme, $domain, $path, $query, $fragment) = uri_split($url);
        if ($scheme && ($domain || $path)) { # no domain for file:// URLs
            return [ $scheme, $domain, $path, $query, $fragment ];
        }
    }
}

method url_to_temp_file($url) {
    return unless ($self->is_url($url));

    $self->log("url: $url");

    my $suffix = $self->extension($url);
    my $template = sprintf('%s_%s', $self->app_name, TEMPLATE);
    my $temp_file = File::Temp->new($suffix ? (SUFFIX => $suffix) : (), TEMPLATE => $template, TMPDIR => 1);

    $self->log('filename: ', $temp_file->filename);
    $self->download($url, $temp_file->filename);

    return $temp_file; # return the object (rather than the filename) to prevent premature unlinking
}

method run ($argv) {
    $self->usage unless (@$argv);

    my $wax_options = 1;
    my $seen_url = 0;
    my ($command, @command, @files);

    while (@$argv) {
        my $arg = shift @$argv;

        if ($wax_options) {
            if ($arg =~ /^(?:-d|--debug)$/) {
                $self->debug(1);
            } elsif ($arg =~ /^(?:-[?h]|--help)$/) {
                exec('perldoc', $self->app_name);
            } elsif ($arg =~ /^(?:-s|--separator)$/) {
                $self->separator(shift @$argv);
            } elsif ($arg =~ /^(?:-S|--no-separator)$/) {
                $self->separator(undef);
            } elsif ($arg =~ /^(?:-t|--timeout)$/) {
                $self->timeout(shift @$argv);
            } elsif ($arg =~ /^(?:-u|--user-agent)$/) {
                $self->agent(shift @$argv);
            } elsif ($arg =~ /^-/) { # unknown option
                $self->usage;
            } else { # non-option: exit the wax-options processing stage
                $command = $arg;
                $wax_options = 0;
            }
        } elsif (defined($self->separator) && ($arg eq $self->separator)) {
            push @command, @$argv;
            last;
        } elsif ($self->is_url($arg)) {
            unless ($seen_url) {
                $self->log('user-agent: ', $self->user_agent);
                $self->log('timeout: ', $self->timeout);
                $seen_url = 1;
            }
            my $temp_file = $self->url_to_temp_file($arg);
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

App::Wax - webify your CLI

=head1 SYNOPSIS

    my $wax = App::Wax->new();
    exit $wax->run(\@ARGV);

=head1 DESCRIPTION

C<App::Wax> is the helper library for L<wax>, a simple command-line program that runs
other command-line programs and converts their URL arguments to file paths.

See the L<wax> documentation for more details.

=head1 ATTRIBUTES

Attributes are fields that can optionally be set in the C<App::Wax> constructor,
and get/set by invoking the corresponding getter/setter methods (which have the
same names as the constructor fields) after the C<App::Wax>
object has been initialized. Attributes can be initialized with a hash or hash ref e.g.

    my $wax = App::Wax->new(debug => 1);
    $wax->timeout(180);
    exit $wax->run(\@ARGV);

=head2 app_name([ $string ])

Getter/setter for the name used in the usage message and used to launch perldoc for the C<--help> &c.
options. Default: C<wax>.

=head2 debug([ $bool ])

Gets or sets the debug flag, used to determine whether to display diagnostic messages.

=head2 separator([ $string ])

Gets or sets the separator token used to mark the end of waxable options. Default: C<-->.

Setting the separator to C<undef> disables detection of the wax separator token i.e.
no separator is used to mark the end of waxable options.

=head2 timeout([ $int ])

Getter/setter for the timeout (in seconds) for HTTP requests. Default: 60.

=head2 ua([ $ua ])

Getter/setter for the L<LWP::UserAgent> instance used to perform HTTP requests.

=head2 user_agent([ $string ])

Getter/setter for the HTTP user-agent string.

=head1 METHODS

=head2 content_type($url)

Returns the content type for the supplied URL.

=head2 download($url, $path)

Saves the contents of the URL to the specified path.

=head2 extension($url)

Returns the file extension for the given URL (e.g. C<.html>) if one can be determined from the path component of the URL,
or the resource's C<Content-type> header. Otherwise, returns undef.

=head2 is_url($url)

Returns a true value (a reference to an array of URL components returned by L<URI::Split>'s C<uri_split> method)
if the supplied string is a valid absolute URL, false otherwise.

=head2 log(@message)

Logs the string or list of strings to STDERR if debugging is enabled.

=head2 mime_types()

Getter for the L<MIME::Types> instance used to map the C<content_type> to an extension.

=head2 run($argv)

Takes a reference to a list of C<@ARGV> arguments and runs the specified command with temporary filenames
substituted for URLs. Returns the command's exit code.

=head2 url_to_temp_file($url)

Returns undef if the supplied argument isn't a URL, or a L<File::Temp> object representing the
temporary file to which the URL should be mirrored otherwise.

=head2 usage()

Prints a brief usage message and exits.

=head1 EXPORT

None by default.

=head1 VERSION

0.3.1

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
