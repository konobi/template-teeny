#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

use_ok('Template::Teeny');

my $tt = Template::Teeny->new();
isa_ok($tt, 'Template::Teeny');

