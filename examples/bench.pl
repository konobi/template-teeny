#!/usr/bin/env perl

use strict;
use warnings;

use Template::Teeny;
use Template::Teeny::Stash;
use Template;

use Template::Simple;

my $iters = shift(@ARGV) || 100_000;

use Benchmark qw(:hireswallclock cmpthese);
basic: {
    my $tt = Template::Teeny->new({ include_path => ['t/tpl'] });
    my $stash = Template::Teeny::Stash->new({ name => 'bob' });
    my $ts = Template::Simple->new();
    my $ts_tmpl = "howdy [% name %]";

    my $t = Template->new({ INCLUDE_PATH => 't/tpl', COMPILE_EXT => '.tc' });
    my $out;
    open my $fh, '>', \$out;

    $tt->process('bench.tpl', $stash, $fh);
    $t->process('bench.tpl', { name => 'bob' }, $fh);
    $ts->render($ts_tmpl, { name => 'bob'});

    sub teeny {
        $tt->process('bench.tpl', $stash, $fh);
        $out = '';
    }
    sub plain {
        $t->process('bench.tpl', { name => 'bob' }, $fh);
        $out = '';
    }
    sub simple {
        $out = $ts->render($ts_tmpl, { name => 'bob'});
        $out = '';
    }

    print "Very simple interpolation:\n";
    cmpthese( $iters, { teeny => \&teeny, template_toolkit => \&plain, simple => \&simple });
}

some_looping_etc: {
    my $tt = Template::Teeny->new({ include_path => ['t/tpl'] });
    my $stash = Template::Teeny::Stash->new({ title => q{Bobs Blog} });

    my $post1 = Template::Teeny::Stash->new({ date => 'Today', title => 'hehe' });
    my $post2 = Template::Teeny::Stash->new({ date => '3 Days ago', title => 'Something new' });
    $stash->add_section('post', $post1);
    $stash->add_section('post', $post2);

    my $ts = Template::Simple->new();
    my $ts_tmpl = "<html>
  <head><title>[% title %]</title></head>
  <body>
    <ul>
      [% START posts %]
        <li>
            <h3>[% title %]</h3>
            <span>[% date %]</span>
        </li>
      [% END posts %]
    </ul>
  </body>
</html>";

    my $t = Template->new({ INCLUDE_PATH => 't/tpl', COMPILE_EXT => '.tc' });
    my $out;
    open my $fh, '>', \$out;

    my $tt_vars = { 
        title => 'Bobs Blog', 
        posts => [
            { title => 'hehe', date => 'Today' },
            { date => '3 Days ago', title => 'Something new' },
        ],
    };
    teeny2();
    plain2();
    simple2();

    sub teeny2 {
        $tt->process('bench2-teeny.tpl', $stash, $fh);
        $out = '';
    }
    sub plain2 {
        $t->process('bench2-tt.tpl', $tt_vars, $fh);    
        $out = '';
    }
    sub simple2 {
        $out = $ts->render($ts_tmpl, $tt_vars);
        $out = '';
    }

    print "\nLoop and interpolation:\n";
    cmpthese( $iters, { teeny => \&teeny2, template_toolkit => \&plain2, simple => \&simple2 });
}




