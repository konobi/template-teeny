package Template::Teeny;

our $CODE_START = <<'END';
sub {
    my ($stash_a) = @_;
    my $output = '';
END

our $CODE_END = <<'END';
}
END

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

sub compile {
    my ($self, $AST) = @_;

    my $current_level ||= 0;

    my $code = '';
    if(!$current_level){
        $code .= $CODE_START;
    }

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

    if(!$current_level){
        $code .= $CODE_END;
    }
    return $code;
}


my $compiled_tpls = {};
sub process {
    my ($self, $tpl, $stash) = @_;

    my $tpl_str = '';
    if(!ref $tpl){
        $tpl_str .= $self->_get_tpl_str($tpl);
    }

    # XXX - This should really take the full name
    my $compile = $compiled_tpls->{ $tpl } ||= do {
        my $AST = $self->parse($tpl_str);
        my $code_str = $self->compile($AST);

        my $coderef = eval($code_str) or die "Could not compile template: $@";
    };
    return $compile->($stash);
}

sub _get_tpl_str {
    my ($self, $tpl) = @_;

    my $tpl_str = '';
    my @dirs_to_try = @{ $self->directory };

    my $file;
    while(my $dir = shift @dirs_to_try){
        my $tmp = $dir . '/' . $tpl;
        if(-e $tmp){
            $file = $tmp;
            last;
        }
    }
    
    die "Could not find $tpl" if(!$file);

    open my $fh, $file or die "Could not open '$file': $!";
    $tpl_str .= do { local $/; <$fh>; };
    close $fh or die "Could not close '$file': $!";

    return $tpl_str;
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

=head2 process

    $tt->process('foo/bar/baz.tpl', $stash);

This method takes a template file name and a stash object to be processed.

=head2 parse

    $tt->parse('[% foo %]');

Takes a string representing the template. Returns an AST.

=head2 compile

    my $eval_string = $tt->compile( ...<AST>... );

This method take a generated AST and translates it into an eval-able
string of perl code.

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
