#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok('Template::Teeny::Stash');

basic: {
    my $stash = Template::Teeny::Stash->new();

    isa_ok($stash, 'Template::Teeny::Stash');
}

accessor: {
    my $stash = Template::Teeny::Stash->new({
        vars => { a => 1 },    
    });

    is $stash->get('a'), 1, q{Basic stash retrieval};
}

sections: {
    my $stash  = Template::Teeny::Stash->new({});
    my $stash2 = Template::Teeny::Stash->new({});
    my $stash3 = Template::Teeny::Stash->new({});

    $stash->add_section('name', $stash2);
    $stash->add_section('name', $stash3);

    my @sections = $stash->sections('name');
    is scalar(@sections), 2, q{Correct number of sections};
    is_deeply [@sections], [$stash2, $stash3], q{Correct sections};
}



