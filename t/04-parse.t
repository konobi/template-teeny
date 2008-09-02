#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Deep;

use_ok('Template::Teeny');

my $tt = Template::Teeny->new();

my ($tl, $got);
basic_variable: {
    check(q{[% name %]}, [[ VARS => [qw(name)] ]], q{Basic variable});
}

basic_plus_text: {
    check(
	q{hhhmmm.... [% haha %]}, 
	[[ TEXT => 'hhhmmm.... ' ], [ VARS => [qw(haha)] ]], 
	q{Text plus basic var}
    );
}

basic_end_text: {
    local $TODO = q{Need to work on the parser};
    check(
	q{[% one_two %] bubba},
	[ [VARS => [qw(one_two)] ], [TEXT => ' bubba'] ],
	q{Basic with text end}
    );
}

basic_with_filters: {
    check(
	q{[% value | filter1 | filter2 %]}, 
	[[ VARS => [qw(value filter1 filter2)] ]], 
	q{Filters}
    );
}

section: {
    check(
	q{[% SECTION hehe %][% END %]},
	[[ SECTION => 'hehe' ], [ 'END' ]], 
	q{Sections}
    );
}

sub check {
    my ($tpl, $ast, $cmt) = @_;
    my $got = $tt->parse($tpl);
    cmp_deeply($got, $ast, $cmt);
}
