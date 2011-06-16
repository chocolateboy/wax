#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 9;

use_ok('App::Wax');

my $wax = App::Wax->new();

is $wax->debug, 0;
is $wax->timeout, App::Wax->TIMEOUT();
is $wax->user_agent, App::Wax->USER_AGENT();
isa_ok $wax->mime_types, 'MIME::Types';
isa_ok $wax->ua, 'LWP::UserAgent';

$wax->debug(1);
is $wax->debug, 1;

$wax->timeout(42);
is $wax->timeout, 42;

$wax->user_agent('Mozilla');
is $wax->user_agent, 'Mozilla';
