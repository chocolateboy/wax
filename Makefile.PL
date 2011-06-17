use 5.008008; # LWP's minimum

use strict;
use warnings;

use inc::Module::Install;

name     'App-Wax';
author   'chocolateboy <chocolate@cpan.org>';
license  'perl';
all_from 'lib/App/Wax.pm';

requires 'HTTP::Request';
requires 'LWP';
requires 'Method::Signatures::Simple' => '0.06';
requires 'MIME::Types'                => '1.31';
requires 'Mouse'                      => '0.93';
requires 'URI';

install_script 'bin/wax';
repository 'https://github.com/chocolateboy/App-Wax';

WriteAll;
