package Template::Teeny;

our $CODE_START;
our $CODE_END;

use Moose;

has directory => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 1,
    lazy => 1,
    default => sub { [qw(.)] },
);

my ($START,$END) = map { qr{\Q$_\E} } qw([% %]);
my $DECLARATION = qr{$START (?:.+?) $END}x;
my $TEXT = qr{
    (?:\A|(?<=$END))    # Start matching from the start of the file or end of a declaration
        .*?                 # everything in between
    (?:\Z|(?=$START))   # Finish at the end of the file or start of another declaration
}msx;
my $CHUNKS = qr{
    ($TEXT)?
    ($DECLARATION)?
}msx;

my $IDENT = qr{
    [a-z][a-z0-9_]+ # any alphanumeric characters and underscores, but must start
                    # with a letter; everything must be lower case
}x;

my $SECTION = qr{
    SECTION \s+ ($IDENT)
}x;
my $INCLUDE = qr{
    INCLUDE \s+ ["']? ([^"']+) ["']?
}x;

my $VARS = qr{
    (?: \s* \| \s* )?
    ( $IDENT )
}x;

my $DIRECTIVE = qr{
    $START
        \s*?
        (END
            | $SECTION
            | $INCLUDE
            | [a-z0-9_\s\|]+
        )
        \s*?
    $END
}x;

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

=for AST_example

    #hehehe sucka [% name | escape_html %]
    #        [% SECTION foo %] [%hehe%] [% END %]

    $AST = [
        [ 'TEXT', 'hehehe sucka ' ],
        [ 'VARS', [ 'name', 'escape_html' ] ],
        [ 'TEXT', "\n        " ],
        [ 'SECTION', 'foo' ],
        [ 'TEXT', ' ' ],
        [ 'VARS', [ 'hehe' ] ],
        [ 'TEXT', ' ' ],
        [ 'END' ],
        [ 'VARS', 'bob']
    ];

    my ($dict) = @_;
    my $output = '';
    $output .= 'hehehe sucka ';
    $output .= escape_html( $dict->get_var('name') );
    $output .= "\n        ";
    for my $sdict ( $dict->get_sections('foo') ) {
        $output .= ' ';
        $output .= $sdict->get_var('hehe');
        $output .= ' ';
    }
    $output .= $dict->get_var('bob');

=cut


sub compile {
    my ($self, $opts) = @_;

    my $AST  = $opts->{AST} or die "No AST to compile";
    my $dict = $opts->{dict};

    my $code = $CODE_START;

    my $current_level = 0;
    my @names = ('a'..'z');

    while(my $item = shift @$AST){
        my ($type, $val) = @$item;

        if($type eq 'TEXT'){
            $code .= q{  $output .= '}.$val.qq{';\n};

        } elsif ($type eq 'VARS') {
            $code .= q{  $output .= $stash_} 
                    . $names[$current_level] 
                    . q{->get(qw(} 
                    . join(' ', @$val)
                    . qq{));\n};

        } elsif ($type eq 'END'){ 
            $code .= "  }\n";
            $current_level--;

        } elsif ($type eq 'SECTION') {
            my $old = $names[$current_level];
            my $new = $names[++$current_level];

            $code .= "  for my \$stash_$new ( \$stash_$old\->sections('$val') ) {\n";
        } else {
            die "Could not understand type '$type'";
        }
    }

    $code .= $CODE_END;
    return $code;
}

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
