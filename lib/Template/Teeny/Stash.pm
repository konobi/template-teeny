package Template::Teeny::Stash;

use Moose;
use Moose::Util::TypeConstraints;

has vars => (is => 'rw', isa => 'HashRef', default => sub { {} });
has _sections => (is => 'rw', isa => 'HashRef[ArrayRef[Template::Teeny::Stash]]', default => sub { {} });

sub sections { @{ $_[0]->_sections->{$_[1]} || [] }; }
sub add_section { 
    $_[0]->_sections->{$_[1]} ||= [];
    push @{ $_[0]->_sections->{$_[1]} }, $_[2]; 
}

# XXX - add ability to deal with filters here
sub get { 
    # All values return are always strings
    "" . $_[0]->vars->{$_[1]}; 
}



1;
