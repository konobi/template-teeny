package Template::Teeny;

use Moose;

has directory => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 1,
    lazy => 1,
    default => sub { [qw(.)] },
);

my ($START,$END) = map { "\Q$_\E" } qw([% %]);
my $CHUNKS = qr{
    (.+)?
    ($START (?:[^%\]]+) $END)
    (.+)?
}msx;
my $NAME = qr{(?:[^%\s]+)};

my $SECTION = qr{SECTION\s+($NAME)};
my $INCLUDE = qr{INCLUDE\s+($NAME)};

my $VARS = qr{
    (?:
        \s*
        (?:\|)?
        \s*
    )
    ([a-z0-9][a-z0-9_]+)
}msx;

my $DIRECTIVE = qr{
    $START
        \s*
        (END|$SECTION|$INCLUDE|(?:[a-z0-9_\s\|]+))
        \s*
    $END
}msx;

sub parse {
    my ($self, $tpl) = @_;
    my (@chunks) = grep { defined $_ && $_ } ($tpl =~ m{$CHUNKS}g);
  
    my @AST;
    while(my $chunk = shift @chunks){
        if(my ($dir) = $chunk =~ $DIRECTIVE){
            if(my ($name) = $dir =~ $SECTION){
                $name =~ s/['"]//g;
                push @AST, [SECTION => $name];
            }elsif(my ($nm) = $dir =~ $INCLUDE){
                $nm =~ s/['"]//g;
                push @AST, [INCLUDE => $nm];
            }elsif($dir =~ m{END}){
                push @AST, ['END'];
            }elsif(my (@items) = $dir =~ m{$VARS}g){
                push @AST, [VARS => [@items]];
            }
        } else {
            push @AST, [TEXT => $chunk];
        }
    }

    return [@AST];
}

=for comment

sub process {
    my ($self, $tmpl, $vars) = @_;

    my $cb = sub { die "Could not get real template" };

    if(ref($tmpl) eq 'SCALAR'){
         $cb = $self->_codify($tmpl);
    }

    print $cb->($vars);
}

sub _codify {
    my ($self, $tpl) = @_;
    my @AST = @{ $self->parse($tpl) };

    my $code = <<'END';
    my $VAR = sub {
        my ($vars) = @_;
        my $output = '';
        my $foo = $vars;
END
    while(my $item = shift @AST){
        my ($type,$stuff) = @$item; 
        if($type eq 'TEXT'){
            my $text = quotemeta($stuff);
            $code .= qq{
                \$output .= "$text";
            };
        }elsif($type eq 'SECTION'){
            $code .= qq!
                # Start of SECTION $stuff
                \$foo = \$vars->{'*$stuff'};
                for my \$ick (\@\$foo){
                    my \$old_foo = \$foo;
                    \$foo = \$ick;
            !;
        }elsif($type eq 'END'){
            $code .= q!
                    $foo = $old_foo;
                }
            !;
        }elsif($type eq 'VARS'){
            unless(@$stuff > 2){
                $code .= qq{
                    \$output .= \$foo->{ $stuff->[0] };
                };
            }
        }
    }
    $code .= <<'END';
        return $output;
    }
END

    my $cb = eval "$code" or die "erk: $@";
    return $cb;
}

=cut

=head1 NAME

Template::Teeny - Teeny-weeny templating system

=head1 VERSION

Version 0.00_001

=cut

our $VERSION = '0.00_001';

=head1 SYNOPSIS


    use Template::Teeny;

    my $tt = Template::Teeny->new();
    ...
# XXX TODO add more here

=head1 METHODS

=head2 parse

    $tt->parse('[% foo %]');

Takes a string representing the template. Returns an AST.

=head1 AUTHOR

Scott McWhirter, C<< <konobi at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Teeny

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Teeny>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Teeny>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Teeny>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Teeny>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Scott McWhirter, all rights reserved.

This program is released under the following license: BSD

=cut

1;
