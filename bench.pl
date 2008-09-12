#!/usr/bin/env perl

use strict;
use warnings;

use Template::Teeny;
use Template::Teeny::Stash;
use Template;

use Benchmark qw(:hireswallclock cmpthese);

my $tt = Template::Teeny->new({ directory => ['t/tpl'] });
my $stash = Template::Teeny::Stash->new({ vars => { name => 'bob' } });

my $t = Template->new({ INCLUDE_PATH => 't/tpl', COMPILE_EXT => '.tc' });
my $out;
open my $fh, '>/dev/null';

sub teeny {
    $tt->process('bench.tpl', $stash, $fh);
}
sub plain {
    $t->process('bench.tpl', { name => 'bob' }, $fh);    
}

cmpthese( 10_000, { teeny => \&teeny, template_toolkit => \&plain });

