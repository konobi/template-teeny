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
  print {$out} 'Hello one and all';
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
  print {$out} $stash_a->get(qw(albert));
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
  print {$out} 'hehehe sucka ';
  print {$out} $stash_a->get(qw(name escape_html));
  print {$out} '
        ';
  for my $stash_b ( $stash_a->sections('foo') ) {
  print {$out} ' ';
  print {$out} $stash_b->get(qw(hehe));
  print {$out} ' ';
  }
# <end>
END

    is $str, $expected, q{Complex example works};
}

#---------------------------------------------------
$Template::Teeny::CODE_START = undef;
$Template::Teeny::CODE_END = undef;

