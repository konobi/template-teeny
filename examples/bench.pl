#!/usr/bin/env perl

use strict;
use warnings;

use Template::Teeny;
use Template::Teeny::Stash;
use Template;

use Benchmark qw(:hireswallclock cmpthese);
basic: {
    my $tt = Template::Teeny->new({ directory => ['t/tpl'] });
    my $stash = Template::Teeny::Stash->new({ name => 'bob' });

    my $t = Template->new({ INCLUDE_PATH => 't/tpl', COMPILE_EXT => '.tc' });
    my $out;
    open my $fh, '>/dev/null';

    $tt->process('bench.tpl', $stash, $fh);
    $t->process('bench.tpl', { name => 'bob' }, $fh);

    sub teeny {
        $tt->process('bench.tpl', $stash, $fh);
    }
    sub plain {
        $t->process('bench.tpl', { name => 'bob' }, $fh);    
    }

    print "Very simple interpolation:\n";
    cmpthese( 10_000, { teeny => \&teeny, template_toolkit => \&plain });
}

some_looping_etc: {
    my $tt = Template::Teeny->new({ directory => ['t/tpl'] });
    my $stash = Template::Teeny::Stash->new({ title => q{Bobs Blog} });

    my $post1 = Template::Teeny::Stash->new({ date => 'Today', title => 'hehe' });
    my $post2 = Template::Teeny::Stash->new({ date => '3 Days ago', title => 'Something new' });
    $stash->add_section('post', $post1);
    $stash->add_section('post', $post2);

    my $t = Template->new({ INCLUDE_PATH => 't/tpl', COMPILE_EXT => '.tc' });
    my $out;
    open my $fh, '>/dev/null';

    my $tt_vars = { 
        title => 'Bobs Blog', 
        posts => [
            { title => 'hehe', date => 'Today' },
            { date => '3 Days ago', title => 'Something new' },
        ],
    };
    teeny2();
    plain2();

    sub teeny2 {
        $tt->process('bench2-teeny.tpl', $stash, $fh);
    }
    sub plain2 {
        $t->process('bench2-tt.tpl', $tt_vars, $fh);    
    }

    print "\nLoop and interpolation:\n";
    cmpthese( 10_000, { teeny => \&teeny2, template_toolkit => \&plain2 });
}




