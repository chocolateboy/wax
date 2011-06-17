#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 16;

use_ok('App::Wax');

my $wax = App::Wax->new();

is $wax->debug, App::Wax->DEBUG();
is $wax->timeout, App::Wax->TIMEOUT();
is $wax->ua->timeout, App::Wax->TIMEOUT();
is $wax->user_agent, App::Wax->USER_AGENT();
is $wax->ua->agent, App::Wax->USER_AGENT();
is $wax->separator, App::Wax->SEPARATOR();

isa_ok $wax->mime_types, 'MIME::Types';
isa_ok $wax->ua, 'LWP::UserAgent';

$wax->debug(1);
is $wax->debug, 1;

$wax->timeout(42);
is $wax->timeout, 42;
is $wax->ua->timeout, 42;

$wax->user_agent('Mozilla');
is $wax->user_agent, 'Mozilla';
is $wax->ua->agent, 'Mozilla';

$wax->separator('--nowax');
is $wax->separator, '--nowax';
$wax->separator(undef);
is $wax->separator, undef;
