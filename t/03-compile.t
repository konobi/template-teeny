#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;

use_ok('Template::Teeny');

my ($start,$end);
{
    # Make it easier to test!
    $start = $Template::Teeny::CODE_START = "# <start>\n";
    $end   = $Template::Teeny::CODE_END   = "# <end>\n";
}

my $tt = Template::Teeny->new();

basic_text: {
    my $str = $tt->compile(
        [[ TEXT => 'Hello one and all' ]],
    );

    my $expected = <<'END';
# <start>
  $output .= 'Hello one and all';
# <end>
END

    is $str, $expected, q{Basic Text works};
}

basic_var: {
    my $str = $tt->compile(
        [[ VARS => [qw(albert)] ]],
    );

    my $expected = <<'END';
# <start>
  $output .= $stash_a->get(qw(albert));
# <end>
END

    is $str, $expected, q{Basic Variable works};
}

basic_section: {
    my $str = $tt->compile(
        [[ SECTION => "blog" ], [ 'END' ]],
    );
    
    my $expected = <<'END';
# <start>
  for my $stash_b ( $stash_a->sections('blog') ) {
  }
# <end>
END

    is $str, $expected, q{Basic Section works};
}

complex: {
    my $str = $tt->compile(
        [
            [TEXT => 'hehehe sucka '],
            [VARS => [qw(name escape_html)]],
            [TEXT => "\n        "],
            [SECTION => 'foo'],
            [TEXT => ' '],
            [VARS => [qw(hehe)]],
            [TEXT => ' '],
            ['END'],
        ],
    );

    my $expected = <<'END';
# <start>
  $output .= 'hehehe sucka ';
  $output .= $stash_a->get(qw(name escape_html));
  $output .= '
        ';
  for my $stash_b ( $stash_a->sections('foo') ) {
  $output .= ' ';
  $output .= $stash_b->get(qw(hehe));
  $output .= ' ';
  }
# <end>
END

    is $str, $expected, q{Complex example works};
}

#---------------------------------------------------
$Template::Teeny::CODE_START = undef;
$Template::Teeny::CODE_END = undef;

