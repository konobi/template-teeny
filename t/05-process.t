#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Differences;
use IO::Scalar;

use_ok('Template::Teeny');
use_ok('Template::Teeny::Stash');

basic: {
    my $stash = Template::Teeny::Stash->new({
        name => 'Perl Hacker', title => 'paper',
    });

    my $tt = Template::Teeny->new({
        include_path => [q{t/tpl}],
    });

    
    my $io = IO::Scalar->new(\(my $out));
    $tt->process('foo.tpl', $stash, $io);
    my $expected = <<'END';

Hi Perl Hacker,

This is my paper

END
    is $out, $expected, q{Full process};
}

nested_sections: {
    my $stash = Template::Teeny::Stash->new({
        name => 'Charlie', interest => 'movies',
    });

    my $item1 = Template::Teeny::Stash->new({ item => 'Happy Gilmore' });
    my $item2 = Template::Teeny::Stash->new({ item => 'Care Bears' });
    
    $stash->add_section('items', $item1);
    $stash->add_section('items', $item2);

    $stash->add_section('possible_geek');

    my $tt = Template::Teeny->new({
        include_path => [q{t/tpl}],
    });

    my $io = IO::Scalar->new(\(my $out));
    $tt->process('nested.tpl', $stash, $io);
    my $expected = <<'END';
<html>
  <head><title>Howdy Charlie</title></head>
  <body>
    <p>My favourite things, movies!</p>
    <ul>
      
        <li>Happy Gilmore</li>
      
        <li>Care Bears</li>
      
    </ul>

    
        <span>I likes DnD...</span>
    
  </body>
</html>
END

    eq_or_diff $out, $expected, q{More complex example};
}

horror: {    
    my $stash = Template::Teeny::Stash->new({
        name => 'Perl Hacker',
    });

    my $tt = Template::Teeny->new({
        include_path => [q{t/tpl}],
    });

    my $io = IO::Scalar->new(\(my $out));
    $tt->process('horror.tpl', $stash, $io);
    my $expected = <<'END';

~`@#$%^&*()-_=+{[]}\|;:"'<,.>?/

Perl Hacker
END
    is $out, $expected, q{Horror process};
}

